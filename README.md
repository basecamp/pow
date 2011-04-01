Pow: Zero-configuration Rack server for Mac OS X
================================================

**Pow is a zero-configuration Rack server for Mac OS X.** It makes
developing Rails and Rack applications _stupid easy_. You can install
it in ten seconds and have your first app up and running in under a
minute. No mucking around with `/etc/hosts`, no compiling Apache
modules, no editing configuration files or installing preference
panes. And running multiple apps with multiple versions of Ruby is
trivial.

How does it work? A few simple conventions eliminate the need for
tedious configuration. Pow runs as your user on an unprivileged port,
and includes both an HTTP and a DNS server. The installation process
sets up a firewall rule to forward incoming requests on port 80 to
Pow. It also sets up a system hook so that all DNS queries for a
special top-level domain (`.test`) resolve to your local machine.

To serve a Rack app, just symlink it into your `~/.pow`
directory. Let's say you're working on an app that lives in
`~/Projects/myapp`. You'd like to access it at
`http://myapp.test/`. Setting it up is as easy as:

    $ cd ~/.pow
    $ ln -s ~/Projects/myapp

That's it! The name of the symlink determines the hostname you use to
access the application it points to.

## Installation

## Managing Applications

## Troubleshooting

## Contributing

## License

