(function() {
  'use strict';
  var $, $async, $drain, $show, $watch, CND, DATOM, DB, SP, alert, badge, debug, demo_2, echo, help, info, jr, log, new_datom, rpr, select, sleep, urge, warn, whisper;

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
  require('cnd/lib/exception-handler');

  //-----------------------------------------------------------------------------------------------------------
  demo_2 = function() {
    return new Promise((resolve) => {
      var fifo, pipeline;
      fifo = FIFO.new_fifo();
      pipeline = [];
      pipeline.push(FIFO.new_message_source(fifo));
      pipeline.push($watch((d) => {
        return info('^333^', d);
      }));
      pipeline.push($drain(() => {
        return resolve();
      }));
      SP.pull(...pipeline);
      return null;
    });
  };

  //###########################################################################################################
  if (require.main === module) {
    (async() => {
      var i, j, k, len, len1, len2, ref, ref1, ref2, row;
      ref = (await DB.query("select * from FM.current_user_state;"));
      for (i = 0, len = ref.length; i < len; i++) {
        row = ref[i];
        //   # await demo_1()
        //   await demo_2()
        //   help 'ok'

        // PG                        = require 'pg'

        // process.on 'uncaughtException',  -> warn "^8876^ uncaughtException";  setTimeout ( -> process.exit 1 ), 250
        // process.on 'unhandledRejection', -> warn "^8876^ unhandledRejection"; setTimeout ( -> process.exit 1 ), 250

        // rpc_server = require '../../intershop/intershop_modules/intershop-rpc-server-secondary'
        // rpc_server.listen()
        info(jr(row.pair));
      }
      ref1 = (await DB.query("select * from FM.emit( '°s^zero' );"));
      for (j = 0, len1 = ref1.length; j < len1; j++) {
        row = ref1[j];
        info(jr(row));
      }
      ref2 = (await DB.query("select * from FM.current_user_state;"));
      for (k = 0, len2 = ref2.length; k < len2; k++) {
        row = ref2[k];
        info(jr(row.pair));
      }
      return process.exit(0);
    })();
  }

}).call(this);
