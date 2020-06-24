-- lib_predicate functions.

------------------ PRIVATE API ---------------------

create or replace function lib_predicate._get_args_as_array(argument$ jsonb) returns text[] as
$$
begin
  if jsonb_typeof(argument$) != 'array' then
    raise 'argument should be a jsonb array' using errcode = 'check_violation';
  end if;
  return array(select jsonb_array_elements_text(argument$));
end;
$$ immutable language plpgsql;

create or replace function lib_predicate._get_int_arg_at(argument$ text[], index$ int) returns int as
$$
declare
  length$ int;
begin

  begin
    length$ = array_length(argument$, 1);
    if length$ is not null and length$ >= index$ then
      return argument$[index$]::int;
    end if;
  exception
    when others then null;
  end;
  raise 'require an int arg value as argument[%]', index$::text using errcode = 'check_violation';
end;
$$ immutable language plpgsql;

create or replace function lib_predicate._get_text_arg_at(argument$ text[], index$ int) returns text as
$$
declare
  length$ int;
begin

  begin
    length$ = array_length(argument$, 1);
    if length$ is not null and length$ >= index$ then
      return argument$[index$]::text;
    end if;
  exception
    when others then null;
  end;
  raise 'require a text arg value as argument[%]', index$::text using errcode = 'check_violation';
end;
$$ immutable language plpgsql;

create or replace function lib_predicate._get_timestamptz_arg_at(argument$ text[], index$ int) returns timestamptz as
$$
declare
  length$ int;
begin

  begin
    length$ = array_length(argument$, 1);
    if length$ is not null and length$ >= index$ then
      return argument$[index$]::timestamptz;
    end if;
  exception
    when others then null;
  end;
  raise 'require a timestamptz arg value as argument[%]', index$::text using errcode = 'check_violation';
end;
$$ immutable language plpgsql;

------------------ TEXT ---------------------

create or replace function lib_predicate.text_equal(value$ text, argument$ jsonb) returns boolean as
$$
begin

  if value$ is null then
    raise 'require text value' using errcode = 'check_violation';
  end if;

  return value$ = lib_predicate._get_text_arg_at(lib_predicate._get_args_as_array(argument$), 1);
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.text_not_equal(value$ text, argument$ jsonb) returns boolean as
$$
begin

  if value$ is null then
    raise 'require text value' using errcode = 'check_violation';
  end if;

  return value$ != lib_predicate._get_text_arg_at(lib_predicate._get_args_as_array(argument$), 1);
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.text_start_with(value$ text, argument$ jsonb) returns boolean as
$$
declare
  arg$  text;
begin

  if value$ is null then
    raise 'require text value' using errcode = 'check_violation';
  end if;

  arg$ = lib_predicate._get_text_arg_at(lib_predicate._get_args_as_array(argument$), 1);
  return left(value$, length(arg$)) = arg$;
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.text_end_with(value$ text, argument$ jsonb) returns boolean as
$$
declare
  arg$  text;
begin

  if value$ is null then
    raise 'require text value' using errcode = 'check_violation';
  end if;

  arg$ = lib_predicate._get_text_arg_at(lib_predicate._get_args_as_array(argument$), 1);
  return right(value$, length(arg$)) = arg$;
end;
$$ immutable language plpgsql;

------------------ TIMESTAMPTZ ---------------------

create or replace function lib_predicate.timestamptz_before(value$ timestamptz, argument$ jsonb) returns boolean as
$$
begin

  if value$ is null then
    raise 'require timestamptz value' using errcode = 'check_violation';
  end if;

  return value$ <= lib_predicate._get_timestamptz_arg_at(lib_predicate._get_args_as_array(argument$), 1);
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.timestamptz_after(value$ timestamptz, argument$ jsonb) returns boolean as
$$
begin

  if value$ is null then
    raise 'require timestamptz value' using errcode = 'check_violation';
  end if;

  return value$ >= lib_predicate._get_timestamptz_arg_at(lib_predicate._get_args_as_array(argument$), 1);
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.timestamptz_between(value$ timestamptz, argument$ jsonb) returns boolean as
$$
declare
  args$        text[];
  lower_bound$ timestamptz;
  upper_bound$ timestamptz;
