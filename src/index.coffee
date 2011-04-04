# **Pow is a zero-configuration Rack server for Mac OS X.** It makes
# developing Rails and Rack applications _stupid easy_. You can
# install it in ten seconds and have your first app up and running in
# under a minute. No mucking around with `/etc/hosts`, no compiling
# Apache modules, no editing configuration files or installing
# preference panes. And running multiple apps with multiple versions
# of Ruby is trivial.
#
# How does it work? A few simple conventions eliminate the need for
# tedious configuration. Pow runs as your user on an unprivileged
# port, and includes both an HTTP and a DNS server. The installation
# process sets up a firewall rule to forward incoming requests on port
# 80 to Pow. It also sets up a system hook so that all DNS queries for
# a special top-level domain (`.test`) resolve to your local machine.
#
# To serve a Rack app, just symlink it into your `~/.pow`
# directory. Let's say you're working on an app that lives in
# `~/Projects/myapp`. You'd like to access it at
# `http://myapp.test/`. Setting it up is as easy as:
#
#     $ cd ~/.pow
#     $ ln -s ~/Projects/myapp
#
# That's it! The name of the symlink (`myapp`) determines the hostname
# you use (`myapp.test`) to access the application it points to
# (`~/Projects/myapp`).

# ### Annotated source code
module.exports =

  # The [Configuration](configuration.html) class stores settings for
  # a Pow daemon and is responsible for mapping hostnames to Rack
  # applications.
  Configuration:   require "./configuration"

  # The [Daemon](daemon.html) class represents a running Pow daemon.
  Daemon:          require "./daemon"

  # [DnsServer](dns_server.html) handles incoming DNS queries.
  DnsServer:       require "./dns_server"

  # [HttpServer](http_server.html) handles incoming HTTP requests.
  HttpServer:      require "./http_server"

  # [Installer](installer.html) compiles and installs local and system
  # configuration files.
  Installer:       require "./installer"

  # [Logger](logger.html) keeps track of everything that happens
  # during a Pow daemon's lifecycle.
  Logger:          require "./logger"

  # [RackApplication](rack_application.html) represents a single
  # running application.
  RackApplication: require "./rack_application"

  # The [util](util.html) module contains various helper functions.
  util:            require "./util"
