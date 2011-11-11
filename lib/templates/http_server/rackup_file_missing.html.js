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
        title: "Rackup file missing"
      }, function() {
        return _capture(function() {
          return _print(_safe('\n  <h1 class="err">Rackup file missing</h1>\n  <h2>Your Rails app needs a <code>config.ru</code> file.</h2>\n  <section>\n    <p>If your app is using Rails 2.3, create a <code>config.ru</code> file in the application root containing the following:</p>\n    <pre class="breakout">require File.dirname(__FILE__) + \'/config/environment\'\nrun ActionController::Dispatcher.new</pre>\n    <p>If you&rsquo;re using a version of Rails older than 2.3, you&rsquo;ll need to upgrade first.</p>\n  </section>\n'));
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