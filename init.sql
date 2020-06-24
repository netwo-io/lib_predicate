-- library for managing predicate configuration and resolution.

drop schema if exists lib_predicate cascade;
create schema lib_predicate;
grant usage on schema lib_predicate to public;
set search_path = pg_catalog;

\ir ./functions/functions.sql
\ir ./config/config.sql
\ir ./predicate.sql

-- public views
\ir ./config/configs.sql
\ir ./predicates.sql
