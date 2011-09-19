#!/bin/sh -e
# `./build.sh` generates dist/$VERSION.tar.gz
# `./build.sh --install` installs into ~/Library/Application Support/Pow/Current

VERSION=$(node -e 'JSON.parse(require("fs").readFileSync("package.json","utf8")).version')
ROOT="/tmp/pow-build.$$"
DIST="$(pwd)/dist"

cake build

mkdir -p "$ROOT/$VERSION/node_modules"
cp -R package.json bin lib "$ROOT/$VERSION"
cp Cakefile "$ROOT/$VERSION"
cd "$ROOT/$VERSION"
BUNDLE_ONLY=1 npm install >/dev/null
cp `which node` bin

if [ "$1" == "--install" ]; then
  POW_ROOT="$HOME/Library/Application Support/Pow"
  rm -fr "$POW_ROOT/Versions/9999.0.0"
  mkdir -p "$POW_ROOT/Versions"
  cp -R "$ROOT/$VERSION" "$POW_ROOT/Versions/9999.0.0"
  rm -f "$POW_ROOT/Current"
  cd "$POW_ROOT"
  ln -s Versions/9999.0.0 Current
  echo "$POW_ROOT/Versions/9999.0.0"
else
  cd "$ROOT"
  tar czf "$VERSION.tar.gz" "$VERSION"
  mkdir -p "$DIST"
  cd "$DIST"
  mv "$ROOT/$VERSION.tar.gz" "$DIST"
  echo "$DIST/$VERSION.tar.gz"
fi

rm -fr "$ROOT"
