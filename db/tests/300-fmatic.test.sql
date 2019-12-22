
/* ###################################################################################################### */
\ir './test-begin.sql'
\timing off
-- \set ECHO queries



-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists X cascade;
create schema X;
\ir '../300-fmatic.sql'
\set filename 300-fmatic.test.sql
\pset pager on

-- ---------------------------------------------------------------------------------------------------------
create function X.test_absolute_path( ¶x text ) returns boolean
  immutable parallel safe language plpgsql as $$
  begin
    return ( ¶x::FMAT.absolute_path )::text = ¶x;
    exception
        when check_violation then
          return false;
        when others then
          raise notice 'error while testing %: (%) %', ¶x, sqlstate, sqlerrm;
          -- raise exception 'error while retrieving %.%: (%) %', schema, name, sqlstate, sqlerrm;
          return null;
  end; $$;

-- ---------------------------------------------------------------------------------------------------------
insert into T.probes_and_matchers
  ( function_name, p1_txt, p1_cast, expect, match_txt, match_type ) values
  ( 'X.test_absolute_path', '/',              'text', 'eq', 'true',  'boolean' ),
  ( 'X.test_absolute_path', '/x/foo/bar',     'text', 'eq', 'true',  'boolean' ),
  ( 'X.test_absolute_path', '/x/foo//bar',    'text', 'eq', 'false', 'boolean' ),
  ( 'X.test_absolute_path', '/x/foo/bar/',    'text', 'eq', 'false', 'boolean' ),
  ( 'X.test_absolute_path', '北',             'text', 'eq', 'false', 'boolean' ),
  ( 'X.test_absolute_path', '/北',            'text', 'eq', 'true',  'boolean' );

/* ====================================================================================================== */
\ir './test-perform.sql'


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
do $$ begin
  -- -------------------------------------------------------------------------------------------------------
  end; $$;
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 5 }———:reset
insert into FMAT.rules ( rulid, comment ) values ( 1, 'XXX' );
insert into FMAT.rules ( rulid, comment ) values ( 2, 'XXX' );
insert into FMAT.rules ( rulid, comment ) values ( 3, 'XXX' );
insert into FMAT.rules ( rulid, comment ) values ( 4, 'XXX' );
insert into FMAT.rules ( rulid, comment ) values ( 5, 'XXX' );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
insert into FMAT.parts ( rulid, role, path ) values
  ( null, 'state',    '/apps/blink/light/:off'                          ),
  ( null, 'state',    '/apps/blink/light/:on'                           ),
  ( null, 'action',   '/apps/blink/light/toggle()'                      ),
  ( null, 'state',    '/apps/blink/plug/:unplugged'                     ),
  ( null, 'state',    '/apps/blink/plug/:inserted'                      ),
  ( null, 'action',   '/apps/blink/timer/tick()'                        ),
  ( 1,    'premise',  '/apps/blink/light/:on'                           ),
  ( 1,    'trigger',  '/apps/blink/light/toggle()'                      ),
  ( 1,    'effect',   '/apps/blink/light/:off'                          ),
  ( 2,    'premise',  '/apps/blink/plug/:inserted'                      ),
  ( 2,    'premise',  '/apps/blink/light/:off'                          ),
  ( 2,    'trigger',  '/apps/blink/light/toggle()'                      ),
  ( 2,    'effect',   '/apps/blink/light/:on'                           ),
  ( 3,    'trigger',  '/apps/blink/timer/tick()'                        ),
  ( 3,    'move',     '/apps/blink/light/toggle()'                      ),
  ( 4,    'premise',  '/apps/blink/plug/:unplugged'                     ),
  ( 4,    'trigger',  '/~enter()'                                       ),
  ( 4,    'effect',   '/apps/blink/light/:off'                          ),
  ( 5,    'premise',  '/apps/blink/plug/:unplugged'                     ),
  ( 5,    'trigger',  '/~enter()'                                       ),
  ( 5,    'premise',  '/apps/blink/light/:on'                           ),
  ( 5,    'move',     '/apps/blink/light/~error("impossible state")'    );

select p.partid, p.rulid, r.rolegroup, r.priority, p.role, p.path from FMAT.parts p join FMAT.roles as r using ( role ) order by r.priority,     p.path,   p.rulid;
select p.partid, p.rulid, r.rolegroup, r.priority, p.role, p.path from FMAT.parts p join FMAT.roles as r using ( role ) order by p.path,     r.priority,   p.rulid;

-- .........................................................................................................
\echo :reverse:steel  queueing :reset
-- select * from         FM.transition_phrases;
do $$ begin perform FMAT.push_to_queue( '/apps/blink/timer/tick()' ); end; $$;
do $$ begin perform FMAT.push_to_queue( '/apps/blink/light/toggle()' ); end; $$;
select * from FMAT.queue order by qid;
select FMAT.advance_next();
do $$ begin perform FMAT.push_to_queue( '/apps/blink/timer/tick()' ); end; $$;
select FMAT.advance_next();
select * from FMAT.queue order by qid;
select * from FMAT.journal order by jid;


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
