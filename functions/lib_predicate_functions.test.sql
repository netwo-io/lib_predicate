-- lib_predicate operator functions tests.

------------------ TEXT ---------------------

create or replace function lib_test.test_case_lib_predicate_text_equal_wrong_input() returns void as $$
begin

  begin
    perform lib_predicate.text_equal('text', '[]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Text equal should take one argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_text_equal_wrong_input2() returns void as $$
begin

  begin
    perform lib_predicate.text_equal('text', '{}'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Text equal should take one argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_text_equal_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.text_equal('text', '["text"]'::jsonb));
  perform lib_test.assert_false(lib_predicate.text_equal('texta', '["text"]'::jsonb));
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_text_not_equal_wrong_input() returns void as $$
begin

  begin
    perform lib_predicate.text_not_equal('text', '[]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Text not equal should take one argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_text_not_equal_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.text_not_equal('texta', '["text"]'::jsonb));
  perform lib_test.assert_false(lib_predicate.text_not_equal('text', '["text"]'::jsonb));
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_text_start_with_wrong_input() returns void as $$
begin

  begin
    perform lib_predicate.text_start_with('text', '[]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Text start with should take one argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_text_start_with_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.text_start_with('lorém ipsum sic amet', '["lorém ip"]'::jsonb));
  perform lib_test.assert_true(lib_predicate.text_start_with(':lorem ipsum sic amet', '[":lorem ip"]'::jsonb));
  perform lib_test.assert_false(lib_predicate.text_start_with('lorem ipsum sic amet', '["orem ip"]'::jsonb));
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_text_end_with_wrong_input() returns void as $$
begin

  begin
    perform lib_predicate.text_end_with('text', '[]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Text end with should take one argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_text_end_with_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.text_end_with('lorem ipsum sic amet', '[" amet"]'::jsonb));
  perform lib_test.assert_false(lib_predicate.text_end_with('lorem ipsum sic amet', '["text"]'::jsonb));
end;
$$ language plpgsql;

------------------ TIMESTAMPTZ ---------------------

create or replace function lib_test.test_case_lib_predicate_timestamptz_before_wrong_input() returns void as $$
begin

  begin
    perform lib_predicate.timestamptz_before('2020-05-2a', '["2020-05-28 10:07:31.390495+00"]'::jsonb);
  exception
    when others then return;
  end;
  perform lib_test.fail('Timestamptz require a valid timestamptz value');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_timestamptz_before_wrong_input2() returns void as $$
begin

  begin
    perform lib_predicate.timestamptz_before('2020-05-28 10:07:31.390495+00', '["not_a_timestamptz"]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Timestamptz before should take a timestamptz as argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_timestamptz_before_wrong_input3() returns void as $$
begin

  begin
    perform lib_predicate.timestamptz_before('2020-05-28 10:07:31.390495+00', '[]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Timestamptz before should take a timestamptz as argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_timestamptz_before_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.timestamptz_before('2020-05-28 10:07:31.390495+00', '["2020-05-28 10:07:31.390495+00"]'::jsonb));
  perform lib_test.assert_true(lib_predicate.timestamptz_before('2020-05-27 10:07:31.390495+00', '["2020-05-28 10:07:31.390495+00"]'::jsonb));
  perform lib_test.assert_false(lib_predicate.timestamptz_before('2020-05-29 10:07:31.390495+00', '["2020-05-28 10:07:31.390495+00"]'::jsonb));
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_timestamptz_after_wrong_input() returns void as $$
begin

  begin
    perform lib_predicate.timestamptz_after('2020-05-28 10:07:31.390495+00', '["not_a_timestamptz"]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Timestamptz after should take one argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_timestamptz_after_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.timestamptz_after('2020-05-28 10:07:31.390495+00', '["2020-05-28 10:07:31.390495+00"]'::jsonb));
  perform lib_test.assert_true(lib_predicate.timestamptz_after('2020-05-29 10:07:31.390495+00', '["2020-05-28 10:07:31.390495+00"]'::jsonb));
  perform lib_test.assert_false(lib_predicate.timestamptz_after('2020-05-27 10:07:31.390495+00', '["2020-05-28 10:07:31.390495+00"]'::jsonb));
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_timestamptz_between_wrong_input() returns void as $$
begin

  begin
    perform lib_predicate.timestamptz_between('2020-05-28 10:07:31.390495+00', '["2020-05-28 10:07:31.390495+00"]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Timestamptz between should take two argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_timestamptz_between_wrong_input2() returns void as $$
begin

  begin
    perform lib_predicate.timestamptz_between('2020-05-28 10:07:31.390495+00', '["2020-05-28 10:07:31.390495+00", "not_timestamptz"]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Timestamptz between should take two timestamptz argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_timestamptz_between_wrong_input3() returns void as $$
begin

  begin
    perform lib_predicate.timestamptz_between('2020-05-28 10:07:31.390495+00', '["2020-05-29 10:07:31.390495+00", "2020-05-28 10:07:31.390495+00"]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Timestamptz between argument 1 should be < argument 2');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_timestamptz_between_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.timestamptz_between('2020-05-29 10:07:31.390495+00', '["2020-05-28 10:07:31.390495+00", "2020-05-30 10:07:31.390495+00"]'::jsonb));
  perform lib_test.assert_true(lib_predicate.timestamptz_between('2020-05-28 10:07:31.390495+00', '["2020-05-28 10:07:31.390495+00", "2020-05-29 10:07:31.390495+00"]'::jsonb));
  perform lib_test.assert_false(lib_predicate.timestamptz_between('2020-05-28 10:07:31.390495+00', '["2020-05-27 10:07:31.390495+00", "2020-05-28 10:07:31.390495+00"]'::jsonb));
  perform lib_test.assert_false(lib_predicate.timestamptz_between('2020-05-28 10:07:31.390495+00', '["2020-05-24 10:07:31.390495+00", "2020-05-27 10:07:31.390495+00"]'::jsonb));
end;
$$ language plpgsql;

------------------ NUMBER ---------------------

create or replace function lib_test.test_case_lib_predicate_number_equal_wrong_input() returns void as $$
begin

  begin
    perform lib_predicate.number_equal('text', '[10]'::jsonb);
  exception
    when others then return;
  end;
  perform lib_test.fail('Number equal should take an int value');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_equal_wrong_input2() returns void as $$
begin

  begin
    perform lib_predicate.number_equal(10, '["art"]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Number equal should take one argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_equal_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.number_equal(10, '[10]'::jsonb));
  perform lib_test.assert_false(lib_predicate.number_equal(10, '[11]'::jsonb));
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_not_equal_wrong_input() returns void as $$
begin

  begin
    perform lib_predicate.number_not_equal(10, '["art"]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Number not equal should take one argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_not_equal_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.number_not_equal(10, '[11]'::jsonb));
  perform lib_test.assert_false(lib_predicate.number_not_equal(10, '[10]'::jsonb));
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_lower_wrong_input() returns void as $$
begin

  begin
    perform lib_predicate.number_lower(10, '["art"]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Number lower should take one argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_lower_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.number_lower(10, '[11]'::jsonb));
  perform lib_test.assert_false(lib_predicate.number_lower(10, '[10]'::jsonb));
  perform lib_test.assert_false(lib_predicate.number_lower(10, '[9]'::jsonb));
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_lower_equal_wrong_input() returns void as $$
begin

  begin
    perform lib_predicate.number_lower_equal(10, '["art"]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Number lower equal should take one argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_lower_equal_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.number_lower_equal(10, '[11]'::jsonb));
  perform lib_test.assert_true(lib_predicate.number_lower_equal(10, '[10]'::jsonb));
  perform lib_test.assert_false(lib_predicate.number_lower_equal(10, '[9]'::jsonb));
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_greater_wrong_input() returns void as $$
begin

  begin
    perform lib_predicate.number_greater(10, '["art"]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Number greater should take one argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_greater_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.number_greater(11, '[10]'::jsonb));
  perform lib_test.assert_false(lib_predicate.number_greater(10, '[10]'::jsonb));
  perform lib_test.assert_false(lib_predicate.number_greater(10, '[11]'::jsonb));
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_greater_equal_wrong_input() returns void as $$
begin

  begin
    perform lib_predicate.number_greater_equal(10, '["art"]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Number greater equal should take one argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_greater_equal_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.number_greater_equal(11, '[10]'::jsonb));
  perform lib_test.assert_true(lib_predicate.number_greater_equal(10, '[10]'::jsonb));
  perform lib_test.assert_false(lib_predicate.number_greater_equal(10, '[11]'::jsonb));
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_between_wrong_input() returns void as $$
begin

  begin
    perform lib_predicate.number_between(10, '["art"]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Number between should take two int argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_between_wrong_input2() returns void as $$
begin

  begin
    perform lib_predicate.number_between(10, '[10, "art"]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Number between should take one argument');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_between_wrong_input3() returns void as $$
begin

  begin
    perform lib_predicate.number_between(10, '[10, 10]'::jsonb);
  exception
    when check_violation then return;
  end;
  perform lib_test.fail('Number between argument 1 should be < argument 2');
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_number_between_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.number_between(10, '[10, 11]'::jsonb));
  perform lib_test.assert_true(lib_predicate.number_between(10, '[9, 100]'::jsonb));
  perform lib_test.assert_false(lib_predicate.number_between(10, '[8, 9]'::jsonb));
  perform lib_test.assert_false(lib_predicate.number_between(10, '[5, 10]'::jsonb));
end;
$$ language plpgsql;

------------------ NULL ---------------------

create or replace function lib_test.test_case_lib_predicate_is_null_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.is_null(null, '[]'::jsonb));
  perform lib_test.assert_false(lib_predicate.is_null('10', '[]'::jsonb));
  perform lib_test.assert_false(lib_predicate.is_null(10, '[]'::jsonb));
end;
$$ language plpgsql;

create or replace function lib_test.test_case_lib_predicate_is_not_null_success() returns void as $$
begin
  perform lib_test.assert_true(lib_predicate.is_not_null('10', '[]'::jsonb));
  perform lib_test.assert_true(lib_predicate.is_not_null(10, '[]'::jsonb));
  perform lib_test.assert_false(lib_predicate.is_not_null(null, '[]'::jsonb));
end;
$$ language plpgsql;
