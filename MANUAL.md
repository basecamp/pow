Pow User's Manual
=================

**Pow is a zero-configuration Rack server for Mac OS X.** It makes
developing Rails and Rack applications as frictionless as
possible. You can install it in ten seconds and have your first app up
and running in under a minute. No mucking around with `/etc/hosts`, no
compiling Apache modules, no editing configuration files or installing
preference panes. And running multiple apps with multiple versions of
Ruby is trivial.

How does it work? A few simple conventions eliminate the need for
tedious configuration. Pow runs as your user on an unprivileged port,
and includes both an HTTP and a DNS server. The installation process
sets up a firewall rule to forward incoming requests on port 80 to
Pow. It also sets up a system hook so that all DNS queries for a
special top-level domain (`.dev`) resolve to your local machine.

To serve a Rack app, just symlink it into your `~/.pow`
directory. Let's say you're working on an app that lives in
`~/Projects/myapp`. You'd like to access it at
`http://myapp.dev/`. Setting it up is as easy as:

    $ cd ~/.pow
    $ ln -s ~/Projects/myapp

That's it! The name of the symlink (`myapp`) determines the hostname
you use (`myapp.dev`) to access the application it points to
(`~/Projects/myapp`).

-----

## Installation ##

Pow requires Mac OS X version 10.6 or newer. To install or upgrade
Pow, just open a terminal and run this command:

    $ curl get.pow.cx | sh

