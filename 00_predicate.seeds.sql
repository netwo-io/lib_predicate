truncate lib_predicate.logical_type restart identity cascade;
truncate lib_predicate.type restart identity cascade;
truncate lib_predicate.widget restart identity cascade;
truncate lib_predicate.config restart identity cascade;

\echo # filling table lib_predicate.logical_type
COPY lib_predicate.logical_type (logical_type__id, label, description) FROM STDIN (FREEZE ON, DELIMITER ';');
all;All;All statements must match
any;One of;At least one statement must match
none;None;None of the statements must match
\.

\echo # filling table lib_predicate.type
COPY lib_predicate.type (type__id) FROM STDIN (FREEZE ON, DELIMITER ';');
int
text
timestamptz
\.

\echo # filling table lib_predicate.widget
COPY lib_predicate.widget (widget__id, label) FROM STDIN (FREEZE ON, DELIMITER ';');
varchar;Small string
text;Large string
number;Number
number_range;Number between
date;Date
date_range;Date between
void;No value required
\.

\echo # filling table lib_predicate.operator
COPY lib_predicate.operator (operator__id, label, type__id, widget__id) FROM STDIN (FREEZE ON, DELIMITER ';');
text_equal;=;text;text
text_not_equal;!=;text;text
text_start_with;Start with;text;varchar
text_end_with;End with;text;varchar
timestamptz_before;<;timestamptz;date
timestamptz_after;>;timestamptz;date
timestamptz_between;Between dates;timestamptz;date_range
number_equal;=;int;number
number_not_equal;!=;int;number
number_lower;<;int;number
number_lower_equal;<=;int;number
number_greater;>;int;number
number_greater_equal;>=;int;number
number_between;Between numbers;int;number_range
is_null;Does not exist;text;void
is_not_null;Exist;text;void
\.
