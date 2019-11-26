
/* ###################################################################################################### */
\ir './test-begin.sql'
\timing off
-- \set ECHO queries

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists X cascade;
\ir '../200-setup.sql'
\set filename xxx-transactions-and-procedures.sql
\pset pager on

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
do $$ begin
  -- -------------------------------------------------------------------------------------------------------
  end; $$;



/* ====================================================================================================== */
\ir './test-perform.sql'

\pset pager on
-- select distinct xcode from FACTORS.factors order by xcode;
-- select glyph, wbf5        from FACTORS.factors            where glyph in ( '際', '祙', '祭', '⽰', '未' );
-- select * from FACTORS._010_factors;

/* ====================================================================================================== */
\ir './test-end.sql'
\quit



-- ---------------------------------------------------------------------------------------------------------
create function FM_FSM.reset() returns void volatile language plpgsql as $$
  -- Reset all values to their defaults
  begin
    perform log( '^FM_FSM.reset^' );
    insert into FM.journal  ( topic, focus, kind, remark )
      select                  topic, focus, kind, 'RESET'
      from FM.pairs
      where dflt; -- `kind = 'state'` is implicit for `dflt = true`
    -- ### TAINT consider to actually use entries in `transition_phrases`:
    insert into FM.journal  ( topic,  focus,      kind,     remark  ) values
                            ( '°FSM', ':ACTIVE',  'state',  'RESET' );
    end; $$;