You can [review the install script](http://get.pow.cx/) yourself
before running it, if you'd like. Always a good idea.

The installer unpacks the latest Pow version into
`~/Library/Application Support/Pow/Versions` and points the
`~/Library/Application Support/Pow/Current` symlink there. It also
installs
[launchd](http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man8/launchd.8.html)
scripts for your user (the Pow server itself) and for the system (to
set up the `ipfw` rule), if necessary. Then it boots the server.

**Note**: The firewall rule installed by Pow redirects all incoming
  traffic on port 80 to port 20559, where Pow runs. This means if you
  have another web server running on port 80, like the Apache that
  comes with Mac OS X, it will be inaccessible without either
  disabling the firewall rule or updating that server's configuration
  to listen on another port.

### From Source ###

To install pow from source, you will need `node >=0.4` and `npm >=1.0`.

    $ git clone https://github.com/37signals/pow.git
    $ cd pow
    $ npm --global install
    $ npm --global run-script pow restart

### Uninstalling Pow ###

If you decide Pow's not for you, uninstallation is just as easy:

    $ curl get.pow.cx/uninstall.sh | sh

([Review the uninstall script](http://get.pow.cx/uninstall.sh).)

## Managing Applications ##

Pow deals exclusively with Rack applications. For the purposes of this
document, a _Rack application_ is a directory with a `config.ru`
rackup file (and optionally a `public` subdirectory containing static
assets). For more information on rackup files, see the [Rack::Builder
documentation](http://rack.rubyforge.org/doc/Rack/Builder.html).

Pow automatically spawns a worker process for an application the first
time it's accessed, and will keep up to two workers running for each
application. Workers are automatically terminated after 15 minutes of
inactivity.

### Using virtual hosts and the .dev domain ###

A _virtual host_ specifies a mapping between a hostname and an
application. To install a virtual host, symlink a Rack application
into your `~/.pow` directory. The name of the symlink tells Pow which
hostname you want to use to access the application. For example, a
symlink named `myapp` will be accessible at `http://myapp.dev/`.

**Note**: The Pow installer creates `~/.pow` as a convenient symlink
  to `~/Library/Application Support/Pow/Hosts`, the actual location
  from which virtual host symlinks are read.

#### Subdomains ####

Once a virtual host is installed, it's also automatically accessible
from all subdomains of the named host. For example, the `myapp`
virtual host described above could also be accessed at
`http://www.myapp.dev/` and `http://assets.www.myapp.dev/`. You can
override this behavior to, say, point `www.myapp.dev` to a different
application &mdash; just create another virtual host symlink named
`www.myapp` for the application you want.

#### Multiple virtual hosts ####

You might want to serve the same application from multiple hostnames.
In Pow, an application may have more than one virtual host. Multiple
symlinks that point to the same application will share the same worker
processes.

### Customizing environment variables ###

Pow lets you customize the environment in which worker processes
run. Before an application boots, Pow attempts to execute two scripts
&mdash; first `.powrc`, then `.powenv` &mdash; in the application's
root. Any environment variables exported from these scripts are passed
along to Rack.

For example, if you wanted to adjust the Ruby load path for a
particular application, you could modify `RUBYLIB` in `.powrc`:

    export RUBYLIB="app:lib:$RUBYLIB"

#### Choosing the right environment script ####

Pow supports two separate environment scripts with the intention that
one may be checked into your source control repository, leaving the
other free for any local overrides. If this sounds like something you
need, you'll want to keep `.powrc` under version control, since it's
loaded first.

### Working with different versions of Ruby ###

Pow offers full support for running multiple applications under
different versions of Ruby with
[rvm](http://rvm.beginrescueend.com/). Just add a [project
`.rvmrc`](http://rvm.beginrescueend.com/workflow/rvmrc/#project)
file to your application's root directory and you're good to go.

For example, to instruct Pow to run an application with Ruby 1.9.2,
use this `.rvmrc` file:

    rvm 1.9.2

If an application has an `.rvmrc` file but rvm isn't installed, Pow
will show an error message without booting the app.

### Serving static files ###

Pow automatically serves static files in the `public` directory of
your application. It's possible to serve a completely static site
without a `config.ru` file as long as it has a `public` directory.

### Restarting applications ###

You can tell Pow to restart an application the next time it's
accessed. Simply save a file named `restart.txt` in the `tmp`
directory of your application (you'll need to create the directory
first if it doesn't exist). The easiest way to do this is with the
`touch` command:

    $ touch tmp/restart.txt

Restarting an application will also reload any environment scripts
(`.powrc`, `.powenv`, or `.rvmrc`) before booting the app, so don't
forget to touch `restart.txt` if you make changes to these scripts.

It's also fine to kill worker processes manually &mdash; they'll
restart the next time you access the virtual host. A handy way to do
this is with OS X's Activity Monitor. Select "All Processes,
Hierarchically" from the dropdown at the top of the Activity Monitor
window. Then find the `pow` process, expand the disclosure triangle,
find the Ruby worker process you want to kill, and choose "Quit
Process." (You can click "Inspect" on a worker process and choose
"Open Files and Ports" to determine which application the process is
serving.)

### Viewing log files ###

Pow stores log files in the `~/Library/Logs/Pow` directory so they can
be viewed easily with OS X's Console application. Each incoming
request URL is logged, along with its hostname and HTTP method, in the
`access.log` file. The stdout and stderr streams for each worker
process are captured and logged to the `apps` directory in a file
matching the name of the application.

**Note**: Rails logger output does not appear in Pow's logs. You'll
  want to `tail -f log/development.log` to see those.

## Configuring Pow ##

Pow is designed so that most people will never need to configure
it. Sometimes you can't avoid having to adjust a setting or two,
though. When Pow boots, it executes the `.powconfig` script in your
home directory if it's present. You can use this script to set
environment variables that will override Pow's default settings.

For example, this `~/.powconfig` file tells Pow to kill idle
applications after 5 minutes (300,000 ms) and spawn 3 workers per app:

    export POW_TIMEOUT=300000
    export POW_WORKERS=3

See the [Configuration class
documentation](http://pow.cx/docs/configuration.html#section-5) for a
full list of settings that you can change.

**Note**: After modifying a setting in `~/.powconfig`, you'll need to
  restart Pow for the change to take effect. You can do this by
  finding the `pow` process in OS X's Activity Monitor and clicking
  "Quit Process".

## Contributing ##

Pow is written in [Node.js](http://nodejs.org/) with
[CoffeeScript](http://jashkenas.github.com/coffee-script/). You can
read the [annotated source code](http://pow.cx/docs/) to learn about
how it works internally. Please report bugs on the [GitHub issue
tracker](https://github.com/37signals/pow/issues).

If you're interested in contributing to Pow, first start by cloning a
copy of the Git repository:

    $ git clone https://github.com/37signals/pow.git

Install the required JavaScript dependencies with
[npm](http://npmjs.org/) (you'll need version 1.0 or higher):

    $ cd pow
    $ npm install --dev

Run the test suite:

    $ cake test

## License ##

(The MIT License)

Copyright &copy; 2011 Sam Stephenson, 37signals

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
