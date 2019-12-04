(function() {
  'use strict';
  var $, $async, $drain, $show, $watch, CND, DATOM, FIFO, FS, FSP, PATH, SP, Tail, alert, badge, debug, demo_2, echo, help, info, is_executable, jr, log, mkfifoSync, new_datom, provide_fifo, rpr, select, sleep, urge, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'FLOWMATIC/NAMED-PIPE';

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
  FS = require('fs');

  FSP = (require('fs')).promises;

  PATH = require('path');

  is_executable = require('executable');

  ({mkfifoSync} = require('named-pipe'));

  Tail = (require('tail')).Tail;

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

  //...........................................................................................................
  require('cnd/lib/exception-handler');

  provide_fifo = function() {
    //-----------------------------------------------------------------------------------------------------------
    this.new_fifo = function() {
      var R, error, fifo_relpath;
      R = PATH.resolve(PATH.join(__dirname, '../../myfifo'));
      fifo_relpath = PATH.relative(process.cwd(), R);
      try {
        // ### TAINT test whether file exists, do not overwrite (?) ###
        // FS.writeFileSync R, ''
        mkfifoSync(R);
      } catch (error1) {
        error = error1;
        if (!((error.message === 'unable to create the pipe. do you have permissions?') && (FS.statSync(R)).isFIFO())) {
          throw error;
        }
      }
      if (error != null) {
        info(`^fifo@5541^ using existing FIFO pipe at ${fifo_relpath}`);
      } else {
        info(`^fifo@5542^ created FIFO pipe at ${fifo_relpath}`);
      }
      return R;
    };
    //-----------------------------------------------------------------------------------------------------------
    this.send = async function(me, d) {
      // FS.appendFileSync me, 'helo'
      await FSP.appendFile(me, (JSON.stringify(d)) + '\n');
      return null;
    };
    //-----------------------------------------------------------------------------------------------------------
    this.new_tail = function(me, handler) {
      var tail;
      // validate.function handler
      tail = new Tail(me, {
        fromBeginning: true
      });
      tail.on('line', (line) => {
        var error;
        try {
          return handler(null, JSON.parse(line));
        } catch (error1) {
          error = error1;
          throw new Error(`when trying to parse ${rpr(line)}, an error was thrown with ${rpr(error.message)}`);
        }
      });
      tail.on('error', (error) => {
        return handler(error);
      });
      return tail;
    };
    // #-----------------------------------------------------------------------------------------------------------
    // @new_message_source = ( me ) ->
    //   tail    = @new_tail me, ( error, d ) =>
    //     throw error if error?
    //     return R.end() if select d, '~stop'
    //     send d
    //   R       = SP.new_push_source()
    //   end     = R.end.bind   R
    //   send    = R.send.bind  R
    //   R.send  = ( d ) => return R.end() if select d, '~stop'; send d
    //   R.end   = => tail.unwatch(); end()
    //   R.tail  = tail
    //   return R

    //-----------------------------------------------------------------------------------------------------------
    return this.new_message_source = function(me) {
      var NET, R, flags, send;
      // stream  = FS.createReadStream me
      // stream.setEncoding('utf8')
      // stream.on 'data', ( d ) => debug '^776^', rpr d; send d
      NET = require('net');
      flags = FS.constants.O_RDONLY | FS.constants.O_NONBLOCK;
      FS.open(me, flags, (error, fd) => {
        var stream;
        if (error != null) {
          throw error;
        }
        stream = new NET.Socket({fd});
        stream.setEncoding('utf-8');
        // Now `stream` is a stream that can be used for reading from the FIFO.
        // stream.on 'data', ( d ) => debug '^776^', rpr d; send d
        stream.pipe(process.stdout);
        stream.on('end', () => {
          debug('^777^');
          return R.end();
        });
        return stream.on('error', () => {
          throw error;
        });
      });
      R = SP.new_push_source();
      // end     = R.end.bind   R
      send = R.send.bind(R);
      R.send = (d) => {
        if (select(d, '~stop')) {
          return R.end();
        }
        return send(d);
      };
      // R.end   = => tail.unwatch(); end()
      // R.tail  = tail
      return R;
    };
  };

  provide_fifo.apply(FIFO = {});

  //-----------------------------------------------------------------------------------------------------------
  demo_2 = function() {
    return new Promise(async(resolve) => {
      var d, fifo, i, nr, pipeline;
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
//.........................................................................................................
      for (nr = i = 1; i <= 10; nr = ++i) {
        d = new_datom('^foo', {
          time: Date.now(),
          value: `msg#${nr}`
        });
        whisper('^22231^', jr(d));
        FIFO.send(fifo, d);
        await sleep(0.1);
      }
      whisper('^22231^', jr(d = new_datom('~stop')));
      FIFO.send(fifo, d);
      debug(rpr((await FSP.readFile(fifo, 'utf-8'))));
      //.........................................................................................................
      info('ok');
      return null;
    });
  };

  //###########################################################################################################
  if (require.main === module) {
    (async() => {
      // await demo_1()
      await demo_2();
      return help('ok');
    })();
  }

}).call(this);
