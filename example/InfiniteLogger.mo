// Persistent logger keeping track of what is going on.

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Logger "mo:ic-logger/Logger";

import BasicLogger "BasicLogger";

actor InfiniteLogger {

  type BasicLogger = BasicLogger.BasicLogger;
  let loggerBuf : Buffer.Buffer<BasicLogger> = Buffer.Buffer<BasicLogger>(0);

  // private func initLogger() : ?BasicLogger.BasicLogger {
  //     let loggerBuf = Buffer.Buffer<?BasicLogger>(0);
  //     let logger = BasicLogger.BasicLogger();
  //     loggerBuf.add(?logger);
  //     loggerBuf;
  // };

  // private func addLogger() {
  //   let logger = BasicLogger.BasicLogger();
  //   loggerBuf.add(logger);
  // };

  // private func getLoggerSize(logger : BasicLogger) : Nat {
  //   var size = 0;
  //   let stats = await logger.stats();
  //   for ( x in stats.bucket_sizes.vals() ) {
  //     size += x;
  //   };
  //   size;
  // };
  
  // Add a set of messages to the log.
  public func append(msgs: [Text]) : async () {
    if (loggerBuf.size() == 0) {
      // addLogger();
      let logger : BasicLogger = await BasicLogger.BasicLogger();
      loggerBuf.add(logger);
    };

    var size = 0;
    let stats = await loggerBuf.get(loggerBuf.size()-1).stats();
    for ( x in stats.bucket_sizes.vals() ) {
      size += x;
    };

    // let size = getLoggerSize(loggerBuf.get(loggerBuf.size()-1));

    if (size >= 100) {
      // addLogger();
      let logger = await BasicLogger.BasicLogger();
      loggerBuf.add(logger);
    };
    
    loggerBuf.get(loggerBuf.size()-1).append(msgs);
  };

  // Return log stats, where:
  //   start_index is the first index of log message.
  //   bucket_sizes is the size of all buckets, from oldest to newest.
  public func stats() : async Logger.Stats {
    let logger : BasicLogger = loggerBuf.get(loggerBuf.size()-1);
    let stats : Logger.Stats = await logger.stats();
    stats;
  };

  // Return the messages between from and to indice (inclusive).
  public func view(from: Nat, to: Nat) : async Logger.View<Text> {
    if (loggerBuf.size() == 0) {
      return {
        start_index = from;
        messages = [];
      }
    };
    await loggerBuf.get(loggerBuf.size()-1).view(from, to);
  };

}
