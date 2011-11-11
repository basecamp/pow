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
        title: "Pow is installed"
      }, function() {
        return _capture(function() {
          _print(_safe('\n  <h1 class="ok">Pow is installed</h1>\n  <h2>You&rsquo;re running version '));
          _print(_this.version);
          _print(_safe('.</h2>\n  <section>\n    <p>Set up a Rack application by symlinking it into your <code>~/.pow</code> directory. The name of the symlink determines the hostname you&rsquo;ll use to access the application.</p>\n    <pre><span>$</span> cd ~/.pow\n<span>$</span> ln -s /path/to/myapp\n<span>$</span> open http://myapp.'));
          _print(_this.domain);
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