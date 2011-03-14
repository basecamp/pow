(function() {
  var LineBuffer, Stream, async, fs, path;
  var __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  fs = require("fs");
  path = require("path");
  async = require("async");
  Stream = require('stream').Stream;
  exports.mkdirp = function(dirname, callback) {
    var p;
    return fs.lstat((p = path.normalize(dirname)), function(err, stats) {
      var paths;
      if (err) {
        paths = [p].concat((function() {
          var _results;
          _results = [];
          while (p !== "/" && p !== ".") {
            _results.push(p = path.dirname(p));
          }
          return _results;
        })());
        return async.forEachSeries(paths.reverse(), function(p, next) {
          return path.exists(p, function(exists) {
            if (exists) {
              return next();
            } else {
              return fs.mkdir(p, 0755, function(err) {
                if (err) {
                  return callback(err);
                } else {
                  return next();
                }
              });
            }
          });
        }, callback);
      } else if (stats.isDirectory()) {
        return callback();
      } else {
        return callback("file exists");
      }
    });
  };
  exports.pause = function(stream) {
    var onClose, onData, onEnd, queue, removeListeners;
    queue = [];
    onData = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return queue.push(['data'].concat(__slice.call(args)));
    };
    onEnd = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return queue.push(['end'].concat(__slice.call(args)));
    };
    onClose = function() {
      return removeListeners();
    };
    removeListeners = function() {
      stream.removeListener('data', onData);
      stream.removeListener('end', onEnd);
      return stream.removeListener('close', onClose);
    };
    stream.on('data', onData);
    stream.on('end', onEnd);
    stream.on('close', onClose);
    return function() {
      var args, _i, _len, _results;
      removeListeners();
      _results = [];
      for (_i = 0, _len = queue.length; _i < _len; _i++) {
        args = queue[_i];
        _results.push(stream.emit.apply(stream, args));
      }
      return _results;
    };
  };
  exports.LineBuffer = LineBuffer = (function() {
    __extends(LineBuffer, Stream);
    function LineBuffer(stream) {
      var self;
      this.stream = stream;
      this.readable = true;
      this._buffer = "";
      self = this;
      this.stream.on('data', function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return self.write.apply(self, args);
      });
      this.stream.on('end', function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return self.end.apply(self, args);
      });
    }
    LineBuffer.prototype.write = function(chunk) {
      var index, line, _results;
      this._buffer += chunk;
      _results = [];
      while ((index = this._buffer.indexOf("\n")) !== -1) {
        line = this._buffer.slice(0, index);
        this._buffer = this._buffer.slice(index + 1, this._buffer.length);
        _results.push(this.emit('data', line));
      }
      return _results;
    };
    LineBuffer.prototype.end = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (args.length > 0) {
        this.write.apply(this, args);
      }
      return this.emit('end');
    };
    return LineBuffer;
  })();
}).call(this);
