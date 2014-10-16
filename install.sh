#!/bin/sh
#                       W
#                      R RW        W.
#                    RW::::RW    DR::R
#         :RRRRRWWWWRt:::::::RRR::::::E        jR
#          R.::::::::::::::::::::::::::Ri  jiR:::R
#           R:::::::.RERRRRWWRERR,::::::Efi:::::::R             GjRRR Rj
#            R::::::.R             R:::::::::::::;G    RRj    WWR    RjRRRRj
#            Rt::::WR      RRWR     R::::::::::::::::fWR::R;  WRW    RW    R
#        WWWWRR:::EWR     E::W     WRRW:::EWRRR::::::::: RRED WR    RRW   RR
#        'R:::::::RRR            RR     DWW   R::::::::RW   LRRR    WR    R
#          RL:::::WRR       GRWRR        RR   R::WRiGRWW    RRR    RRR   R
#            Ri:::WWD    RWRRRWW   WWR   LR   R W    RR    RRRR    RR    R
#   RRRWWWWRE;,:::WW     R:::RW   RR:W   RR   ERE    RR    RRR    RRR    R
#    RR:::::::::::RR    tR:::WR   Wf:R   RW    R     R     RRR    RR    R
#      WR::::::::tRR    WR::RW   ER.R   RRR       R       RRRR    RR    R
#         WE:::::RR     R:::RR   :RW   E RR      RW;     GRRR    RR    R
#         R.::::,WR     R:::GRW       E::RR     WiWW     RRWR   LRRWWRR
#       WR::::::RRRRWRG::::::RREWDWRj::::RW  ,WR::WR    iRWWWWWRWW    R
#     LR:::::::::::::::::::::::::::::::::EWRR::::::RRRDi:::W    RR   R
#    R:::::::::::::::::::::::::::::::::::::::::::::::::::tRW   RRRWWWW
#  RRRRRRRRRRR::::::::::::::::::::::::::::::::::::,:::DE RRWRWW,
#            R::::::::::::: RW::::::::R::::::::::RRWRRR
#            R::::::::::WR.  ;R::::;R  RWi:::::ER
#            R::::::.RR       Ri:iR       RR:,R
#            E::: RE           RW           Y
#            ERRR
#            G       Zero-configuration Rack server for Mac OS X
#                    http://pow.cx/
#
#     This is the installation script for Pow.
#     See the full annotated source: http://pow.cx/docs/
#
#     Install Pow by running this command:
#     curl get.pow.cx | sh
#
#     Uninstall Pow: :'(
#     curl get.pow.cx/uninstall.sh | sh


# Set up the environment.

      set -e
      POW_ROOT="$HOME/Library/Application Support/Pow"
      NODE_BIN="$POW_ROOT/Current/bin/node"
      POW_BIN="$POW_ROOT/Current/bin/pow"
      LATEST_VERSION="0.5.0"

      if [ -z "$ARCHIVE_URL_ROOT" ]; then
        ARCHIVE_URL_ROOT="http://get.pow.cx/versions"
      else
        ARCHIVE_URL_ROOT="${ARCHIVE_URL_ROOT%/}"
      fi


# Fail fast if we're not on OS X.

      if [ "$(uname -s)" != "Darwin" ]; then
        echo "Sorry, Pow requires Mac OS X to run." >&2
        exit 1
      fi


# Define a function to extract version number components.

      version_component() {
        printf "%s" "$1" |
          sed -e "s/\./"$'\t'"/g" -e "s/-/"$'\t'"/" |
          cut -f "$2"
      }


# Pow 0.4.3 and earlier require OS X 10.6; 0.5.0 and up require OS X 10.9.
# If $VERSION is unspecified, default to the highest supported version for
# each platform. Otherwise, ensure the platform version is recent enough.

      MAC_OS_VERSION="$(sw_vers -productVersion)"
      MAC_OS_MINOR_VERSION="$(version_component "$MAC_OS_VERSION" 2)"

      if [ "$MAC_OS_MINOR_VERSION" -lt 6 ]; then
        echo "Pow requires Mac OS X 10.6 or later." >&2
        exit 1

      elif [ -z "$VERSION" ]; then
        if [ "$MAC_OS_MINOR_VERSION" -lt 9 ]; then
          VERSION="0.4.3"
        else
          VERSION="$LATEST_VERSION"
        fi

      else
        POW_MAJOR_VERSION="$(version_component "$VERSION" 1)"
        POW_MINOR_VERSION="$(version_component "$VERSION" 2)"

        if [ "$MAC_OS_MINOR_VERSION" -gt 9 ]; then
          if [ "$POW_MAJOR_VERSION" -le 0 ] && [ "$POW_MINOR_VERSION" -lt 5 ]; then
            echo "OS X $MAC_OS_VERSION requires Pow 0.5.0 or later." >&2
            exit 1
          fi

        elif [ "$MAC_OS_MINOR_VERSION" -lt 9 ]; then
          if [ "$POW_MAJOR_VERSION" -gt 0 ] || [ "$POW_MINOR_VERSION" -ge 5 ]; then
            echo "Pow $VERSION requires OS X 10.9 or later." >&2
            exit 1
          fi
        fi
      fi


