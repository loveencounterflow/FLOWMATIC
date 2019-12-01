

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'FLOWMATIC/NAMED-PIPE'
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
FS                        = require 'fs'
FSP                       = ( require 'fs' ).promises
PATH                      = require 'path'
is_executable             = require 'executable'
{ mkfifoSync, }           = require 'named-pipe'
Tail                      = ( require 'tail' ).Tail
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
#...........................................................................................................
require 'cnd/lib/exception-handler'

provide_fifo = ->

  #-----------------------------------------------------------------------------------------------------------
  @new_fifo = ->
    R             = PATH.resolve PATH.join __dirname, '../../myfifo'
    fifo_relpath  = PATH.relative process.cwd(), R
    ### TAINT test whether file exists, do not overwrite (?) ###
    FS.writeFileSync R, ''
    # try mkfifoSync R catch error
    #   throw error unless ( error.message is 'unable to create the pipe. do you have permissions?' ) \
    #     and ( FS.statSync R ).isFIFO()
    # if error? then  info "^fifo@5541^ using existing FIFO pipe at #{fifo_relpath}"
    # else            info "^fifo@5542^ created FIFO pipe at #{fifo_relpath}"
    return R

  #-----------------------------------------------------------------------------------------------------------
  @send = ( me, d ) ->
    # FS.appendFileSync me, 'helo'
    await FSP.appendFile me, ( JSON.stringify d ) + '\n'
    return null

  #-----------------------------------------------------------------------------------------------------------
  @new_tail = ( me, handler ) ->
    # validate.function handler
    tail = new Tail me, { fromBeginning: true, }
    tail.on 'line',   ( line  ) =>
      try handler null, JSON.parse line catch error
        throw new Error "when trying to parse #{rpr line}, an error was thrown with #{rpr error.message}"
    tail.on 'error',  ( error ) => handler error
    return tail

  #-----------------------------------------------------------------------------------------------------------
  @new_message_source = ( me ) ->
    tail    = @new_tail me, ( error, d ) =>
      throw error if error?
      return R.end() if select d, '~stop'
      send d
    R       = SP.new_push_source()
    end     = R.end.bind   R
    send    = R.send.bind  R
    R.send  = ( d ) => return R.end() if select d, '~stop'; send d
    R.end   = => tail.unwatch(); end()
    R.tail  = tail
    return R
provide_fifo.apply FIFO = {}


#-----------------------------------------------------------------------------------------------------------
demo_2 = -> new Promise ( resolve ) =>
  fifo      = FIFO.new_fifo()
  pipeline  = []
  pipeline.push FIFO.new_message_source fifo
  pipeline.push $watch ( d ) => info '^333^', d
  pipeline.push $drain =>
    resolve()
  SP.pull pipeline...
  #.........................................................................................................
  for nr in [ 1 .. 10 ]
    d = new_datom '^foo', { time: Date.now(), value: "msg##{nr}", }
    whisper '^22231^', jr d
    FIFO.send fifo, d
    await sleep 0.1
  FIFO.send fifo, new_datom '~stop'
  # source.end()
  #.........................................................................................................
  info 'ok'
  return null

############################################################################################################
if require.main is module then do =>
  # await demo_1()
  await demo_2()
  help 'ok'

