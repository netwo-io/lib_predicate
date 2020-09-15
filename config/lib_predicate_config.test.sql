-- lib_predicate config tests.

create or replace function lib_predicate.operator_test(value text, argument jsonb) returns boolean as
$$
begin
  return false;
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.operator_test2(value text, argument jsonb) returns boolean as
$$
begin
  return false;
end;
$$ immutable language plpgsql;

-- Target

create or replace function lib_test.test_case_lib_predicate_cannot_create_target_w_invalid_id() returns void as $$
begin

  begin
    perform lib_predicate.target_create('ar', 'Article title', 'text');
  exception
    when check_violation then
      perform lib_test.assert_equal(sqlerrm, 'value for domain lib_predicate.target_identifier violates check constraint "target_identifier_check"');
      return;
  end;
  perform lib_test.fail('Target with invalid id should not be created');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_cannot_create_target_w_invalid_type() returns void as $$
begin

  begin
    perform lib_predicate.target_create('article', 'Article title', 'unexisting_type');
  exception
    when foreign_key_violation then
      perform lib_test.assert_equal(sqlerrm, 'insert or update on table "target" violates foreign key constraint "target_type__id_fkey"');
      return;
  end;
  perform lib_test.fail('Target with invalid type should not be created');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_cannot_create_target_w_in_use_id() returns void as $$
begin

  begin
    perform lib_predicate.target_create('article.title', 'Article title', 'text');
  exception
    when unique_violation then
      perform lib_test.assert_equal(sqlerrm, 'duplicate key value violates unique constraint "target_pkey"');
      return;
  end;
  perform lib_test.fail('Duplicate target id should not be possible.');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_can_create_target() returns void as $$
declare
  target__id$ varchar;
begin
  select lib_predicate.target_create('article.titlee', 'Article title', 'text') into target__id$;
  perform lib_test.assert_not_null(target__id$, 'Target not created');
end;
$$ language plpgsql;

-- Config

create or replace function lib_test.test_case_lib_predicate_cannot_create_config_w_invalid_label() returns void as $$
begin

  begin
    perform lib_predicate.config_create('', 'My first config description');
  exception
    when check_violation then
      perform lib_test.assert_equal(sqlerrm, 'value for domain lib_predicate.label violates check constraint "label_check"');
      return;
  end;
  perform lib_test.fail('Config should not be created with invalid label');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_can_create_config() returns void as $$
declare
  config__id$ uuid;
  configs$    jsonb;
begin

  select lib_predicate.config_create('My first config', 'My first config description') into config__id$;
  perform lib_test.assert_not_null(config__id$, 'Config not created');
  select row_to_json(configs) from lib_predicate.configs where id = config__id$ limit 1 into configs$;
  perform lib_test.assert_equal((configs$->>'id')::uuid, config__id$);
  perform lib_test.assert_equal(configs$->>'label', 'My first config');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_can_delete_config() returns void as $$
declare
  config__id$ uuid;
  count$      int;
begin

  config__id$ = '00000000-0000-0000-0000-0000000000c2'::uuid;
  perform lib_predicate.config_delete(config__id$);
  select count(1) from lib_predicate.configs where id = config__id$ limit 1 into count$;
  perform lib_test.assert_equal(count$, 0);
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_cannot_enable_unexisting_logical_type() returns void as $$
begin

  begin
    perform lib_predicate.config_enable_logical_type('00000000-0000-0000-0000-0000000000c1'::uuid, 'not_existing');
  exception
    when foreign_key_violation then
      perform lib_test.assert_equal(sqlerrm, 'insert or update on table "config__logical_type" violates foreign key constraint "config__logical_type_logical_type__id_fkey"');
      return;
  end;
  perform lib_test.fail('Not existing logical type should not be activable in config');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_cannot_enable_logical_type_without_config() returns void as $$
begin

  begin
    perform lib_predicate.config_enable_logical_type('00000000-0000-0000-ffff-0000000000c0'::uuid, 'all');
  exception
    when foreign_key_violation then
      perform lib_test.assert_equal(sqlerrm, 'insert or update on table "config__logical_type" violates foreign key constraint "config__logical_type_config__id_fkey"');
      return;
  end;
  perform lib_test.fail('Enable a logical type on an inexisting config should fail.');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_can_enable_logical_type() returns void as $$
declare
  config__id$ uuid;
  configs$    jsonb;
