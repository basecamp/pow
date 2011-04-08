module.exports = function(__obj) {
  var _safe = function(value) {
    if (typeof value === 'undefined' && value == null)
      value = '';
    var result = new String(value);
    result.ecoSafe = true;
    return result;
  };
  return (function() {
    var __out = [], __self = this, _print = function(value) {
      if (typeof value !== 'undefined' && value != null)
        __out.push(value.ecoSafe ? value : __self.escape(value));
    }, _capture = function(callback) {
      var out = __out, result;
      __out = [];
      callback.call(this);
      result = __out.join('');
      __out = out;
      return _safe(result);
    };
    (function() {
      _print(_safe('#!/bin/sh\n. /etc/rc.common\n \nIPFW=/sbin/ipfw\nSYSCTL=/usr/sbin/sysctl\nHTTP_PORT='));
      _print(this.httpPort);
      _print(_safe('\nDST_PORT='));
      _print(this.dstPort);
      _print(_safe('\n\n# The start subroutine\nStartService() {\n  ConsoleMessage "Starting pow ipfw route from 127.0.0.1:${HTTP_PORT} to ${DST_PORT}"\n  ${IPFW} add 5000 fwd 127.0.0.1,${HTTP_PORT} tcp from any to me dst-port ${DST_PORT} in\n  ${SYSCTL} -w net.inet.ip.forwarding=1\n}\n \n# The stop subroutine\nStopService() {\n  ConsoleMessage "Stopping pow ipfw route from 127.0.0.1:${HTTP_PORT} to ${DST_PORT}"\n  ${IPFW} del 5000\n}\n \n# The restart subroutine\nRestartService() {\n  ConsoleMessage "Restarting pow ipfw route from 127.0.0.1:${HTTP_PORT} to ${DST_PORT}"\n  ${IPFW} del 5000\n  ${IPFW} add 5000 fwd 127.0.0.1,${HTTP_PORT} tcp from any to me dst-port ${DST_PORT} in\n  ${SYSCTL} -w net.inet.ip.forwarding=1\n}\n \nRunService "$1"\n\n'));
    }).call(this);
    
    return __out.join('');
  }).call((function() {
    var obj = {
      escape: function(value) {
        return ('' + value)
          .replace(/&/g, '&amp;')
          .replace(/</g, '&lt;')
          .replace(/>/g, '&gt;')
          .replace(/"/g, '&quot;');
      },
      safe: _safe
    }, key;
    for (key in __obj) obj[key] = __obj[key];
    return obj;
  })());
};