#!/bin/bash
BASEDIR=$(git rev-parse --show-toplevel)
TMPDIR=${BASEDIR}/wiki
for f in $(cd ${BASEDIR}; find .  -type f  | egrep -v '*\.(pdf|zip|wsdl|git|/\.|/bin/|/releases/|/lib/)' | sed 's/^\.\///g'); do 
  t="${f//\//:}"
  if diff ${BASEDIR}/$f ${TMPDIR}/$t 2>&1 >/dev/null; then
    cp -fv ${BASEDIR}/$f ${TMPDIR}/$t
  fi
done
(cd ${TMPDIR}; git add *; git commit -m 'updated'; git push)
git add ${TMPDIR}; git commit -m 'update wiki'; git push
