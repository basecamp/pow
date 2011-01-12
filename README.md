### Installation

1. Install Node.js 0.2.6 and npm.
2. npm install https://github.com/skampler/ndns/tarball/master
3. git clone https://github.com/sstephenson/pow.git && cd pow
4. npm link
5. sudo mkdir -p /etc/resolver
6. sudo cp config/etc/resolver/test /etc/resolver
7. sudo cp config/launchd/cx.pow.firewall.plist /Library/LaunchDaemons
8. cp config/launchd/cx.pow.powd.plist ~/Library/LaunchAgents
9. sudo launchctl load /Library/LaunchDaemons/cx.pow.firewall.plist
10. launchctl load ~/Library/LaunchAgents/cx.pow.powd.plist
11. mkdir -p ~/.pow && cd ~/.pow
12. ln -s /path/to/myapp && open http://myapp.test/

