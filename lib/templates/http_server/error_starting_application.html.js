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
        title: "Error starting application",
        "class": "big"
      }, function() {
        return _capture(function() {
          _print(_safe('\n  <h1 class="err">Error starting application</h1>\n  <h2>Your Rack app raised an exception when Pow tried to run it.</h2>\n  <section>\n    <pre class="breakout small_text"><strong>'));
          _print(_this.err);
          _print(_safe('</strong>\n'));
          _print(_this.stack.join("\n"));
          if (_this.rest) {
            _print(_safe('\n<a href="#" onclick="this.style.display=\'none\',this.nextSibling.style.display=\'\';return false">Show '));
            _print(_this.rest.length);
            _print(_safe(' more lines</a><div style="display: none">'));
            _print(_this.rest.join("\n"));
            _print(_safe('</div>'));
          }
          return _print(_safe('</pre>\n    <p>(If your app uses Bundler, check to make sure you have the <a href="http://gembundler.com/">latest version</a>, then run <code>bundle install</code>. If you&rsquo;re using rvm, make sure you have the <a href="https://rvm.beginrescueend.com/rvm/upgrading/">latest version</a> installed and your app is using the right gemset.)</p>\n  </section>\n'));
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