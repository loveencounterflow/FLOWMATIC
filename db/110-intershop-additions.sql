

/* ###################################################################################################### */
\ir '../intershop/db/010-trm.sql'
\ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
\set filename 110-intershop-additions.sql
-- -- \set ECHO queries

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
-- drop schema if exists U        cascade; create schema U;
-- drop schema if exists FM_TYPES  cascade; create schema FM_TYPES;
-- drop schema if exists FM_FSM    cascade; create schema FM_FSM;

-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
create or replace function U._array_regex_position( ¶texts text[], ¶regex text )
  returns bigint immutable parallel safe language sql as $$
    select nr from unnest( ¶texts ) with ordinality x ( d, nr )
    where d ~ ¶regex order by nr limit 1; $$;

-- ---------------------------------------------------------------------------------------------------------
create or replace function U._any_matches( ¶texts text[], ¶regex text )
  returns boolean immutable parallel safe language sql as $$
    select U._array_regex_position( ¶texts, ¶regex ) is not null; $$;

/* demo
select U._array_regex_position( array[ 'foo', 'bar', 'baz' ], '^b' );
select U._array_regex_position( array[ 'foo', 'bar', 'baz' ], 'a' );
select U._array_regex_position( array[ 'foo', 'bar', 'baz' ], '.' );
select U._array_regex_position( array[ 'foo', 'bar', 'baz' ], 'X' );
select U._array_regex_position( array[ 'foo', 'bar', 'baz' ], 'az' );
select U._any_matches( array[ 'foo', 'bar', 'baz' ], 'X' );
select U._any_matches( array[ 'foo', 'bar', 'baz' ], 'az' );
*/


/* ###################################################################################################### */
\echo :red ———{ :filename 2 }———:reset
\quit

