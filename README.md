Pow: Zero-configuration Rack server for Mac OS X
================================================

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

## Installation

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

## Managing Applications

Pow deals exclusively with Rack applications. For the purposes of this
document, a Rack application is a directory with a `config.ru` rackup
file (and optionally a `public` subdirectory containing static
assets). For more information on rackup files, see the [Rack::Builder
documentation](http://rack.rubyforge.org/doc/Rack/Builder.html).

Pow automatically spawns a worker process for an application the first
time it's accessed, and will keep up to two workers running for each
application. Workers are automatically terminated after 15 minutes of
inactivity.

### Using virtual hosts and the .dev domain

A virtual host specifies a mapping between a hostname and an
application. (An application may have more than one virtual host.)

### Customizing environment variables

### Working with different versions of Ruby

### Serving static files

### Restarting applications

### Viewing log files

## Contributing

## License

(The MIT License)

Copyright (c) 2011 Sam Stephenson, 37signals

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