begin

  if value$ is null then
    raise 'require timestamptz value' using errcode = 'check_violation';
  end if;

  args$ = lib_predicate._get_args_as_array(argument$);
  lower_bound$ = lib_predicate._get_timestamptz_arg_at(args$, 1);
  upper_bound$ = lib_predicate._get_timestamptz_arg_at(args$, 2);

  if lower_bound$ >= upper_bound$ then
    raise 'argument[1]::timestamptz should be lower then argument[2]::timestamptz' using errcode = 'check_violation';
  end if;
  return lower_bound$ <= value$ and value$ < upper_bound$;
end;
$$ immutable language plpgsql;

------------------ NUMBER ---------------------

create or replace function lib_predicate.number_equal(value$ int, argument$ jsonb) returns boolean as
$$
begin

  if value$ is null then
    raise 'require int value' using errcode = 'check_violation';
  end if;

  return value$ = lib_predicate._get_int_arg_at(lib_predicate._get_args_as_array(argument$), 1);
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.number_not_equal(value$ int, argument$ jsonb) returns boolean as
$$
begin

  if value$ is null then
    raise 'require int value' using errcode = 'check_violation';
  end if;

  return value$ != lib_predicate._get_int_arg_at(lib_predicate._get_args_as_array(argument$), 1);
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.number_lower(value$ int, argument$ jsonb) returns boolean as
$$
begin

  if value$ is null then
    raise 'require int value' using errcode = 'check_violation';
  end if;

  return value$ < lib_predicate._get_int_arg_at(lib_predicate._get_args_as_array(argument$), 1);
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.number_lower_equal(value$ int, argument$ jsonb) returns boolean as
$$
begin

  if value$ is null then
    raise 'require int value' using errcode = 'check_violation';
  end if;

  return value$ <= lib_predicate._get_int_arg_at(lib_predicate._get_args_as_array(argument$), 1);
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.number_greater(value$ int, argument$ jsonb) returns boolean as
$$
begin

  if value$ is null then
    raise 'require int value' using errcode = 'check_violation';
  end if;

  return value$ > lib_predicate._get_int_arg_at(lib_predicate._get_args_as_array(argument$), 1);
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.number_greater_equal(value$ int, argument$ jsonb) returns boolean as
$$
begin

  if value$ is null then
    raise 'require int value' using errcode = 'check_violation';
  end if;

  return value$ >= lib_predicate._get_int_arg_at(lib_predicate._get_args_as_array(argument$), 1);
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.number_between(value$ int, argument$ jsonb) returns boolean as
$$
declare
  args$        text[];
  lower_bound$ int;
  upper_bound$ int;
begin

  if value$ is null then
    raise 'require int value' using errcode = 'check_violation';
  end if;

  args$ = lib_predicate._get_args_as_array(argument$);
  lower_bound$ = lib_predicate._get_int_arg_at(args$, 1);
  upper_bound$ = lib_predicate._get_int_arg_at(args$, 2);

  if lower_bound$ >= upper_bound$ then
    raise 'argument[1]::int should be lower then argument[2]::int' using errcode = 'check_violation';
  end if;
  return lower_bound$ <= value$ and value$ < upper_bound$;
end;
$$ immutable language plpgsql;

------------------ NULL ---------------------

create or replace function lib_predicate.is_null(value$ text, jsonb) returns boolean as
$$
begin
  return value$ is null;
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.is_null(value$ int, jsonb) returns boolean as
$$
begin
  return value$ is null;
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.is_not_null(value$ text, jsonb) returns boolean as
$$
begin
  return value$ is not null;
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.is_not_null(value$ int, jsonb) returns boolean as
$$
begin
  return value$ is not null;
end;
$$ immutable language plpgsql;
