module.exports = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0">\n<dict>\n\t<key>Label</key>\n\t<string>cx.pow.firewall</string>\n\t<key>ProgramArguments</key>\n\t<array>\n\t\t<string>sh</string>\n\t\t<string>-c</string>\n\t\t<string>ipfw add fwd 127.0.0.1,');
    
      __out.push(__sanitize(this.httpPort));
    
      __out.push(' tcp from any to me dst-port ');
    
      __out.push(__sanitize(this.dstPort));
    
      __out.push(' in &amp;&amp; sysctl -w net.inet.ip.forwarding=1 &amp;&amp; sysctl -w net.inet.ip.fw.enable=1</string>\n\t</array>\n\t<key>RunAtLoad</key>\n\t<true/>\n\t<key>UserName</key>\n\t<string>root</string>\n</dict>\n</plist>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
}