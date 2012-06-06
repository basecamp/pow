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
        title: "Error starting application",
        "class": "big"
      }, function() {
        return __capture(function() {
          __out.push('\n  <h1 class="err">Error starting application</h1>\n  <h2>Your Rack app raised an exception when Pow tried to run it.</h2>\n  <section>\n    <pre class="breakout small_text"><strong>');
          __out.push(__sanitize(_this.err));
          __out.push('</strong>\n');
          __out.push(__sanitize(_this.stack.join("\n")));
          if (_this.rest) {
            __out.push('\n<a href="#" onclick="this.style.display=\'none\',this.nextSibling.style.display=\'\';return false">Show ');
            __out.push(__sanitize(_this.rest.length));
            __out.push(' more lines</a><div style="display: none">');
            __out.push(__sanitize(_this.rest.join("\n")));
            __out.push('</div>');
          }
          return __out.push('</pre>\n  </section>\n');
        });
      }));
    
      __out.push('\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
}