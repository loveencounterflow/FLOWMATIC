
/* ###################################################################################################### */
-- \ir './test-begin.sql'
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
  -- perform FM.add_atom( '°s',              'component',  'default component'                               );
  -- perform FM.add_atom( '°bell',           'component',  'attention grabber'                               );
  -- perform FM.add_atom( '^zero',           'verb',       'digit 0 coming up'                               );
  -- perform FM.add_atom( '^one',            'verb',       'digit 1 coming up'                               );
  -- perform FM.add_atom( '^ring',           'verb',       'make noise'                                      );
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_pair( '°zeros',          ':even', 'state',  true,    'even # of 0s'  );
  perform FM.add_pair( '°zeros',          ':odd',  'state',  false,   'odd # of 0s'  );
  perform FM.add_pair( '°ones',           ':even', 'state',  true,    'even # of 1s'  );
  perform FM.add_pair( '°ones',           ':odd',  'state',  false,   'odd # of 1s'  );
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_pair( '°s',              '^zero',      'event',  false,  'next digit is a 0'             );
  perform FM.add_pair( '°s',              '^one',       'event',  false,  'next digit is a 1'             );
  perform FM.add_pair( '°bell',           '^ring',      'event',  false,  'grab attention'                );
  perform FM.add_pair( '°light',          '^flash',     'event',  false,  'grab attention'                );
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_transition( '°FSM:IDLE', '°FSM^RESET', null, '°bell^ring'                                );
  -- .......................................................................................................
  perform FM.add_transition( '°zeros:even',  '°s^zero',    '°zeros:odd'                             );
  perform FM.add_transition( '°zeros:odd',   '°s^zero',    '°zeros:even', '°bell^ring'              );
  -- perform FM.add_transition( null,           '°bell^ring', null,          '°light^flash',            );
  perform FM.add_transition( '°ones:even',   '°s^one',     '°ones:odd'                              );
  perform FM.add_transition( '°ones:odd',    '°s^one',     '°ones:even'                             );
  -- .......................................................................................................
  end; $$;

do $$ begin perform FM.emit( '°FSM^RESET'     ); end; $$;
do $$ begin perform FM.emit( '°s^zero'        ); end; $$;
do $$ begin perform FM.emit( '°s^one'         ); end; $$;
-- do $$ begin perform FM.emit( '°s^zero'        ); end; $$;
do $$ begin perform FM.emit( '°s^one'         ); end; $$;
do $$ begin perform FM.emit( '°s^one'         ); end; $$;
-- do $$ begin perform FM.emit( '°s^one'         ); end; $$;
-- do $$ begin perform FM.emit( '°switch^toggle' ); end; $$;
-- do $$ begin perform FM.emit( '°FSM^HELO' );      end; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 9 }———:reset
-- .........................................................................................................
\echo :reverse:steel  FM.transition_phrases :reset
select * from         FM.transition_phrases;

-- -- .........................................................................................................
-- \echo :reverse:steel  FM.atoms :reset
-- select * from         FM.atoms;
-- -- .........................................................................................................
-- \echo :reverse:steel  FM.queue :reset
-- select * from         FM.queue;
-- -- .........................................................................................................
-- \echo :reverse:steel  FM.journal :reset
-- select * from         FM.journal order by jid;
-- .........................................................................................................
\echo :reverse:steel  FM.transitions :reset
select * from FM.transitions;
-- .........................................................................................................
\echo :reverse:steel  FM.current_user_state :reset
select * from         FM.current_user_state;


do $$ begin perform FM.emit( '°FSM^RESET'     ); end; $$;
-- do $$ begin perform FM.emit( '°s^zero'        ); end; $$;

-- .........................................................................................................
\echo :reverse:steel  FM.transitions :reset
select * from FM.transitions;
-- .........................................................................................................
\echo :reverse:steel  FM.current_user_state :reset
select * from         FM.current_user_state;



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
