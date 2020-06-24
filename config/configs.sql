create view lib_predicate.configs as
  select
    config.config__id id,
    config.label,
    coalesce(logical_types, '[]'::json) as logical_types,
    coalesce(operators, '[]'::json) as operators,
    coalesce(targets, '[]'::json) as targets,
    coalesce(types, '[]'::json) as types
  from lib_predicate.config
    -- Build logical_types.
    left join lateral (
      select
        config.config__id,
        json_agg(
          json_build_object(
            'id', logical_type.logical_type__id,
            'label', logical_type.label
          )
        ) as logical_types
      from lib_predicate.logical_type
        inner join lib_predicate.config__logical_type clt on logical_type.logical_type__id = clt.logical_type__id and config.config__id = clt.config__id
        group by config__id
    ) as logical_types on true
    -- Build targets.
    left join lateral (
      select
        config.config__id,
        json_agg(
          json_build_object(
            'id', target.target__id,
            'label', target.label,
            'type', target.type__id
          )
        ) as targets
      from lib_predicate.target
        inner join lib_predicate.config__target ct on target.target__id = ct.target__id and config.config__id = ct.config__id
        group by config__id
    ) as targets on targets.config__id = config.config__id
    -- Build types.
    left join lateral (
      select
        config__id,
        json_agg(
          json_build_object(
            'id', type.type__id,
            'operators', operators
          )
        ) as types
      from lib_predicate.type
        inner join lib_predicate.target on type.type__id = target.type__id
        inner join lib_predicate.config__target ct on target.target__id = ct.target__id and config.config__id = ct.config__id
        inner join lateral (
          select array_agg(operator__id) operators from lib_predicate.operator
            where operator.type__id = type.type__id
            group by operator.type__id
        ) as operators on true
      group by config__id
    ) as types on types.config__id = config.config__id
    -- Build operators.
    left join lateral (
      select
        config__id,
        json_agg(
          json_build_object(
            'id', operator.operator__id,
            'label', operator.label,
            'widget', operator.widget__id
          )
        ) as operators
      from lib_predicate.operator
        inner join lib_predicate.target using (type__id)
        inner join lib_predicate.config__target ct on target.target__id = ct.target__id and config.config__id = ct.config__id
      group by config__id
    ) as operators on operators.config__id = config.config__id;
