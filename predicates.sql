create view lib_predicate.compound_predicates as
  select
    compound_predicate.compound_predicate__id,
    compound_predicate.predicate_tree__id,
    compound_predicate.parent_compound_predicate__id,
    logical_type__id,
    json_agg(
      jsonb_build_object(
        'target_id', predicate.target__id,
        'operator_id', predicate.operator__id,
        'argument', predicate.argument
      )
    ) as predicates
    from lib_predicate.compound_predicate
      inner join lib_predicate.predicate using (compound_predicate__id)
    group by compound_predicate__id;

create view lib_predicate.predicate_trees as
  with recursive compound_predicate_from_parent as
  (
    -- Compound predicate without parent, starting point
    select cp.compound_predicate__id, cp.predicate_tree__id, cp.logical_type__id, case when cps.compound_predicate__id is not null then true else false end has_child
      from lib_predicate.compound_predicate cp
      left join lib_predicate.compound_predicate cps on cps.parent_compound_predicate__id = cp.compound_predicate__id
      where cp.parent_compound_predicate__id is null
    union all
    -- Recursively find sub-classes and append them to the result-set
    select cp.compound_predicate__id, cp.predicate_tree__id, cp.logical_type__id, case when cps.compound_predicate__id is not null then true else false end
      from compound_predicate_from_parent p
        join lib_predicate.compound_predicate cp on cp.parent_compound_predicate__id = p.compound_predicate__id
        left join lib_predicate.compound_predicate cps on cps.parent_compound_predicate__id = cp.compound_predicate__id
  ),
  compound_predicate_from_children as
  (
    select cp.predicate_tree__id, cp.parent_compound_predicate__id, json_agg(jsonb_build_object('logical_type_id', cp.logical_type__id, 'predicates', cps.predicates))::jsonb as predicates
      from compound_predicate_from_parent tree
          join lib_predicate.compound_predicate cp using (compound_predicate__id)
          join lib_predicate.compound_predicates cps on cps.compound_predicate__id = cp.compound_predicate__id
      where has_child = false
      group by cp.predicate_tree__id, cp.parent_compound_predicate__id
    union all
    select
        cp.predicate_tree__id,
        cp.parent_compound_predicate__id,
        jsonb_build_object('logical_type_id', cp.logical_type__id, 'predicates', ('[' || trim('[]' from tree.predicates::text) || ',' || trim('[]' from cps.predicates::text) || ']')::jsonb) as predicates
      from compound_predicate_from_children tree
        join lib_predicate.compound_predicate cp on cp.compound_predicate__id = tree.parent_compound_predicate__id
        join lib_predicate.compound_predicates cps on cps.compound_predicate__id = cp.compound_predicate__id
  )
  select
    predicate_tree.predicate_tree__id id,
    predicate_tree.config__id config,
    predicate_tree.created_at,
    predicate_tree.updated_at,
    compound_predicate_from_children.predicates
  from lib_predicate.predicate_tree
    inner join compound_predicate_from_children using (predicate_tree__id)
    where parent_compound_predicate__id is null;

create or replace function lib_predicate.tree_to_sql_query(predicate_tree__id$ uuid) returns text as
$$
declare
  predicate_trees$ jsonb;
begin
  select row_to_json(predicate_trees) from lib_predicate.predicate_trees where id = predicate_tree__id$ limit 1 into predicate_trees$;
  return lib_predicate.tree_to_sql_query(predicate_trees$->'predicates');
end;
$$ language plpgsql;
