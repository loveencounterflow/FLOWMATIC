
\ir '../../intershop/db/010-trm.sql'
\timing off
\set X :yellow


-- turn off echo and keep things quiet.
-- format the output for nice tap.
\set echo none
\set quiet 1
-- \pset format unaligned
-- \pset tuples_only true
\pset pager off

-- revert all changes on failure.
\set on_error_rollback 1
\set on_error_stop true

-- ---------------------------------------------------------------------------------------------------------
begin;

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists T cascade;
create schema T;

-- ---------------------------------------------------------------------------------------------------------
create type T.outcome as enum ( 'eq', 'error' );

-- ---------------------------------------------------------------------------------------------------------
create table T.probes_and_matchers (
  function_name text not null,
  p1_txt        text,
  p1_cast       text not null,
  expect        T.outcome,
  match_txt     text,
  match_type    text );

-- ---------------------------------------------------------------------------------------------------------
create unique index on T.probes_and_matchers
 ( function_name, p1_txt, p1_cast, expect, match_txt, match_type );

-- ---------------------------------------------------------------------------------------------------------
/* thx to https://stackoverflow.com/a/10711349/7568091 for using `regclass` and `format( '...%s...' )` */
create function T.test_functions( ¶pm_table_name text )
  returns table (
    function_name_q   text,
    p1_txt_q          text,
    p1_cast_q         text,
    expect_q          text,
    result_txt_q      text,
    result_type_q     text,
    ok                boolean )
  volatile language plpgsql as $outer$
  declare
    ¶x              record;
    ¶result         record;
    ¶Q1             text;
    ¶Q2             text;
    ¶message        text;
    ¶nr             integer := 0;
    ¶match_txt_q    text;
    ¶match_type_q   text;
  -- .......................................................................................................
  begin
    ¶Q1 := format( $$ select * from %s $$, ¶pm_table_name );
    -- .....................................................................................................
    for ¶x in execute ¶Q1 loop begin
      ¶nr               :=  ¶nr + 1;
      function_name_q   :=  quote_literal( ¶x.function_name );
      p1_txt_q          :=  quote_nullable( ¶x.p1_txt );
      p1_cast_q         :=  quote_nullable( ¶x.p1_cast );
      expect_q          :=  quote_nullable( ¶x.expect );
      result_txt_q      :=  null;
      result_type_q     :=  null;
      ok                :=  false;
      ¶message          :=  null;
      -- ...................................................................................................
      ¶Q2 :=  format( $$ with v1 as (
        select
            %s( $1::%s ) as value )
        select
            v1.value::text                  as value_txt,
            ( pg_typeof( v1.value ) )::text as type_txt
          from v1; $$,
        ¶x.function_name,
        ¶x.p1_cast );
      -- ...................................................................................................
      execute ¶Q2 using ¶x.p1_txt into ¶result;
      result_txt_q  :=  quote_nullable( ¶result.value_txt   );
      result_type_q :=  quote_nullable( ¶result.type_txt    );
      -- ...................................................................................................
      ok        :=  true
        and ( ¶result.value_txt is not distinct from ¶x.match_txt   )
        and ( ¶result.type_txt  is not distinct from ¶x.match_type  );
      -- ...................................................................................................
      if not ok then
        ¶match_txt_q  :=  quote_nullable( ¶x.match_txt  );
        ¶match_type_q :=  quote_nullable( ¶x.match_type );
        perform log( '10091 expected  ', function_name_q, p1_txt_q, p1_cast_q, ¶match_txt_q, ¶match_type_q );
        perform log( '10091 actual    ', function_name_q, p1_txt_q, p1_cast_q, result_txt_q, result_type_q );
        end if;
      -- ...................................................................................................
      return next;
      -- ...................................................................................................
      exception when others then
        raise notice '(sqlstate) sqlerrm: (%) %', sqlstate, sqlerrm;
        ¶message      := format( '(%s) %s', sqlstate, sqlerrm );
        result_txt_q  := quote_nullable( ¶message );
        ok            := ¶x.expect = 'error' and ¶x.match_txt = ¶message;
        return next;
      end; end loop;
    -- .....................................................................................................
    end; $outer$;



