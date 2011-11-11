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
      var _this = this;
    
      _print(_safe(this.renderTemplate("layout", {
        title: "Application not found"
      }, function() {
        return _capture(function() {
          _print(_safe('\n  <h1 class="err">Application not found</h1>\n  <h2>Symlink your app to <code>~/.pow/'));
          _print(_this.name);
          _print(_safe('</code> first.</h2>\n  <section>\n    <p>When you access <code>http://'));
          _print(_this.host);
          _print(_safe('/</code>, Pow looks for a Rack application at <code>~/.pow/'));
          _print(_this.name);
          _print(_safe('</code>. To run your app at this domain:</p>\n    <pre><span>$</span> cd ~/.pow\n<span>$</span> ln -s /path/to/myapp '));
          _print(_this.name);
          _print(_safe('\n<span>$</span> open http://'));
          _print(_this.host);
          return _print(_safe('/</pre>\n  </section>\n'));
        });
      })));
    
      _print(_safe('\n'));
    
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