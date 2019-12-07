(function() {
  'use strict';
  var $, $async, $drain, $show, $watch, CND, DATOM, DB, SP, alert, badge, cast, debug, echo, help, info, isa, jr, log, new_datom, rpr, select, sleep, type_of, types, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'FLOWMATIC/INTERACTION';

  log = CND.get_logger('plain', badge);

  debug = CND.get_logger('debug', badge);

  info = CND.get_logger('info', badge);

  warn = CND.get_logger('warn', badge);

  alert = CND.get_logger('alert', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  // FS                        = require 'fs'
  // FSP                       = ( require 'fs' ).promises
  // PATH                      = require 'path'
  //...........................................................................................................
  SP = require('steampipes');

  ({$, $async, $watch, $show, $drain} = SP.export());

  DATOM = require('datom');

  ({new_datom, select} = DATOM.export());

  sleep = function(dts) {
    return new Promise((done) => {
      return setTimeout(done, dts * 1000);
    });
  };

  ({jr} = CND);

  DB = require('../../intershop/intershop_modules/db');

  //...........................................................................................................
  types = require('../types');

  ({isa, validate, cast, type_of} = types);

  //...........................................................................................................
  require('cnd/lib/exception-handler');

  // #-----------------------------------------------------------------------------------------------------------
  // demo_2 = -> new Promise ( resolve ) =>
  //   fifo      = FIFO.new_fifo()
  //   pipeline  = []
  //   pipeline.push FIFO.new_message_source fifo
  //   pipeline.push $watch ( d ) => info '^333^', d
  //   pipeline.push $drain =>
  //     resolve()
  //   SP.pull pipeline...
  //   return null

  //###########################################################################################################
  if (require.main === module) {
    (async() => {
      var emit, rpc_server, show;
      emit = async function($key, $value) {
        validate.undefined($value);
        await DB.query(["select FM.emit( $1 );", $key]);
        return null;
      };
      show = async function() {
        /* TAINT assemble value in DB */
        var R, i, len, ref, row;
        R = {};
        ref = (await DB.query("select * from FM.current_user_state order by topic;"));
        for (i = 0, len = ref.length; i < len; i++) {
          row = ref[i];
          R[row.topic] = row.focus;
        }
        return urge(jr(R));
      };
      rpc_server = require('../../intershop/intershop_modules/intershop-rpc-server-secondary');
      rpc_server.listen();
      process.on('uncaughtException', function() {
        return rpc_server.stop();
      });
      process.on('unhandledRejection', function() {
        return rpc_server.stop();
      });
      //.........................................................................................................
      rpc_server.contract('on_flowmatic_event', function(S, Q) {
        var event;
        validate.object(Q);
        ({event} = Q);
        debug('^33373^', rpr(event));
        if (event === '°s^one') {
          return ['°s^zero'];
        }
        return null;
      });
      //.........................................................................................................
      // info jr row for row in await DB.query """select * from FM.journal;"""
      await show();
      await emit('°s^zero');
      await show();
      await emit('°s^zero');
      await show();
      await emit('°s^one');
      await show();
      return process.exit(0);
    })();
  }

}).call(this);
