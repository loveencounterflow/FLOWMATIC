

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
# PATH                      = require 'path'
#...........................................................................................................
SP                        = require 'steampipes'
{ $
  $async
  $watch
  $show
  $drain }                = SP.export()
DATOM                     = require 'datom'
{ new_datom
  select }                = DATOM.export()
sleep                     = ( dts ) -> new Promise ( done ) => setTimeout done, dts * 1000
{ jr }                    = CND
DB                        = require '../../intershop/intershop_modules/db'
#...........................................................................................................
require 'cnd/lib/exception-handler'


#-----------------------------------------------------------------------------------------------------------
demo_2 = -> new Promise ( resolve ) =>
  fifo      = FIFO.new_fifo()
  pipeline  = []
  pipeline.push FIFO.new_message_source fifo
  pipeline.push $watch ( d ) => info '^333^', d
  pipeline.push $drain =>
    resolve()
  SP.pull pipeline...
  return null

############################################################################################################
if require.main is module then do =>
#   # await demo_1()
#   await demo_2()
#   help 'ok'

  # PG                        = require 'pg'

  # process.on 'uncaughtException',  -> warn "^8876^ uncaughtException";  setTimeout ( -> process.exit 1 ), 250
  # process.on 'unhandledRejection', -> warn "^8876^ unhandledRejection"; setTimeout ( -> process.exit 1 ), 250

  # rpc_server = require '../../intershop/intershop_modules/intershop-rpc-server-secondary'
  # rpc_server.listen()

  info jr row.pair for row in await DB.query """select * from FM.current_user_state;"""
  info jr row for row in await DB.query """select * from FM.emit( '°s^zero' );"""
  info jr row.pair for row in await DB.query """select * from FM.current_user_state;"""
  process.exit 0