# Prepare for installation.

      ARCHIVE_URL="$ARCHIVE_URL_ROOT/$VERSION.tar.gz"
      echo "*** Installing Pow $VERSION..."


# Create the Pow directory structure if it doesn't already exist.

      mkdir -p "$POW_ROOT/Hosts" "$POW_ROOT/Versions"


# If the requested version of Pow is already installed, remove it first.

      cd "$POW_ROOT/Versions"
      rm -rf "$POW_ROOT/Versions/$VERSION"


# Download the requested version of Pow and unpack it.

      curl -sL "$ARCHIVE_URL" | tar xzf -


# Update the Current symlink to point to the new version.

      cd "$POW_ROOT"
      rm -f Current
      ln -s Versions/$VERSION Current


# Create the ~/.pow symlink if it doesn't exist.

      cd "$HOME"
      [ -a .pow ] || ln -s "$POW_ROOT/Hosts" .pow


# Install local configuration files.

      echo "*** Installing local configuration files..."
      "$NODE_BIN" "$POW_BIN" --install-local


# Check to see whether we need root privileges.

      "$NODE_BIN" "$POW_BIN" --install-system --dry-run >/dev/null && NEEDS_ROOT=0 || NEEDS_ROOT=1


# Install system configuration files, if necessary. (Avoid sudo otherwise.)

      if [ $NEEDS_ROOT -eq 1 ]; then
        echo "*** Installing system configuration files as root..."
        sudo "$NODE_BIN" "$POW_BIN" --install-system

        if [ "$MAC_OS_MINOR_VERSION" -ge 10 ]; then
          sudo launchctl bootstrap system /Library/LaunchDaemons/cx.pow.firewall.plist 2>/dev/null
          sudo launchctl enable system/cx.pow.firewall 2>/dev/null
          sudo launchctl kickstart -k system/cx.pow.firewall 2>/dev/null
        else
          sudo launchctl load -Fw /Library/LaunchDaemons/cx.pow.firewall.plist 2>/dev/null
        fi
      fi


# Start (or restart) Pow.

      echo "*** Starting the Pow server..."

      if [ "$MAC_OS_MINOR_VERSION" -ge 10 ]; then
        launchctl bootstrap gui/"$UID" "$HOME/Library/LaunchAgents/cx.pow.powd.plist" 2>/dev/null
        launchctl enable gui/"$UID"/cx.pow.powd 2>/dev/null
        launchctl kickstart -k gui/"$UID"/cx.pow.powd 2>/dev/null
      else
        launchctl unload "$HOME/Library/LaunchAgents/cx.pow.powd.plist" 2>/dev/null || true
        launchctl load -Fw "$HOME/Library/LaunchAgents/cx.pow.powd.plist" 2>/dev/null
      fi


# Show a message about where to go for help.

      function print_troubleshooting_instructions() {
        echo
        echo "For troubleshooting instructions, please see the Pow wiki:"
        echo "https://github.com/basecamp/pow/wiki/Troubleshooting"
        echo
        echo "To uninstall Pow, \`curl get.pow.cx/uninstall.sh | sh\`"
      }


# Check to see if the server is running properly.

      # If this version of Pow supports the --print-config option,
      # source the configuration and use it to run a self-test.
      CONFIG=$("$NODE_BIN" "$POW_BIN" --print-config 2>/dev/null || true)

      if [ -n "$CONFIG" ]; then
        eval "$CONFIG"
        echo "*** Performing self-test..."

        # Check to see if the server is running at all.
        function check_status() {
          sleep 1
          curl -sH host:pow "127.0.0.1:$POW_HTTP_PORT/status.json" | grep -c "$VERSION" >/dev/null
        }

        # Attempt to connect to Pow via each configured domain. If a
        # domain is inaccessible, try to force a reload of OS X's
        # network configuration.
        function check_domains() {
          for domain in ${POW_DOMAINS//,/$IFS}; do
            echo | nc "${domain}." "$POW_DST_PORT" 2>/dev/null || return 1
          done
        }

        # Use networksetup(8) to create a temporary network location,
        # switch to it, switch back to the original location, then
        # delete the temporary location. This forces reloading of the
        # system network configuration.
        function reload_network_configuration() {
          [ "$MAC_OS_MINOR_VERSION" -lt 10 ] || return
          echo "*** Reloading system network configuration..."
          local location=$(networksetup -getcurrentlocation)
          networksetup -createlocation "pow$$" >/dev/null 2>&1
          networksetup -switchtolocation "pow$$" >/dev/null 2>&1
          networksetup -switchtolocation "$location" >/dev/null 2>&1
          networksetup -deletelocation "pow$$" >/dev/null 2>&1
        }

        # Try twice to connect to Pow. Bail if it doesn't work.
        check_status || check_status || {
          echo "!!! Couldn't find a running Pow server on port $POW_HTTP_PORT"
          print_troubleshooting_instructions
          exit 1
        }

        # Try resolving and connecting to each configured domain. If
        # it doesn't work, reload the network configuration and try
        # again. Bail if it fails the second time.
        check_domains || {
          { reload_network_configuration && check_domains; } || {
            echo "!!! Couldn't resolve configured domains ($POW_DOMAINS)"
            print_troubleshooting_instructions
            exit 1
          }
        }
      fi


# All done!

      echo "*** Installed"
      print_troubleshooting_instructions
