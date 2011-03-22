# **Pow is a zero-configuration Rack server for Mac OS X.** It makes
# developing Rails and Rack applications _stupid easy_. You can
# install it in ten seconds from the terminal (seriously!) and have
# your first app up and running in under a minute. No mucking around
# with your `/etc/hosts` file, no compiling Apache modules, no editing
# configuration files or installing preference panes. And running
# multiple apps is cake.
#
# How does it work? A few simple conventions eliminate the need for
# tedious configuration. Pow runs as your user on an unprivileged
# port, and includes both an HTTP and a DNS server. The installation
# process sets up a firewall rule to forward incoming requests on port
# 80 to Pow. It also sets up a system hook so that all DNS queries for
# `*.test` resolve to your local machine.
#
# To serve a Rack app, just symlink it into your `~/.pow`
# directory. The name of the symlink is the hostname you use to access
# the app. So if you symlink `/Volumes/37signals/basecamp` into
# `~/.pow/basecamp`, it'll handle all HTTP requests for
# `*.basecamp.test`.

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

  # [Logger](logger.html) keeps track of everything that happens
  # during a Pow daemon's lifecycle.
  Logger:          require "./logger"

  # [RackApplication](rack_application.html) represents a single
  # running application.
  RackApplication: require "./rack_application"

  # The [util](util.html) module contains various helper functions.
  util:            require "./util"
