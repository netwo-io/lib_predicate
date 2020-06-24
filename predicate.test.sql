-- lib_predicate tree tests.

create or replace function lib_test.test_case_lib_predicate_tree_upsert_success() returns void as $$
declare
  predicate_tree__id$ uuid default public.gen_random_uuid();
  trees$              jsonb;
  created_at$         text;
begin

  perform lib_predicate.predicate_tree_upsert(
    '00000000-0000-0000-0000-0000000000c4'::uuid,
    '{
      "logical_type_id": "all",
      "predicates": [
        {
          "target_id": "article.title",
          "operator_id": "text_equal",
          "argument": ["paradise"]
        }
      ]
    }'::jsonb,
    predicate_tree__id$
  );
  select row_to_json(predicate_trees) from lib_predicate.predicate_trees where id = predicate_tree__id$ limit 1 into trees$;
  perform lib_test.assert_equal((trees$->>'id')::uuid, predicate_tree__id$);
  perform lib_test.assert_equal((trees$->>'config')::uuid, '00000000-0000-0000-0000-0000000000c4'::uuid);
  created_at$ = trees$->>'created_at';
  perform lib_test.assert_not_null(created_at$, 'created_at should not be null on just inserted entity');
  perform lib_test.assert_null(trees$->>'updated_at', 'updated_at should be null on just inserted entity');

  perform lib_predicate.predicate_tree_upsert(
    '00000000-0000-0000-0000-0000000000c4'::uuid,
    '{
      "logical_type_id": "all",
      "predicates": [
        {
          "target_id": "article.title",
          "operator_id": "text_equal",
          "argument": ["paradise2"]
        }
      ]
    }'::jsonb,
    predicate_tree__id$
  );
  select row_to_json(predicate_trees) from lib_predicate.predicate_trees where id = predicate_tree__id$ limit 1 into trees$;
  perform lib_test.assert_equal((trees$->>'id')::uuid, predicate_tree__id$);
  perform lib_test.assert_equal((trees$->>'config')::uuid, '00000000-0000-0000-0000-0000000000c4'::uuid);
  perform lib_test.assert_equal(created_at$, (trees$->>'created_at')::text);
  perform lib_test.assert_not_null(trees$->>'updated_at', 'updated_at should not be null on updated entity');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_tree_delete() returns void as $$
declare
  predicate_tree__id$ uuid default '00000000-0000-0000-0000-0000000000f4'::uuid;
  count$              int;
begin

  perform lib_predicate.predicate_tree_delete(predicate_tree__id$);
  select count(1) from lib_predicate.predicate_trees where id = predicate_tree__id$ limit 1 into count$;
  perform lib_test.assert_equal(count$, 0);
  -- check idempotency.
  perform lib_predicate.predicate_tree_delete(predicate_tree__id$);
end;
$$ language plpgsql;

-- Serialized tree structure validation.

create or replace function lib_test.test_case_lib_predicate_tree_upsert_tree_invalid_target() returns void as $$
begin

  begin
    perform lib_predicate.predicate_tree_upsert('00000000-0000-0000-0000-0000000000c4'::uuid, '{
      "logical_type_id": "all",
      "predicates": [
        {
          "target_id": "article.published_at",
          "operator_id": "timestamptz_between",
          "argument": ["2020-05-24 10:07:31.390495+00", "2020-05-27 10:07:31.390495+00"]
        }
      ]
    }'::jsonb);
  exception
    when foreign_key_violation then return;
  end;
  perform lib_test.fail('Using target__id not linked to tree config should fail.');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_tree_upsert_tree_invalid_structure() returns void as $$
begin

  begin
    perform lib_predicate.predicate_tree_upsert('00000000-0000-0000-0000-0000000000c4'::uuid, '{
      "logical_type": "all",
      "predicates": [
        {
          "target_id": "article.title",
          "operator_id": "text_equal",
          "argument": ["paradise"]
        }
      ]
    }'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Wrongly formatted compound should fail.');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_tree_upsert_tree_invalid_structure2() returns void as $$
