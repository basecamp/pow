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
        title: "Pow is installed"
      }, function() {
        return __capture(function() {
          __out.push('\n  <h1 class="ok">Pow is installed</h1>\n  <h2>You&rsquo;re running version ');
          __out.push(__sanitize(_this.version));
          __out.push('.</h2>\n  <section>\n    <p>Set up a Rack application by symlinking it into your <code>~/.pow</code> directory. The name of the symlink determines the hostname you&rsquo;ll use to access the application.</p>\n    <pre><span>$</span> cd ~/.pow\n<span>$</span> ln -s /path/to/myapp\n<span>$</span> open http://myapp.');
          __out.push(__sanitize(_this.domain));
          return __out.push('/</pre>\n  </section>\n');
        });
      }));
    
      __out.push('\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
}