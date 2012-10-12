#!/bin/bash
BASEDIR=$(git rev-parse --show-toplevel)
TMPDIR=${BASEDIR}/wiki
echo > ${BASEDIR}/.wiki.log
for f in $(cd ${BASEDIR}; find .  -type f  | egrep -v '*\.(pdf|zip|wsdl|git|/\.|/bin/|/releases/|/lib/|.keep|TODO|README.wiki)' | sed 's/^\.\///g'); do 
  t="${f//\//:}"
  if diff ${BASEDIR}/$f $t 2>&1 >/dev/null; then
    cp -fv ${BASEDIR}/$f ${TMPDIR}/$t >> ${BASEDIR}/.wiki.log >> ${BASEDIR}/.wiki.log 2>&1
  fi
done
cp -fv ${BASEDIR}/README.wiki ${TMPDIR}/Home.wiki >> ${BASEDIR}/.wiki.log 2>&1
(cd ${TMPDIR}; git status -sb)
(cd ${TMPDIR}; git add *; git commit -m 'updated'; git push) >> ${BASEDIR}/.wiki.log 2>&1
(git add ${TMPDIR}; git commit -m 'update wiki'; git push) >> ${BASEDIR}/.wiki.log 2>&1
