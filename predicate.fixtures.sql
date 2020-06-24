\echo # filling table lib_predicate.config
COPY lib_predicate.config (config__id, label, description) FROM STDIN (FREEZE ON, DELIMITER ';');
00000000-0000-0000-0000-0000000000c1;To build;description
00000000-0000-0000-0000-0000000000c2;To delete config;description
00000000-0000-0000-0000-0000000000c3;Existing;description
00000000-0000-0000-0000-0000000000c4;Existing 2;description
\.

\echo # filling table lib_predicate.target
COPY lib_predicate.target (target__id, label, type__id) FROM STDIN (FREEZE ON, DELIMITER ';');
article.title;Article title;text
article.date;Article date;timestamptz
article.field;Article field;text
article.count;Article count;int
article.published_at;Article published;timestamptz
\.

\echo # filling table lib_predicate.config__target
COPY lib_predicate.config__target (config__id, target__id) FROM STDIN (FREEZE ON, DELIMITER ';');
00000000-0000-0000-0000-0000000000c3;article.field
00000000-0000-0000-0000-0000000000c4;article.title
00000000-0000-0000-0000-0000000000c4;article.date
00000000-0000-0000-0000-0000000000c4;article.count
\.

\echo # filling table lib_predicate.config__logical_type
COPY lib_predicate.config__logical_type (config__id, logical_type__id) FROM STDIN (FREEZE ON, DELIMITER ';');
00000000-0000-0000-0000-0000000000c3;any
00000000-0000-0000-0000-0000000000c4;all
00000000-0000-0000-0000-0000000000c4;any
\.

\echo # filling table lib_predicate.widget
COPY lib_predicate.widget (widget__id, label) FROM STDIN (FREEZE ON, DELIMITER ';');
to_delete;To delete
cannot_delete;Cannot delete
\.

create or replace function lib_predicate.to_delete(value$ text, argument$ jsonb) returns boolean as
$$
begin
  return false;
end;
$$ immutable language plpgsql;

create or replace function lib_predicate.lock_delete(value$ text, argument$ jsonb) returns boolean as
$$
begin
  return false;
end;
$$ immutable language plpgsql;

\echo # filling table lib_predicate.operator
COPY lib_predicate.operator (operator__id, label, type__id, widget__id) FROM STDIN (FREEZE ON, DELIMITER ';');
to_delete;=;text;text
lock_delete;=;text;cannot_delete
\.

\echo # filling table lib_predicate.predicate_tree
COPY lib_predicate.predicate_tree (predicate_tree__id, config__id) FROM STDIN (FREEZE ON, DELIMITER ';');
00000000-0000-0000-0000-0000000000f4;00000000-0000-0000-0000-0000000000c4
\.
