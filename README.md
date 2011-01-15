### Installation

1. Install Node.js 0.2.6 and npm.
1. git clone https://github.com/sstephenson/pow.git && cd pow
1. npm link
1. sudo mkdir -p /etc/resolver
1. sudo cp config/etc/resolver/test /etc/resolver
1. sudo cp config/launchd/cx.pow.firewall.plist /Library/LaunchDaemons
1. cp config/launchd/cx.pow.powd.plist ~/Library/LaunchAgents
1. sudo launchctl load /Library/LaunchDaemons/cx.pow.firewall.plist
1. launchctl load ~/Library/LaunchAgents/cx.pow.powd.plist
1. mkdir -p ~/.pow && cd ~/.pow
1. ln -s /path/to/myapp && open http://myapp.test/

