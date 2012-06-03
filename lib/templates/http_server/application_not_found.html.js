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
        title: "Application not found"
      }, function() {
        return __capture(function() {
          __out.push('\n  <h1 class="err">Application not found</h1>\n  <h2>Symlink your app to <code>~/.pow/');
          __out.push(__sanitize(_this.name));
          __out.push('</code> first.</h2>\n  <section>\n    <p>When you access <code>http://');
          __out.push(__sanitize(_this.host));
          __out.push('/</code>, Pow looks for a Rack application at <code>~/.pow/');
          __out.push(__sanitize(_this.name));
          __out.push('</code>. To run your app at this domain:</p>\n    <pre><span>$</span> cd ~/.pow\n<span>$</span> ln -s /path/to/myapp ');
          __out.push(__sanitize(_this.name));
          __out.push('\n<span>$</span> open http://');
          __out.push(__sanitize(_this.host));
          return __out.push('/</pre>\n  </section>\n');
        });
      }));
    
      __out.push('\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
}