
/* ###################################################################################################### */
\ir './test-begin.sql'
\timing off
-- \set ECHO queries

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists X cascade;
\ir '../200-setup.sql'
\set filename demo-even-even-2.sql
\pset pager on


-- see https://youtu.be/Pt6GBVIifZA?t=1302
-- Finite State Machines
-- Shai Simonson
-- aduni.org/courses/theory/

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
do $$ begin
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_states( 's/zeros[:even,:odd]'  );
  perform FM.add_states( 's/ones[:even,:odd]'   );
  perform FM.add_states( 's/light[:off,:on]'    );
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_events( 's/zero()'       );
  perform FM.add_events( 's/one()'        );
  perform FM.add_events( 'bell/ring()'  );
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_transitions( 'match s/zeros[:even]               await s/zero() apply s/zeros[:odd]'                     );
  perform FM.add_transitions( 'match s/zeros[:odd]                await s/zero() apply s/zeros[:even] emit bell/ring()' );
  perform FM.add_transitions( 'match s/ones[:even]                await s/one()  apply s/ones[:odd]'                      );
  perform FM.add_transitions( 'match s/ones[:odd]                 await s/one()  apply s/ones[:even]  emit bell/ring()' );
  perform FM.add_transitions( 'match s/ones[:even], s/ones[:even] await entry()  emit bell/ring(), s/light[:on]' );
  perform FM.add_transitions( 'match s/ones[:even], s/ones[:even] await exit()   emit bell/ring(), s/light[:on]' );
  -- .......................................................................................................
  end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
do $$ begin
  -- -------------------------------------------------------------------------------------------------------
  -- state declaration that start with colon set type of state to enumeration of symbols; can be either
  -- single values or lists. First state added for a given component is initial (i.e. default) value:
  perform FM.add_states( 's/zeros=:even'      );
  perform FM.add_states( 's/zeros=:odd'       );
  perform FM.add_states( 's/ones=:even:odd'   );
  perform FM.add_states( 's/light=:off:on'    );
  -- state declarations that do not start with colon must be followed by single, valid JSON literal that
  -- denotes initial state. No type checking is done, not (yet?) possible to add any domain checks (such
  -- as for positive integers or the like):
  perform FM.add_states( 's/nr=0' );
  perform FM.add_states( 's/foo=true' );
  perform FM.add_states( 's/bar=null' );
  perform FM.add_states( 's/bar="sometext"' );
  perform FM.add_states( 's/bar=[8,7,6]' );
  perform FM.add_states( 's/bar={"foo":42}' );
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_events( 's/zero()'       );
  perform FM.add_events( 's/one()'        );
  perform FM.add_events( 's/nr/plus()'    );
  perform FM.add_events( 'bell/ring()'    );
  -- -------------------------------------------------------------------------------------------------------
  -- Transition phrases use keywords `match`, `await`, `apply`, `emit`, `call` to introduce premises, triggers,
  -- effects, moves, and actions, respectively.
  perform FM.add_transitions( 'match s/zeros=:even               await s/zero() apply s/zeros=:odd'                     );
  perform FM.add_transitions( 'match s/zeros=:odd                await s/zero() apply s/zeros=:even emit bell/ring()' );
  perform FM.add_transitions( 'match s/ones=:even                await s/one()  apply s/ones=:odd'                      );
  perform FM.add_transitions( 'match s/ones=:odd                 await s/one()  apply s/ones=:even  emit bell/ring()' );
  perform FM.add_transitions( 'match s/ones=:even s/zeros:even   await entry()  emit bell/ring() s/light=:on' );
  perform FM.add_transitions( 'match s/ones=:even s/zeros:even   await exit()   emit bell/ring() s/light=:on' );
  perform FM.add_transitions( 'await exit() call bell/ring()' );
  -- .......................................................................................................
  end; $$;

do $$ begin perform FM.emit( '°FSM^RESET'     ); end; $$;
do $$ begin perform FM.emit( '°s^zero'        ); end; $$;
do $$ begin perform FM.emit( '°s^one'         ); end; $$;
do $$ begin perform FM.emit( '°s^zero'        ); end; $$;
do $$ begin perform FM.emit( '°s^one'         ); end; $$;
do $$ begin perform FM.emit( '°s^one'         ); end; $$;
do $$ begin perform FM.emit( '°s^one'         ); end; $$;
-- do $$ begin perform FM.emit( '°switch^toggle' ); end; $$;
-- do $$ begin perform FM.emit( '°FSM^HELO' );      end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 9 }———:reset
-- -- .........................................................................................................
-- \echo :reverse:steel  FM.atoms :reset
-- select * from         FM.atoms;
-- -- .........................................................................................................
-- \echo :reverse:steel  FM.queue :reset
-- select * from         FM.queue;
-- -- .........................................................................................................
-- \echo :reverse:steel  FM.journal :reset
-- select * from         FM.journal order by jid;
-- -- .........................................................................................................
-- \echo :reverse:steel  FM.current_user_state :reset
-- select * from         FM.current_user_state;
-- .........................................................................................................
\echo :reverse:steel  FM.transitions :reset
select * from FM.transitions;

-- select
--     trans.jid     as jid,
--     trans.t       as t,
--     trans.kind    as kind,
--     trans.topic   as topic,
--     trans.focus   as focus,
--     trans.pair    as pair,
--     trans.status  as status
--   from FM.journal as trans
--   order by jid
--   ;

select U.split_initial_json_trimmed( ' "an initial value" followed by other stuff'  );




/* ###################################################################################################### */
\echo :red ———{ :filename 10 }———:reset
\quit



/* ====================================================================================================== */
\ir './test-perform.sql'

\pset pager on
-- select distinct xcode from FACTORS.factors order by xcode;
-- select glyph, wbf5        from FACTORS.factors            where glyph in ( '際', '祙', '祭', '⽰', '未' );
-- select * from FACTORS._010_factors;

/* ====================================================================================================== */
\ir './test-end.sql'
\quit
