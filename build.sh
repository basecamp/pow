#!/bin/sh

set -e
BRANCH="${BRANCH:-master}"

git show "${BRANCH}:MANUAL.md" |
./mdtoc.rb |
markdown |
ruby -e 'puts IO.read("manual.html").sub(/(<!--begin-->).*?(<!--end-->)/m) { $1 + $<.read + $2 }' \
> manual.tmp.html

mv manual.tmp.html manual.html
