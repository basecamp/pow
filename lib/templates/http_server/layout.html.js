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
    
      _print(_safe('<!doctype html>\n<html>\n<head>\n  <meta charset="utf-8">\n  <title>'));
    
      _print(this.title);
    
      _print(_safe('</title>\n  <style>\n    body {\n      margin: 0;\n      padding: 0;\n      background: #e0e0d8;\n      line-height: 18px;\n    }\n    div.page {\n      margin: 72px auto;\n      margin: 36px auto;\n      background: #fff;\n      border-radius: 18px;\n      -webkit-box-shadow: 0px 2px 7px #999;\n      -moz-box-shadow: 0px 2px 7px #999;\n      padding: 36px 90px;\n      width: 480px;\n      position: relative;\n    }\n    .big div.page {\n      width: 720px;\n    }\n    h1, h2, p, li {\n      font-family: Helvetica, sans-serif;\n      font-size: 13px;\n    }\n    h1 {\n      line-height: 45px;\n      font-size: 36px;\n      margin: 0;\n    }\n    h1:before {\n      font-size: 66px;\n      line-height: 42px;\n      position: absolute;\n      right: 576px;\n    }\n    .big h1:before {\n      right: 819px;\n    }\n    h1.ok {\n      color: #060;\n    }\n    h1.ok:before {\n      content: "✓";\n      color: #090;\n    }\n    h1.err {\n      color: #600;\n    }\n    h1.err:before {\n      content: "✗";\n      color: #900;\n    }\n    h2 {\n      line-height: 27px;\n      font-size: 18px;\n      font-weight: normal;\n      margin: 0;\n    }\n    a, pre span {\n      color: #776;\n    }\n    h2, p, pre {\n      color: #222;\n    }\n    pre {\n      white-space: pre-wrap;\n      font-size: 13px;\n    }\n    pre, code {\n      font-family: Menlo, Monaco, monospace;\n    }\n    p code {\n      font-size: 12px;\n    }\n    pre.breakout {\n      border-top: 1px solid #ddd;\n      border-bottom: 1px solid #ddd;\n      background: #fafcf4;\n      margin-left: -90px;\n      margin-right: -90px;\n      padding: 8px 0 8px 90px;\n    }\n    pre.small_text {\n      font-size: 10px;\n    }\n    pre.small_text strong {\n      font-size: 13px;\n    }\n    ul {\n      padding: 0;\n    }\n    li {\n      list-style-type: none;\n    }\n  </style>\n</head>\n<body class="'));
    
      _print(this["class"]);
    
      _print(_safe('">\n  <div class="page">\n    '));
    
      _print(this.yield());
    
      _print(_safe('\n    <ul>\n      <li><a href="http://pow.cx/manual">Pow User&rsquo;s Manual</a></li>\n      <li><a href="https://github.com/37signals/pow/wiki/Troubleshooting">Troubleshooting</a></li>\n      <li><a href="https://github.com/37signals/pow/wiki/FAQ">Frequently Asked Questions</a></li>\n      <li><a href="https://github.com/37signals/pow/issues">Issue Tracker</a></li>\n    </ul>\n  </div>\n</body>\n</html>\n'));
    
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