#!/bin/bash
BASEDIR=$(git rev-parse --show-toplevel)
TMPDIR=$(mktemp -d /tmp/wiki-XXXXX)
git clone --depth=1 git@github.com:EucalyptusSystems/architecture.wiki.git ${TMPDIR}
rm -rfv ${TMPDIR}/*
for f in $(cd ${BASEDIR}; find .  -type f  | egrep -v '*\.(pdf|zip|wsdl|git|/\.|/bin/|/releases/|/lib/)' | sed 's/^\.\///g'); do 
  t="${f//\//:}"
  cp -fv ${BASEDIR}/$f ${TMPDIR}/$t
done
(cd ${TMPDIR}; git add *; git commit -m 'updated'; git push)
rm -rfv ${TMPDIR}
