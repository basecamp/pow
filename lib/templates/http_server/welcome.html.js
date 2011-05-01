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
      _print(_safe('<!doctype html>\n<html>\n<head>\n  <meta charset="utf-8">\n  <title>Pow is installed</title>\n  <style>\n    body {\n      margin: 0;\n      padding: 0;\n      background: #e0e0d8;\n      line-height: 18px;\n    }\n    div.page {\n      margin: 72px auto;\n      background: #fff;\n      border-radius: 18px;\n      -webkit-box-shadow: 0px 2px 7px #999;\n      -moz-box-shadow: 0px 2px 7px #999;\n      padding: 36px 90px;\n      width: 480px;\n      position: relative;\n    }\n    h1, h2, p, li {\n      font-family: Helvetica, sans-serif;\n      font-size: 13px;\n    }\n    h1 {\n      line-height: 45px;\n      font-size: 36px;\n      color: #060;\n      margin: 0;\n    }\n    h1:before {\n      content: "✓";\n      font-size: 66px;\n      line-height: 42px;\n      color: #090;\n      position: absolute;\n      right: 576px;\n    }\n    h2 {\n      line-height: 27px;\n      font-size: 18px;\n      font-weight: normal;\n      margin: 0;\n    }\n    a, pre span {\n      color: #776;\n    }\n    h2, p, pre {\n      color: #222;\n    }\n    ul {\n      padding: 0;\n    }\n    li {\n      list-style-type: none;\n    }\n  </style>\n</head>\n<body>\n  <div class="page">\n    <h1>Pow is installed.</h1>\n    <h2>You&rsquo;re running version '));
      _print(this.version);
      _print(_safe('</h2>\n    <section>\n      <p>Set up a Rack application by symlinking it into your <code>~/.pow</code> directory. The name of the symlink determines the hostname you&rsquo;ll use to access the application.</p>\n      <pre><span>$</span> cd ~/.pow\n<span>$</span> ln -s /path/to/myapp\n<span>$</span> open http://myapp.'));
      _print(this.domain);
      _print(_safe('/</pre>\n    </section>\n    <ul>\n      <li><a href="http://pow.cx/manual">Pow User&rsquo;s Manual</a></li>\n      <li><a href="https://github.com/37signals/pow/wiki/Troubleshooting">Troubleshooting</a></li>\n      <li><a href="https://github.com/37signals/pow/wiki/FAQ">Frequently Asked Questions</a></li>\n      <li><a href="https://github.com/37signals/pow/issues">Issue Tracker</a></li>\n    </ul>\n  </div>\n</body>\n</html>\n'));
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