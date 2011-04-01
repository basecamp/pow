#!/bin/sh
#
#     8b,dPPYba,    ,adPPYba,   8b      db      d8
#     88P'    "8a  a8"     "8a  `8b    d88b    d8'
#     88       d8  8b       d8   `8b  d8'`8b  d8'
#     88b,   ,a8"  "8a,   ,a8"    `8bd8'  `8bd8'
#     88`YbbdP"'    `"YbbdP"'       YP      YP
#     88
#     88    Zero-configuration Rack server
#           for Mac OS X -- http://pow.cx/
#
#
#     To install, run this command in a terminal:
#
#     curl get.pow.cx | sh
#

set -e
POW_ROOT="$HOME/Library/Application Support/Pow"
[[ -z "$VERSION" ]] && VERSION=0.1.9

# Fail fast if we're not on OS X >= 10.6.0.
if [ "$(uname -s)" != "Darwin" ]; then
  echo "Sorry, Pow requires Mac OS X to run." >&2
  exit 1
elif [ "$(expr "$(uname -r | cut -f 2 -d .)" \>= 7)" = 0 ]; then
  echo "Pow requires Mac OS X 10.6 or later." >&2
  exit 1
fi

echo "*** Installing Pow $VERSION..."

# Create the Pow directory structure if it doesn't already exist.
mkdir -p "$POW_ROOT"
cd "$POW_ROOT"
mkdir -p Hosts
mkdir -p Versions

# If the requested version of Pow is already installed, remove it first.
cd Versions
rm -rf "$POW_ROOT/Versions/$VERSION"

# Download the requested version of Pow and unpack it.
curl -s http://get.pow.cx/versions/$VERSION.tar.gz | tar xzf -
cd ..

# Update the Current symlink to point to the new version.
rm -f Current
ln -s Versions/$VERSION Current

# Create the ~/.pow symlink if it doesn't exist.
cd
[[ -a .pow ]] || ln -s "$POW_ROOT/Hosts" .pow

# Make a temporary directory for the launchd and resolver files.
TMP="/tmp/pow-install.$$"
mkdir -p "$TMP"

# Write out the powd launchctl script.
POWD_SCRIPT_SRC="$TMP/cx.pow.powd.plist"
POWD_SCRIPT_DST="$HOME/Library/LaunchAgents/cx.pow.powd.plist"
cat > "$POWD_SCRIPT_SRC" <<EOF
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

# Write out the resolver file.
RESOLVER_FILE_SRC="$TMP/test"
RESOLVER_FILE_DST="/etc/resolver/test"
cat > "$RESOLVER_FILE_SRC" <<EOF
nameserver 127.0.0.1
port 20560
EOF

# Determine whether the resolver file needs to be installed.
if [[ ! -a "$RESOLVER_FILE_DST" ]]; then
  INSTALL_RESOLVER_FILE=1
elif [[ -n $(diff -q "$RESOLVER_FILE_SRC" "$RESOLVER_FILE_DST" && true) ]]; then
  INSTALL_RESOLVER_FILE=1
else
  INSTALL_RESOLVER_FILE=0
fi

# Write out the firewall launchctl script.
FIREWALL_SCRIPT_SRC="$TMP/cx.pow.firewall.plist"
FIREWALL_SCRIPT_DST="/Library/LaunchDaemons/cx.pow.firewall.plist"
cat > "$FIREWALL_SCRIPT_SRC" <<EOF
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

# Determine whether the firewall launchctl script needs to be installed.
if [[ ! -a "$FIREWALL_SCRIPT_DST" ]]; then
  INSTALL_FIREWALL_SCRIPT=1
elif [[ -n $(diff -q "$FIREWALL_SCRIPT_SRC" "$FIREWALL_SCRIPT_DST" && true) ]]; then
  INSTALL_FIREWALL_SCRIPT=1
else
  INSTALL_FIREWALL_SCRIPT=0
fi

# Install the powd launchctl script.
mkdir -p Library/LaunchAgents
mv "$POWD_SCRIPT_SRC" "$POWD_SCRIPT_DST"

# Start (or restart) powd.
echo "*** Starting the Pow server..."
launchctl unload "$POWD_SCRIPT_DST" 2>/dev/null || true
launchctl load "$POWD_SCRIPT_DST" 2>/dev/null

# Print a message if we need to elevate privileges.
if [ $INSTALL_RESOLVER_FILE = 1 ] || [ $INSTALL_FIREWALL_SCRIPT = 1 ]; then
  echo "*** Installing system startup scripts as root..."
fi

# Install the resolver file, if necessary.
if [ $INSTALL_RESOLVER_FILE = 1 ]; then
  sudo mkdir -p /etc/resolver
  sudo mv "$RESOLVER_FILE_SRC" "$RESOLVER_FILE_DST"
fi

# Install the firewall script, if necessary.
if [ $INSTALL_FIREWALL_SCRIPT = 1 ]; then
  sudo mv "$FIREWALL_SCRIPT_SRC" "$FIREWALL_SCRIPT_DST"
  sudo chown root:wheel "$FIREWALL_SCRIPT_DST"
  sudo launchctl load "$FIREWALL_SCRIPT_DST" 2>/dev/null
fi

# Remove the temporary directory.
rm -rf "$TMP"

echo "*** Installed"
