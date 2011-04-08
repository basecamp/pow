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
      _print(_safe('<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist SYSTEM "file://localhost/System/Library/DTDs/PropertyList.dtd">\n<plist version="0.9">\n    <dict>\n        <key>Description</key>\n        <string>Pow.cx Firewall Rules</string>\n        <key>OrderPreference</key>\n        <string>Late</string>\n        <key>Requires</key>\n        <array>\n                <string>Network</string>\n        </array>\n\n        <key>Provides</key>\n        <array>\n                <string>PowFirewallRules</string>\n        </array>\n    </dict>\n</plist>\n\n'));
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