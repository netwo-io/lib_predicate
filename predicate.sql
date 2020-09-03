------------------ ENTITIES ---------------------

create table lib_predicate.predicate_tree
(
  predicate_tree__id uuid not null primary key default public.gen_random_uuid(),
  config__id         uuid not null references lib_predicate.config(config__id) on delete cascade on update cascade,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz
);

comment on table lib_predicate.predicate_tree is 'User defined predicate rules tree.';

create table lib_predicate.compound_predicate
(
  compound_predicate__id        uuid not null primary key default public.gen_random_uuid(),
  parent_compound_predicate__id uuid references lib_predicate.compound_predicate(compound_predicate__id) on delete cascade on update cascade,
  predicate_tree__id            uuid not null references lib_predicate.predicate_tree(predicate_tree__id) on delete cascade on update cascade,
  logical_type__id              lib_predicate.identifier references lib_predicate.logical_type(logical_type__id) on delete cascade on update cascade
);

create table lib_predicate.predicate
(
  compound_predicate__id uuid not null references lib_predicate.compound_predicate(compound_predicate__id) on delete cascade on update cascade,
  target__id             lib_predicate.target_identifier references lib_predicate.target(target__id) on delete cascade on update cascade,
  operator__id           lib_predicate.identifier references lib_predicate.operator(operator__id) on delete cascade on update cascade,
  argument               jsonb not null check (argument::text ~* '^\[.*\]$')
);

------------------ TRIGGERS ---------------------------

create or replace function lib_predicate.ensure_predicate_target_belongs_to_config() returns trigger as
$$
declare
  count$ int;
begin

  select 1 from lib_predicate.compound_predicate
    inner join lib_predicate.predicate_tree using (predicate_tree__id)
    inner join lib_predicate.config__target on config__target.target__id = new.target__id and config__target.config__id = predicate_tree.config__id into count$;

  if not found then
    raise 'predicate target__id must be recorded in predicate_tree parent config.' using errcode = 'foreign_key_violation';
  end if;

  return new;
end;
$$ language plpgsql;

create trigger ensure_predicate_target_belongs_to_config
  before insert or update
  on lib_predicate.predicate
  for each row
execute procedure lib_predicate.ensure_predicate_target_belongs_to_config();

------------------ PRIVATE API ------------------------

create type lib_predicate.deserialized_tree as (
  compound_predicates lib_predicate.compound_predicate[],
  predicates          lib_predicate.predicate[]
);

create type lib_predicate.exploded_tree as (
  statement text,
  cols      text[],
  tables    text[],
  variables text[]
);

create or replace function lib_predicate.deserialize_tree(predicate_tree__id$ uuid, serialized_predicate_tree$ jsonb, parent_compound_predicate__id$ uuid default null) returns lib_predicate.deserialized_tree as
$$
declare
  result$             lib_predicate.deserialized_tree;
  child_result$       lib_predicate.deserialized_tree;
  compound_predicate$ lib_predicate.compound_predicate;
  predicate$          lib_predicate.predicate;
  i$                  jsonb;
  match$              text[];
begin

  if serialized_predicate_tree$->'logical_type_id' is not null and serialized_predicate_tree$#>'{predicates,0}' is not null then

    compound_predicate$.compound_predicate__id = public.gen_random_uuid();
    compound_predicate$.logical_type__id = serialized_predicate_tree$->>'logical_type_id';
    compound_predicate$.predicate_tree__id = predicate_tree__id$;
    compound_predicate$.parent_compound_predicate__id = parent_compound_predicate__id$;

    result$.compound_predicates = result$.compound_predicates || compound_predicate$;

    for i$ in select * from jsonb_array_elements(serialized_predicate_tree$->'predicates')
    loop

      child_result$ = lib_predicate.deserialize_tree(predicate_tree__id$, i$, compound_predicate$.compound_predicate__id);
      result$.compound_predicates = result$.compound_predicates || child_result$.compound_predicates;
      result$.predicates = result$.predicates || child_result$.predicates;
    end loop;

    return result$;

  elsif serialized_predicate_tree$->'target_id' is not null and serialized_predicate_tree$->'operator_id' is not null then

    match$ = regexp_matches(serialized_predicate_tree$->>'target_id'::text, '^([a-z_]+(\.[a-z_]+)*)$'::text);
    if array_length(match$, 1) = 0 then
      raise 'wrong target_id % format, awaited {table}(.{field})*', serialized_predicate_tree$->>'target_id'::text using errcode = 'check_violation';
    end if;

    match$ = regexp_matches(serialized_predicate_tree$->>'argument'::text, '^\[.*\]$'::text);
    if array_length(match$, 1) = 0 then
      raise 'wrong argument % format, awaited json array', serialized_predicate_tree$->>'argument'::text using errcode = 'check_violation';
    end if;

    predicate$.compound_predicate__id = parent_compound_predicate__id$;
    predicate$.target__id = serialized_predicate_tree$->>'target_id'::text;
    predicate$.operator__id = (serialized_predicate_tree$->>'operator_id')::text;
    predicate$.argument = (serialized_predicate_tree$->>'argument')::text;

    result$.predicates = result$.predicates || predicate$;
    return result$;
  end if;

  raise 'wrong serialized predicate tree format' using errcode = 'check_violation';
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.explode_tree(body$ jsonb) returns lib_predicate.exploded_tree as $$
declare
  operator$      text;
  prefix$        text default '';
  i              jsonb;
  j              text;
  elem           lib_predicate.exploded_tree;
  sub_elem       lib_predicate.exploded_tree;
  sub_statements text[];
  couple$        text[];
  temp$          text[];
