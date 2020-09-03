------------------ ENTITIES ---------------------

drop domain if exists lib_predicate.identifier;
create domain lib_predicate.identifier as varchar(63)
  not null
  check (value ~* '^(([a-z]|[a-z][a-z0-9\-_]*[a-z0-9])){3,63}$');

drop domain if exists lib_predicate.target_identifier;
create domain lib_predicate.target_identifier as varchar(63)
  not null
  check (value ~* '^([a-z_]+(\.[a-z_]+)*)$' and length(trim(value)) > 3);

drop domain if exists lib_predicate.label;
create domain lib_predicate.label as varchar(63)
  not null
  check (length(trim(value)) > 0);

drop domain if exists lib_predicate.description;
create domain lib_predicate.description as text
  not null
  check (length(trim(value)) > 3);

create table lib_predicate.logical_type
(
  logical_type__id lib_predicate.identifier primary key,
  label            lib_predicate.label,
  description      lib_predicate.description
);

create table lib_predicate.config
(
  config__id  uuid primary key not null default public.gen_random_uuid(),
  label       lib_predicate.label,
  description lib_predicate.description
);

create table lib_predicate.type
(
  type__id lib_predicate.identifier primary key
);

comment on column lib_predicate.type.type__id is 'Target data type identifier e.g: "int", "text", "timestamptz"';

create table lib_predicate.target
(
  target__id lib_predicate.target_identifier primary key,
  label      lib_predicate.label,
  type__id   lib_predicate.identifier references lib_predicate.type(type__id) on delete restrict on update cascade
);

create table lib_predicate.widget
(
  widget__id lib_predicate.identifier primary key,
  label      lib_predicate.label
);

comment on table lib_predicate.widget is 'UI widget pickers list.';
comment on column lib_predicate.widget.widget__id is 'List all availables ui widget for an operator.';

create table lib_predicate.operator
(
  operator__id lib_predicate.identifier primary key,
  label        lib_predicate.label,
  type__id     lib_predicate.identifier references lib_predicate.type(type__id) on delete restrict on update cascade,
  widget__id   lib_predicate.identifier references lib_predicate.widget(widget__id) on delete restrict on update cascade
);

comment on column lib_predicate.operator.operator__id is 'Comparison operator function identifier e.g: "text_ends_width", "timestamptz_before"...';
comment on column lib_predicate.operator.label is 'Comparison operator function descriptive identifier e.g: "=", ">=", "between"...';

------------------ LINKS ------------------------

create table lib_predicate.config__logical_type
(
  config__id       uuid not null references lib_predicate.config(config__id) on delete cascade on update cascade,
  logical_type__id lib_predicate.identifier references lib_predicate.logical_type(logical_type__id) on delete cascade on update cascade,
  unique (config__id, logical_type__id)
);

create table lib_predicate.config__target
(
  config__id uuid not null references lib_predicate.config(config__id) on delete cascade on update cascade,
  target__id lib_predicate.target_identifier references lib_predicate.target(target__id) on delete cascade on update cascade,
  unique (config__id, target__id)
);

------------------ TRIGGERS ---------------------

create or replace function lib_predicate.ensure_operator_function_exists() returns trigger as
$$
declare
  name$ text;
begin

  select p.proname from pg_proc p
    join pg_namespace n on p.pronamespace = n.oid
    where n.nspname = 'lib_predicate' and p.proname::text = new.operator__id::text into name$;

  if not found then
    raise 'an operator__id must have a lib_predicate function counterpart.' using errcode = 'check_violation';
  end if;

  return new;
end;
$$ language plpgsql;

create trigger ensure_operator_function_exists
  before insert or update
  on lib_predicate.operator
  for each row
execute procedure lib_predicate.ensure_operator_function_exists();

------------------ API --------------------------

-- Target

create or replace function lib_predicate.target_create(
  target__id$ lib_predicate.target_identifier,
  label$      lib_predicate.label,
  type__id$   lib_predicate.identifier
) returns lib_predicate.target_identifier as
$$
begin
  insert into lib_predicate.target (target__id, label, type__id) values (target__id$, label$, type__id$) returning target__id into target__id$;
  return target__id$;
end;
$$ language plpgsql;

create or replace function lib_predicate.target_delete(target__id$ lib_predicate.target_identifier) returns void as
$$
begin
  delete from lib_predicate.target where target__id = target__id$;
end;
$$ language plpgsql;

-- Config

create or replace function lib_predicate.config_create(
  label$       lib_predicate.label,
  description$ lib_predicate.description,
  config__id$  uuid default public.gen_random_uuid()
) returns uuid as
$$
begin
  insert into lib_predicate.config (config__id, label, description) values (config__id$, label$, description$) returning config__id into config__id$;
  return config__id$;
end;
$$ language plpgsql;

create or replace function lib_predicate.config_enable_logical_type(config__id$  uuid, logical_type__id$ lib_predicate.identifier) returns void as
$$
begin
  insert into lib_predicate.config__logical_type (config__id, logical_type__id) values (config__id$, logical_type__id$);
end;
$$ language plpgsql;

create or replace function lib_predicate.config_disable_logical_type(config__id$  uuid, logical_type__id$ lib_predicate.identifier) returns void as
$$
begin
  delete from lib_predicate.config__logical_type where config__id = config__id$ and logical_type__id = logical_type__id$;
end;
$$ language plpgsql;

create or replace function lib_predicate.config_enable_target(config__id$  uuid, target__id$ lib_predicate.target_identifier) returns void as
$$
begin
  insert into lib_predicate.config__target (config__id, target__id) values (config__id$, target__id$);
end;
$$ language plpgsql;

create or replace function lib_predicate.config_disable_target(config__id$  uuid, target__id$ lib_predicate.target_identifier) returns void as
$$
begin
  delete from lib_predicate.config__target where config__id = config__id$ and target__id = target__id$;
end;
$$ language plpgsql;

create or replace function lib_predicate.config_delete(config__id$ uuid) returns void as
$$
begin
  delete from lib_predicate.config where config__id = config__id$;
end;
$$ language plpgsql;

-- Argument type

create or replace function lib_predicate.widget_create(
  widget__id$ lib_predicate.identifier,
  label$             lib_predicate.label
) returns lib_predicate.identifier as
$$
begin
  insert into lib_predicate.widget (widget__id, label) values (widget__id$, label$) returning widget__id into widget__id$;
  return widget__id$;
end;
$$ language plpgsql;

create or replace function lib_predicate.widget_delete(widget__id$ lib_predicate.identifier) returns void as
$$
begin
  delete from lib_predicate.widget where widget__id = widget__id$;
end;
$$ language plpgsql;

-- Operator

create or replace function lib_predicate.operator_create(
  operator__id$      lib_predicate.identifier,
  label$             lib_predicate.label,
  type__id$          lib_predicate.identifier,
  widget__id$ lib_predicate.identifier
) returns lib_predicate.identifier as
$$
begin
  insert into lib_predicate.operator (operator__id, label, type__id, widget__id) values (operator__id$, label$, type__id$, widget__id$) returning operator__id into operator__id$;
  return operator__id$;
end;
$$ language plpgsql;

create or replace function lib_predicate.operator_delete(operator__id$ lib_predicate.identifier) returns void as
$$
begin
  delete from lib_predicate.operator where operator__id = operator__id$;
end;
$$ language plpgsql;
