
/* ###################################################################################################### */
\ir './test-begin.sql'
\timing off
-- \set ECHO queries

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists X cascade;
\ir '../200-setup.sql'
\set filename 200-setup.test.sql
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
  -- -- -------------------------------------------------------------------------------------------------------
  -- perform FM.add_atom( ':even0_even1',    'aspect',     'even # of 0s, even # of 1s'                      );
  -- perform FM.add_atom( ':even0_odd1',     'aspect',     'even # of 0s, odd # of 1s'                       );
  -- perform FM.add_atom( ':odd0_even1',     'aspect',     'odd # of 0s, even # of 1s'                       );
  -- perform FM.add_atom( ':odd0_odd1',      'aspect',     'odd # of 0s, odd # of 1s'                        );
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_pair( '°s',              ':even0_even1', 'state',  true,   'even # of 0s, even # of 1s'  );
  perform FM.add_pair( '°s',              ':even0_odd1',  'state',  false,  'even # of 0s, odd # of 1s'   );
  perform FM.add_pair( '°s',              ':odd0_even1',  'state',  false,  'odd # of 0s, even # of 1s'   );
  perform FM.add_pair( '°s',              ':odd0_odd1',   'state',  false,  'odd # of 0s, odd # of 1s'    );
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_pair( '°s',              '^zero',      'event',  false,  'next digit is a 0'             );
  perform FM.add_pair( '°s',              '^one',       'event',  false,  'next digit is a 1'             );
  perform FM.add_pair( '°bell',           '^ring',      'event',  false,  'grab attention'                );
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_transition( '°FSM:IDLE', '°FSM^RESET', null, '°bell^ring'                                );
  -- .......................................................................................................
  perform FM.add_transition( '°s:even0_even1',  '°s^zero',    '°s:odd0_even1'                             );
  perform FM.add_transition( '°s:even0_even1',  '°s^one',     '°s:even0_odd1'                             );
  -- .......................................................................................................
  perform FM.add_transition( '°s:odd0_even1',   '°s^zero',    '°s:even0_even1', '°bell^ring'              );
  perform FM.add_transition( '°s:odd0_even1',   '°s^one',     '°s:odd0_odd1'                              );
  -- .......................................................................................................
  perform FM.add_transition( '°s:even0_odd1',   '°s^zero',    '°s:odd0_odd1'                              );
  perform FM.add_transition( '°s:even0_odd1',   '°s^one',     '°s:even0_even1', '°bell^ring'              );
  -- .......................................................................................................
  perform FM.add_transition( '°s:odd0_odd1',    '°s^zero',    '°s:even0_odd1'                             );
  perform FM.add_transition( '°s:odd0_odd1',    '°s^one',     '°s:odd0_even1'                             );
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
-- .........................................................................................................
\echo :reverse:steel  FM.atoms :reset
select * from         FM.atoms;
-- .........................................................................................................
\echo :reverse:steel  FM.queue :reset
select * from         FM.queue;
-- .........................................................................................................
\echo :reverse:steel  FM.journal :reset
select * from         FM.journal order by jid;
-- .........................................................................................................
\echo :reverse:steel  FM.current_user_state :reset
select * from         FM.current_user_state;


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
