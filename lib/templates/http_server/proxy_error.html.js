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
      var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
      _print(_safe(this.renderTemplate("layout", {
        title: "Proxy Error"
      }, __bind(function() {
        return _capture(__bind(function() {
          _print(_safe('\n  <h1 class="err">Proxy Error</h1>\n  <h2>Couldn\'t proxy request to <code>'));
          _print(this.hostname);
          _print(_safe(':'));
          _print(this.port);
          _print(_safe('</code>.</h2>\n  <section>\n    <pre class="breakout small_text"><strong>'));
          _print(this.err);
          return _print(_safe('</strong>\n  </section>\n'));
        }, this));
      }, this))));
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