begin

  if body$->'logical_type_id' is not null and body$#>'{predicates,0}' is not null then

    case body$->>'logical_type_id'
      when 'all' then operator$ = 'AND';
      when 'any' then operator$ = 'OR';
      when 'none' then
        operator$ = 'AND';
        prefix$ = 'NOT ';
      else
        raise 'unknown logical id' using errcode = 'check_violation';
    end case;

    for i in select * from jsonb_array_elements(body$->'predicates')
    loop
      sub_elem = lib_predicate.explode_tree(i);
      elem.cols = elem.cols || sub_elem.cols;
      elem.variables = elem.variables || sub_elem.variables;
      elem.tables = elem.tables || sub_elem.tables;
      sub_statements = sub_statements || sub_elem.statement;
    end loop;

    elem.statement = prefix$ || '(' || array_to_string(sub_statements, ' ' || operator$ || ' ') || ')';
    return elem;

  elsif body$->'target_id' is not null and body$->'operator_id' is not null then

    couple$ = regexp_matches(body$->>'target_id'::text, '([a-zA-Z0-9]+)\.([a-zA-Z0-9]+)'::text);
    if array_length(couple$, 1) != 2 then
      raise 'wrong target_id$ format, awaited {table}:{field}' using errcode = 'check_violation';
    end if;

    elem.tables = array[couple$[1]];
    elem.cols = array[format(E'%I.%I', couple$[1], couple$[2])];
    elem.variables = array[(body$->>'operator_id')::text, couple$[1], couple$[2], (body$->>'argument')::text];
    elem.statement = 'lib_predicate.%I(%I.%I, %L)';
    return elem;
  end if;

  raise 'wrong predicate config' using errcode = 'check_violation';
end;
$$ immutable language plpgsql;

------------------ PUBLIC API -------------------------

-- Predicate tree

create or replace function lib_predicate.predicate_tree_upsert(config__id$ uuid, serialized_predicate_tree$ jsonb, predicate_tree__id$ uuid default public.gen_random_uuid()) returns uuid as
$$
declare
  tree$ lib_predicate.deserialized_tree;
begin

  tree$ = lib_predicate.deserialize_tree(predicate_tree__id$, serialized_predicate_tree$);

  delete from lib_predicate.compound_predicate where predicate_tree__id = predicate_tree__id$;

  insert into lib_predicate.predicate_tree (predicate_tree__id, config__id) values (predicate_tree__id$, config__id$)
    on conflict (predicate_tree__id) do update set config__id = config__id$, updated_at = now();

  insert into lib_predicate.compound_predicate select * from unnest(tree$.compound_predicates);
  insert into lib_predicate.predicate select * from unnest(tree$.predicates);

  return predicate_tree__id$;
end;
$$ language plpgsql;

create or replace function lib_predicate.predicate_tree_delete(predicate_tree__id$ uuid) returns void as
$$
begin
  delete from lib_predicate.predicate_tree where predicate_tree__id = predicate_tree__id$;
end;
$$ language plpgsql;

create or replace function lib_predicate.tree_to_sql_query(predicate_tree$ jsonb) returns text as
$$
declare
  extract$ lib_predicate.exploded_tree;
  cols$    text[];
  tables$  text[];
  query$   text;
begin
  extract$ = lib_predicate.explode_tree(predicate_tree$);
  tables$ = array(select distinct e from unnest(extract$.tables) as a(e));
  if array_length(tables$, 1) > 1 then
    raise 'multiple table source is currently not available' using errcode = 'check_violation';
  end if;
  cols$ = array(select distinct e from unnest(extract$.cols) as a(e));

  query$ = E'select ' || array_to_string(cols$, ', ')  || ' from ' || array_to_string(tables$, ', ') || ' where ' || extract$.statement;
  return format(query$, variadic extract$.variables);
end;
$$ language plpgsql;
