#!/bin/sh
#
#     8b,dPPYba,    ,adPPYba,   8b      db      d8
#     88P'    "8a  a8"     "8a  `8b    d88b    d8'
#     88       d8  8b       d8   `8b  d8'`8b  d8'
#     88b,   ,a8"  "8a,   ,a8"    `8bd8'  `8bd8'
#     88`YbbdP"'    `"YbbdP"'       YP      YP
#     88
#     88
#
#     Zero-configuration development server for Rack applications
#
#     Requires Mac OS X 10.6
#     To install, run this command in a Terminal window:
#
#     curl get.pow.cx | sh -
#

set -e
POW_ROOT="$HOME/Library/Application Support/Pow"
[[ -z "$VERSION" ]] && VERSION=0.1.1

echo "*** Installing Pow $VERSION..."

mkdir -p "$POW_ROOT"
cd "$POW_ROOT"
mkdir -p Hosts
mkdir -p Versions
cd Versions
curl -s http://get.pow.cx.s3-website-us-east-1.amazonaws.com/versions/$VERSION.tar.gz | tar xzf -
cd ..
rm -f Current
ln -s Versions/$VERSION Current

cd
[[ -a .pow ]] || ln -s "$POW_ROOT/Hosts" .pow

mkdir -p Library/LaunchAgents
cat > Library/LaunchAgents/cx.pow.powd.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>cx.pow.powd</string>
	<key>ProgramArguments</key>
	<array>
		<string>sh</string>
		<string>-i</string>
		<string>-c</string>
		<string>\$SHELL --login -c "'$POW_ROOT/Current/bin/pow'"</string>
	</array>
	<key>KeepAlive</key>
	<true/>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
EOF

TMP=/tmp/pow-install.$$
mkdir -p $TMP

cat > $TMP/cx.pow.firewall.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>cx.pow.firewall</string>
	<key>ProgramArguments</key>
	<array>
		<string>$POW_ROOT/Current/bin/pow_firewall</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>UserName</key>
	<string>root</string>
</dict>
</plist>
EOF

cat > $TMP/test <<EOF
nameserver 127.0.0.1
port 20560
EOF

sudo mv $TMP/cx.pow.firewall.plist /Library/LaunchDaemons
sudo chown root:wheel /Library/LaunchDaemons/cx.pow.firewall.plist
sudo mkdir -p /etc/resolver
sudo mv $TMP/test /etc/resolver

sudo launchctl load /Library/LaunchDaemons/cx.pow.firewall.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/cx.pow.powd.plist 2>/dev/null

echo "*** Installed"