/* #########################################################################################################

 .d8888b.
d88P  Y88b
       888
     .d88P
 .od888P"
d88P"
888"
888888888

######################################################################################################### */

-- ---------------------------------------------------------------------------------------------------------
drop schema if exists T2 cascade;
create schema T2;

-- ---------------------------------------------------------------------------------------------------------
create type T2.outcome as enum ( 'eq', 'error' );

-- ---------------------------------------------------------------------------------------------------------
create table T2.probes_and_matchers (
  function_name text not null,
  p1_txt        text,
  p1_cast       text not null,
  p2_txt        text,
  p2_cast       text not null,
  expect        T2.outcome,
  match_txt     text,
  match_type    text );

-- ---------------------------------------------------------------------------------------------------------
create unique index on T2.probes_and_matchers
 ( function_name, p1_txt, p1_cast, p2_txt, p2_cast, expect, match_txt, match_type );

-- ---------------------------------------------------------------------------------------------------------
/* thx to https://stackoverflow.com/a/10711349/7568091 for using `regclass` and `format( '...%s...' )` */
create function T2.test_functions( ¶pm_table_name text )
  returns table (
    function_name_q   text,
    p1_txt_q          text,
    p1_cast_q         text,
    p2_txt_q          text,
    p2_cast_q         text,
    expect_q          text,
    result_txt_q      text,
    result_type_q     text,
    ok                boolean )
  volatile language plpgsql as $outer$
  declare
    ¶x              record;
    ¶result         record;
    ¶Q1             text;
    ¶Q2             text;
    ¶message        text;
    ¶nr             integer := 0;
    ¶match_txt_q    text;
    ¶match_type_q   text;
  -- .......................................................................................................
  begin
    ¶Q1 := format( $$ select * from %s $$, ¶pm_table_name );
    -- .....................................................................................................
    for ¶x in execute ¶Q1 loop begin
      ¶nr               :=  ¶nr + 1;
      function_name_q   :=  quote_literal( ¶x.function_name );
      p1_txt_q          :=  quote_nullable( ¶x.p1_txt );
      p1_cast_q         :=  quote_nullable( ¶x.p1_cast );
      p2_txt_q          :=  quote_nullable( ¶x.p2_txt );
      p2_cast_q         :=  quote_nullable( ¶x.p2_cast );
      expect_q          :=  quote_nullable( ¶x.expect );
      result_txt_q      :=  null;
      result_type_q     :=  null;
      ok                :=  false;
      ¶message          :=  null;
      -- ...................................................................................................
      ¶Q2 :=  format( $$ with v1 as (
        select
            %s( $1::%s, $2::%s ) as value )
        select
            v1.value::text                  as value_txt,
            ( pg_typeof( v1.value ) )::text as type_txt
          from v1; $$,
        ¶x.function_name,
        ¶x.p1_cast,
        ¶x.p2_cast );
      -- ...................................................................................................
      execute ¶Q2 using ¶x.p1_txt, ¶x.p2_txt into ¶result;
      result_txt_q  :=  quote_nullable( ¶result.value_txt   );
      result_type_q :=  quote_nullable( ¶result.type_txt    );
      -- ...................................................................................................
      ok        :=  true
        and ( ¶result.value_txt is not distinct from ¶x.match_txt   )
        and ( ¶result.type_txt  is not distinct from ¶x.match_type  );
      -- ...................................................................................................
      if not ok then
        ¶match_txt_q  :=  quote_nullable( ¶x.match_txt  );
        ¶match_type_q :=  quote_nullable( ¶x.match_type );
        perform log( '10091 expected  ', function_name_q, p1_txt_q, p1_cast_q, ¶match_txt_q, ¶match_type_q );
        perform log( '10091 actual    ', function_name_q, p1_txt_q, p1_cast_q, result_txt_q, result_type_q );
        end if;
      -- ...................................................................................................
      return next;
      -- ...................................................................................................
      exception when others then
        raise notice '(sqlstate) sqlerrm: (%) %', sqlstate, sqlerrm;
        ¶message      := format( '(%s) %s', sqlstate, sqlerrm );
        result_txt_q  := quote_nullable( ¶message );
        ok            := ¶x.expect = 'error' and ¶x.match_txt = ¶message;
        return next;
      end; end loop;
    -- .....................................................................................................
    end; $outer$;





