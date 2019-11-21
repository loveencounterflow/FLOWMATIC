
\timing off


-- ---------------------------------------------------------------------------------------------------------
create materialized view T.test_functions_results as (
  select * from T.test_functions( 'T.probes_and_matchers' ) );
select
    function_name_q                     as fn,
    p1_txt_q                            as p1,
    p1_cast_q                           as p1cast,
    expect_q                            as x,
    result_txt_q                        as res,
    result_type_q                       as restype,
    case when ok then '' else 'X' end   as "?"
  from T.test_functions_results;

-- ---------------------------------------------------------------------------------------------------------
create materialized view T.all_result_counts as (
  select null::text as category, null::integer as count where false union all
  -- .........................................................................................................
  select 'total',   count(*) from T.test_functions_results                union all
  select 'passed',  count(*) from T.test_functions_results where      ok  union all
  select 'failed',  count(*) from T.test_functions_results where  not ok  union all
  -- .........................................................................................................
  select null, null where false );



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
create materialized view T2.test_functions_results as (
  select * from T2.test_functions( 'T2.probes_and_matchers' ) );
select
    function_name_q                     as fn,
    p1_txt_q                            as p1,
    p1_cast_q                           as p1cast,
    p2_txt_q                            as p2,
    p2_cast_q                           as p2cast,
    expect_q                            as x,
    result_txt_q                        as res,
    result_type_q                       as restype,
    case when ok then '' else 'X' end   as "?"
  from T2.test_functions_results;

-- ---------------------------------------------------------------------------------------------------------
create materialized view T2.all_result_counts as (
  select null::text as category, null::integer as count where false union all
  -- .........................................................................................................
  select 'total',   count(*) from T2.test_functions_results                union all
  select 'passed',  count(*) from T2.test_functions_results where      ok  union all
  select 'failed',  count(*) from T2.test_functions_results where  not ok  union all
  -- .........................................................................................................
  select null, null where false );

-- ---------------------------------------------------------------------------------------------------------
\set ECHO queries
select * from T.all_result_counts;
select * from T2.all_result_counts;
\set ECHO none

-- ---------------------------------------------------------------------------------------------------------
do $$
  declare
    ¶count  integer := 0;
  begin
    ¶count  :=            count from T.all_result_counts  where category = 'failed';
    ¶count  :=  ¶count +  count from T2.all_result_counts where category = 'failed';
    if ¶count != 0 then
      raise exception 'tests failed';
      end if;
    end; $$;


