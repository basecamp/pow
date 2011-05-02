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


# Set up the environment. Respect $VERSION if it's set.

      set -e
      POW_ROOT="$HOME/Library/Application Support/Pow"
      POW_BIN="$POW_ROOT/Current/bin"
      [[ -z "$VERSION" ]] && VERSION=0.2.2


# Fail fast if we're not on OS X >= 10.6.0.

      if [ "$(uname -s)" != "Darwin" ]; then
        echo "Sorry, Pow requires Mac OS X to run." >&2
        exit 1
      elif [ "$(expr "$(sw_vers -productVersion | cut -f 2 -d .)" \>= 6)" = 0 ]; then
        echo "Pow requires Mac OS X 10.6 or later." >&2
        exit 1
      fi

      echo "*** Installing Pow $VERSION..."


# Create the Pow directory structure if it doesn't already exist.

      mkdir -p "$POW_ROOT/Hosts" "$POW_ROOT/Versions"


# If the requested version of Pow is already installed, remove it first.

      cd "$POW_ROOT/Versions"
      rm -rf "$POW_ROOT/Versions/$VERSION"


# Download the requested version of Pow and unpack it.

      curl -s http://get.pow.cx/versions/$VERSION.tar.gz | tar xzf -


# Update the Current symlink to point to the new version.

      cd "$POW_ROOT"
      rm -f Current
      ln -s Versions/$VERSION Current


# Create the ~/.pow symlink if it doesn't exist.

      cd "$HOME"
      [[ -a .pow ]] || ln -s "$POW_ROOT/Hosts" .pow


# Install local configuration files.

      echo "*** Installing local configuration files..."
      "$POW_BIN/pow" --install-local


# Check to see whether we need root privileges.

      "$POW_BIN/pow" --install-system --dry-run >/dev/null && NEEDS_ROOT=0 || NEEDS_ROOT=1


# Install system configuration files, if necessary. (Avoid sudo otherwise.)

      if [ $NEEDS_ROOT -eq 1 ]; then
        echo "*** Installing system configuration files as root..."
        sudo "$POW_BIN/pow" --install-system
        sudo launchctl load -Fw /Library/LaunchDaemons/cx.pow.firewall.plist 2>/dev/null
      fi


# Start (or restart) powd.

      echo "*** Starting the Pow server..."
      launchctl unload "$HOME/Library/LaunchAgents/cx.pow.powd.plist" 2>/dev/null || true
      launchctl load -Fw "$HOME/Library/LaunchAgents/cx.pow.powd.plist" 2>/dev/null

      echo "*** Installed"
      echo
      echo "For troubleshooting instructions, please see the Pow wiki:"
      echo "https://github.com/37signals/pow/wiki/Troubleshooting"
