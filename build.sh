#!/bin/sh

VERSION=$(node -e 'JSON.parse(require("fs").readFileSync("package.json","utf8")).version')
ROOT=dist/$VERSION

npm bundle
rm -fr $ROOT
mkdir -p $ROOT/bin
cp -R lib node_modules $ROOT
cp `which node` $ROOT/bin
cp bin/pow* $ROOT/bin
cp package.json $ROOT

cd dist
tar czvf $VERSION.tar.gz $VERSION
