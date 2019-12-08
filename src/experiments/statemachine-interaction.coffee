

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'FLOWMATIC/INTERACTION'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
info                      = CND.get_logger 'info',      badge
warn                      = CND.get_logger 'warn',      badge
alert                     = CND.get_logger 'alert',     badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
# FS                        = require 'fs'
# FSP                       = ( require 'fs' ).promises
PATH                      = require 'path'
#...........................................................................................................
SP                        = require 'steampipes'
{ $
  $async
  $watch
  $show
  $drain }                = SP.export()
DATOM                     = require 'datom'
{ new_datom
  freeze
  select }                = DATOM.export()
sleep                     = ( dts ) -> new Promise ( done ) => setTimeout done, dts * 1000
{ jr }                    = CND
DB                        = require '../../intershop/intershop_modules/db'
#...........................................................................................................
types                     = require '../types'
{ isa
  validate
  cast
  type_of }               = types
#...........................................................................................................
require 'cnd/lib/exception-handler'


# #-----------------------------------------------------------------------------------------------------------
# demo_2 = -> new Promise ( resolve ) =>
#   fifo      = FIFO.new_fifo()
#   pipeline  = []
#   pipeline.push FIFO.new_message_source fifo
#   pipeline.push $watch ( d ) => info '^333^', d
#   pipeline.push $drain =>
#     resolve()
#   SP.pull pipeline...
#   return null

#-----------------------------------------------------------------------------------------------------------
emit = ( $key, $value ) ->
  validate.undefined $value
  await DB.query [ "select FM.emit( $1 );", $key, ]
  return null

#-----------------------------------------------------------------------------------------------------------
show = ->
  ### TAINT assemble value in DB ###
  R = {}
  for row in await DB.query "select * from FM.current_user_state order by topic;"
    R[ row.topic ] = row.focus
  urge jr R

#-----------------------------------------------------------------------------------------------------------
start_rpc_server = -> new Promise ( resolve, reject ) =>
  rpc_server = require '../../intershop/intershop_modules/intershop-rpc-server-secondary'
  rpc_server.listen ( error, P ) => if error? then reject error else resolve rpc_server

#-----------------------------------------------------------------------------------------------------------
demo = ->
  rpc_server = await start_rpc_server()
  process.on 'uncaughtException',  -> rpc_server.stop()
  process.on 'unhandledRejection', -> rpc_server.stop()
  #.........................................................................................................
  rpc_server.contract 'on_flowmatic_event', ( S, Q ) ->
    validate.object Q
    { event, } = Q
    debug '^33373^', rpr event
    return [ '°s^zero', ] if event is '°s^one'
    return null
  #.........................................................................................................
  # info jr row for row in await DB.query """select * from FM.journal;"""
  await show()
  await emit '°s^zero'
  await show()
  await emit '°s^zero'
  await show()
  await emit '°s^one'
  await show()
  process.exit 0

#-----------------------------------------------------------------------------------------------------------
read_configuration = ->
  PTVR                      = require '../../intershop/intershop_modules/ptv-reader'
  guest_intershop_ptv_path  = PATH.resolve PATH.join __dirname, '../../intershop/intershop.ptv'
  host_intershop_ptv_path   = PATH.resolve PATH.join __dirname, '../../intershop.ptv'
  return freeze PTVR.hash_from_paths guest_intershop_ptv_path, host_intershop_ptv_path

#-----------------------------------------------------------------------------------------------------------
start_rpc_server_with_default_handler = ->
  # help PgBoss.getConstructionPlans()
  rpc_server = await start_rpc_server()
  process.on 'uncaughtException',  -> rpc_server.stop()
  process.on 'unhandledRejection', -> rpc_server.stop()
  #.........................................................................................................
  rpc_server.contract 'on_flowmatic_event', ( S, Q ) ->
    validate.object Q
    { event, } = Q
    return 'gotcha'
  return rpc_server


############################################################################################################
if require.main is module then do =>


  rpc_server = await start_rpc_server_with_default_handler()
  process.exit 1