begin

  begin
    perform lib_predicate.predicate_tree_upsert('00000000-0000-0000-0000-0000000000c4'::uuid, '{
      "logical_type_id": "all",
      "predicates": [ ]
    }'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Wrongly formatted compound should fail.');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_tree_upsert_tree_invalid_structure3() returns void as $$
begin

  begin
    perform lib_predicate.predicate_tree_upsert('00000000-0000-0000-0000-0000000000c4'::uuid, '{
      "logical_type_id": "all",
      "predicates": [
        {
          "targEt_id": "article.title",
          "operator_id": "text_equal",
          "argument": ["paradise"]
        }
      ]
    }'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Wrongly formatted predicate should fail.');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_tree_upsert_tree_invalid_structure3() returns void as $$
begin

  begin
    perform lib_predicate.predicate_tree_upsert('00000000-0000-0000-0000-0000000000c4'::uuid, '{
      "logical_type_id": "all",
      "predicates": [
        {
          "target_id": "article.title",
          "operator_id": "text_equal",
          "argument": "paradise"
        }
      ]
    }'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Wrongly formatted predicate should fail.');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_tree_upsert_tree_invalid_structure3() returns void as $$
begin

  begin
    perform lib_predicate.predicate_tree_upsert('00000000-0000-0000-0000-0000000000c4'::uuid, '{
      "logical_type_id": "all",
      "predicates": [
        {
          "target_id": "012-articletitle",
          "operator_id": "text_equal",
          "argument": "paradise"
        }
      ]
    }'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Wrongly formatted predicate should fail.');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_tree_upsert_tree_full_success() returns void as $$
declare
  predicate_tree__id$ uuid;
  predicate_trees$    jsonb;
  sql_query$          text;
begin

  predicate_tree__id$ = lib_predicate.predicate_tree_upsert('00000000-0000-0000-0000-0000000000c4'::uuid, '{
      "logical_type_id": "all",
      "predicates": [
        {
          "target_id": "article.title",
          "operator_id": "text_equal",
          "argument": ["paradise"]
        },
        {
          "target_id": "article.count",
          "operator_id": "number_greater",
          "argument": [2]
        },
        {
          "logical_type_id": "none",
          "predicates": [
            {
              "target_id": "article.date",
              "operator_id": "timestamptz_between",
              "argument": [
                "2017-10-05",
                "2018-10-05"
              ]
            },
            {
              "target_id": "article.date",
              "operator_id": "timestamptz_between",
              "argument": [
                "2010-10-05",
                "2011-10-05"
              ]
            }
          ]
        }
      ]
    }'::jsonb);

  select row_to_json(predicate_trees) from lib_predicate.predicate_trees where id = predicate_tree__id$ limit 1 into predicate_trees$;

  perform lib_test.assert_equal((predicate_trees$->>'id')::uuid, predicate_tree__id$);
  perform lib_test.assert_equal(predicate_trees$->'predicates'->>'logical_type_id', 'all');
  perform lib_test.assert_equal(predicate_trees$->'predicates'#>'{predicates,0}'->>'logical_type_id', 'none');
  perform lib_test.assert_equal(predicate_trees$->'predicates'#>'{predicates,1}'->>'operator_id', 'text_equal');
  perform lib_test.assert_equal(predicate_trees$->'predicates'#>'{predicates,1}'->>'target_id', 'article.title');
  perform lib_test.assert_equal(predicate_trees$->'predicates'#>'{predicates,1}'->>'argument', '["paradise"]');

  sql_query$ = $_$select article.title, article.date, article.count from article where  (NOT (lib_predicate.timestamptz_between(article.date, '["2017-10-05", "2018-10-05"]') AND lib_predicate.timestamptz_between(article.date, '["2010-10-05", "2011-10-05"]')) AND lib_predicate.text_equal(article.title, '["paradise"]') AND lib_predicate.number_greater(article.count, '[2]'))$_$;
  perform lib_test.assert_equal(lib_predicate.tree_to_sql_query(predicate_tree__id$), sql_query$);
  perform lib_test.assert_equal(lib_predicate.tree_to_sql_query(predicate_trees$->'predicates'), sql_query$);
end;
$$ language plpgsql;
