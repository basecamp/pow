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
      var _this = this;
    
      __out.push(this.renderTemplate("layout", {
        title: "Rackup file missing"
      }, function() {
        return __capture(function() {
          return __out.push('\n  <h1 class="err">Rackup file missing</h1>\n  <h2>Your Rails app needs a <code>config.ru</code> file.</h2>\n  <section>\n    <p>If your app is using Rails 2.3, create a <code>config.ru</code> file in the application root containing the following:</p>\n    <pre class="breakout">require File.dirname(__FILE__) + \'/config/environment\'\nrun ActionController::Dispatcher.new</pre>\n    <p>If you&rsquo;re using a version of Rails older than 2.3, you&rsquo;ll need to upgrade first.</p>\n  </section>\n');
        });
      }));
    
      __out.push('\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
}