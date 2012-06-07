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
    
      __out.push('<!doctype html>\n<html>\n  <head>\n    <title>Pow: Automatic RVM support is deprecated</title>\n    <style type="text/css">\n      html {\n        background: #fff;\n        margin: 0;\n        padding: 0;\n      }\n\n      body {\n        margin: 30px auto;\n        padding: 15px 35px;\n        width: 520px;\n        font-family: Lucida Grande;\n      }\n\n      h1 {\n        font-family: Helvetica;\n        font-size: 24px;\n      }\n\n      a {\n        color: #03f;\n      }\n\n      p {\n        width: 460px;\n        font-size: 13px;\n      }\n\n      .important {\n        background: #ff3;\n      }\n\n      code {\n        font-family: Menlo;\n        font-size: 12px;\n      }\n    </style>\n    <script type="text/javascript">\n      function addToPowrc(link) {\n        perform(link, "add_to_powrc",\n          "This code has been added to your application&rsquo;s <code>.powrc</code> file."\n        )\n      }\n\n      function disable(link) {\n        perform(link, "disable",\n          "You will not see this deprecation notice for other applications. " +\n          \'<a href="#" onclick="enable(this); return false">Undo</a>\'\n        )\n      }\n\n      function enable(link) {\n        perform(link, "enable")\n      }\n\n      function perform(link, action, successHTML) {\n        if (link.className == "busy") return\n        link.className = "busy"\n\n        xhr = new XMLHttpRequest()\n        xhr.open("POST", "/__pow__/rvm_deprecation/" + action, true)\n        xhr.onreadystatechange = function() {\n          if (xhr.readyState != 4) return\n          link.className = ""\n\n          if (xhr.status == 200) {\n            var p = link.parentNode\n            var previousInnerHTML = p.previousInnerHTML\n            p.previousInnerHTML = p.innerHTML\n            p.innerHTML = successHTML || previousInnerHTML\n          }\n        }\n\n        xhr.send()\n      }\n    </script>\n  </head>\n  <body>\n    <h1>Automatic RVM support is deprecated</h1>\n\n    <p>We&rsquo;re showing you this notice because you just accessed\n    an application with a per-project <code>.rvmrc</code> file.</p>\n\n    <p><span class="important">Support for automatically loading\n    per-project <code>.rvmrc</code> files in Pow is deprecated and\n    will be removed in the next major release.</span></p>\n\n    <p>Ensure your application continues to work with future releases\n    of Pow by adding the following code to the\n    application&rsquo;s <code>.powrc</code> file:</p>\n\n    <pre><code>');
    
      __out.push(__sanitize(this.boilerplate));
    
      __out.push('</code></pre>\n\n    <p><a href="#" onclick="addToPowrc(this); return false">Add this\n    code to <code>.powrc</code> for me</a></p>\n\n    <p>We won&rsquo;t notify you again for this project.</p>\n\n    <p><a href="#" onclick="disable(this); return false">Don&rsquo;t\n    notify me about deprecations for any other applications,\n    either</a></p>\n\n    <p>Thanks for using Pow.</p>\n  </body>\n</html>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
}