begin
  config__id$ = '00000000-0000-0000-0000-0000000000c1';
  perform lib_predicate.config_enable_logical_type(config__id$, 'all');
  select row_to_json(configs) from lib_predicate.configs where id = config__id$ limit 1 into configs$;
  perform lib_test.assert_equal(configs$#>'{logical_types,0}'->>'id', 'all');
  perform lib_test.assert_equal(configs$#>'{logical_types,0}'->>'label', 'All');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_can_disable_logical_type() returns void as $$
declare
  config__id$ uuid;
  configs$    jsonb;
begin

  config__id$ = '00000000-0000-0000-0000-0000000000c3';
  select row_to_json(configs) from lib_predicate.configs where id = config__id$ limit 1 into configs$;
  perform lib_test.assert_equal(configs$#>'{logical_types,0}'->>'id', 'any');

  perform lib_predicate.config_disable_logical_type(config__id$, 'any');
  select row_to_json(configs) from lib_predicate.configs where id = config__id$ limit 1 into configs$;
  perform lib_test.assert_equal(jsonb_array_length(configs$->'logical_types'), 0);
  -- Delete should be idempotent.
  perform lib_predicate.config_disable_logical_type(config__id$, 'any');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_cannot_enable_unexisting_target() returns void as $$
begin

  begin
    perform lib_predicate.config_enable_target('00000000-0000-0000-0000-0000000000c1'::uuid, 'resource.not_existing');
  exception
    when foreign_key_violation then
      perform lib_test.assert_equal(sqlerrm, 'insert or update on table "config__target" violates foreign key constraint "config__target_target__id_fkey"');
      return;
  end;
  perform lib_test.fail('Not existing target should not be activable in config');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_cannot_enable_target_without_config() returns void as $$
begin

  begin
    perform lib_predicate.config_enable_target('00000000-0000-0000-ffff-0000000000c0'::uuid, 'article.title');
  exception
    when foreign_key_violation then
      perform lib_test.assert_equal(sqlerrm, 'insert or update on table "config__target" violates foreign key constraint "config__target_config__id_fkey"');
      return;
  end;
  perform lib_test.fail('Enable a target on an inexisting config should fail.');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_can_enable_target() returns void as $$
declare
  config__id$ uuid;
  configs$    jsonb;
begin

  config__id$ = '00000000-0000-0000-0000-0000000000c1';
  perform lib_predicate.config_enable_target(config__id$, 'article.title');
  select row_to_json(configs) from lib_predicate.configs where id = config__id$ limit 1 into configs$;
  perform lib_test.assert_equal(configs$#>'{targets,0}'->>'id', 'article.title');
  perform lib_test.assert_equal(configs$#>'{targets,0}'->>'label', 'Article title');
  perform lib_test.assert_equal(configs$#>'{targets,0}'->>'type', 'text');

  perform lib_test.assert_equal(configs$#>'{types,0}'->>'id', 'text');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_can_disable_target() returns void as $$
declare
  config__id$ uuid;
  configs$    jsonb;
begin

  config__id$ = '00000000-0000-0000-0000-0000000000c3';
  select row_to_json(configs) from lib_predicate.configs where id = config__id$ limit 1 into configs$;
  perform lib_test.assert_equal(configs$#>'{targets,0}'->>'id', 'article.field');
  perform lib_test.assert_equal(configs$#>'{types,0}'->>'id', 'text');

  perform lib_predicate.config_disable_target(config__id$, 'article.field');
  select row_to_json(configs) from lib_predicate.configs where id = config__id$ limit 1 into configs$;
  perform lib_test.assert_equal(jsonb_array_length(configs$->'targets'), 0);
  perform lib_test.assert_equal(jsonb_array_length(configs$->'types'), 0);
  -- Delete should be idempotent.
  perform lib_predicate.config_disable_target(config__id$, 'article.field');
end;
$$ language plpgsql;

-- Widget

create or replace function lib_test.test_case_lib_predicate_cannot_create_widget_w_in_use_id() returns void as $$
begin

  begin
    perform lib_predicate.widget_create('text', 'Short text');
  exception
    when unique_violation then
      perform lib_test.assert_equal(sqlerrm, 'duplicate key value violates unique constraint "widget_pkey"');
      return;
  end;
  perform lib_test.fail('Duplicate widget should not be possible.');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_can_create_widget() returns void as $$
declare
  widget__id$ varchar;
begin
  select lib_predicate.widget_create('text_bis', 'Shorter text') into widget__id$;
  perform lib_test.assert_not_null(widget__id$, 'Widget not created');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_cannot_delete_widget_in_use() returns void as $$
begin

  begin
    perform lib_predicate.widget_delete('cannot_delete');
  exception
    when foreign_key_violation then
      perform lib_test.assert_equal(sqlerrm, 'update or delete on table "widget" violates foreign key constraint "operator_widget__id_fkey" on table "operator"');
      return;
  end;
  perform lib_test.fail('In use widget should not be deletable.');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_can_delete_widget() returns void as $$
declare
  count$ int;
begin
  perform lib_predicate.widget_delete('to_delete');
  select count(*) from lib_predicate.widget where widget__id = 'to_delete' into count$;
  perform lib_test.assert_equal(count$, 0);
  -- Check idempotency.
  perform lib_predicate.widget_delete('to_delete');
end;
$$ language plpgsql;

-- Operator

create or replace function lib_test.test_case_lib_predicate_cannot_create_operator_wo_function() returns void as $$
begin

  begin
    perform lib_predicate.operator_create('operator_test_not_exist', 'Text is equal to', 'text', 'text');
  exception
    when check_violation then
      perform lib_test.assert_equal(sqlerrm, 'an operator__id must have a lib_predicate function counterpart.');
      return;
  end;
  perform lib_test.fail('Create an operator without a bound function should not be possible.');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_cannot_create_operator_w_in_use_id() returns void as $$
begin

  begin
    perform lib_predicate.operator_create('text_equal', 'Text is equal to', 'text', 'text');
  exception
    when unique_violation then
      perform lib_test.assert_equal(sqlerrm, 'duplicate key value violates unique constraint "operator_pkey"');
      return;
  end;
  perform lib_test.fail('Duplicate operator should not be possible.');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_cannot_create_operator_w_invalid_arg_type() returns void as $$
begin

  begin
    perform lib_predicate.operator_create('operator_test2', 'Text is equal to', 'texty', 'text');
  exception
    when foreign_key_violation then
      perform lib_test.assert_equal(sqlerrm, 'insert or update on table "operator" violates foreign key constraint "operator_type__id_fkey"');
      return;
  end;
  perform lib_test.fail('Create an operator with an invalid argument type should not be possible.');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_cannot_create_operator_w_invalid_widget() returns void as $$
begin

  begin
    perform lib_predicate.operator_create('operator_test2', 'Text is equal to', 'text', 'not_existing_widget');
  exception
    when foreign_key_violation then
      perform lib_test.assert_equal(sqlerrm, 'insert or update on table "operator" violates foreign key constraint "operator_widget__id_fkey"');
      return;
  end;
  perform lib_test.fail('Create an operator with an invalid widget should not be possible.');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_can_create_operator() returns void as $$
declare
  operator__id$ varchar;
begin
  select lib_predicate.operator_create('operator_test', 'Text is equal to', 'text', 'text') into operator__id$;
  perform lib_test.assert_not_null(operator__id$, 'Operator not created');
  perform lib_predicate.operator_delete('operator_test');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_can_delete_operator() returns void as $$
declare
  count$ int;
begin
  perform lib_predicate.operator_delete('to_delete');
  select count(*) from lib_predicate.operator where operator__id = 'to_delete' into count$;
  perform lib_test.assert_equal(count$, 0);
  -- Check idempotency.
  perform lib_predicate.operator_delete('to_delete');
end;
$$ language plpgsql;

-- View

create or replace function lib_test.test_case_lib_predicate_can_read_config() returns void as $$
declare
  configs$ jsonb;
begin

  select row_to_json(configs) from lib_predicate.configs where id = '00000000-0000-0000-0000-0000000000c4' into configs$;
  perform lib_test.assert_equal(configs$->>'id', '00000000-0000-0000-0000-0000000000c4');
  perform lib_test.assert_equal(configs$->>'label', 'Existing 2');
  perform lib_test.assert_equal(configs$->'logical_types', '[{"id" : "all", "label" : "All"}, {"id" : "any", "label" : "One of"}]'::jsonb);
  perform lib_test.assert_equal(configs$#>'{operators,0}'->>'id', 'text_equal');
  perform lib_test.assert_equal(configs$#>'{operators,0}'->>'label', '=');
  perform lib_test.assert_equal(configs$#>'{operators,0}'->>'widget', 'text');
  perform lib_test.assert_equal(configs$#>'{targets,0}'->>'id', 'article.title');
  perform lib_test.assert_equal(configs$#>'{targets,0}'->>'label', 'Article title');
  perform lib_test.assert_equal(configs$#>'{targets,0}'->>'type', 'text');
  perform lib_test.assert_equal(configs$#>'{types,0}'->>'id', 'text');
  perform lib_test.assert_true(jsonb_array_length(configs$#>'{types,0}'->'operators') > 0);
end;
$$ language plpgsql;
