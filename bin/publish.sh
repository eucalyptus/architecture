#!/bin/bash
BASEDIR=$(git rev-parse --show-toplevel)
TMPDIR=${BASEDIR}/wiki
echo > ${BASEDIR}/.wiki.log
for f in $(cd ${BASEDIR}; find .  -type f  | egrep -v '^./wiki' | egrep -v '*\.(pdf|zip|wsdl|git|/\.|/bin/|/releases/|/lib/|.keep|TODO|README.wiki)' | sed 's/^\.\///g'); do
  echo $f 
  mkdir -p ${TMPDIR}/$(dirname $f)
  rsync -avP ${BASEDIR}/$f ${TMPDIR}/$f >> ${BASEDIR}/.wiki.log >> ${BASEDIR}/.wiki.log 2>&1
done
cp -fv ${BASEDIR}/README.wiki ${TMPDIR}/Home.wiki >> ${BASEDIR}/.wiki.log 2>&1
(cd ${TMPDIR}; git add *; git status -sb; git commit -m 'updated'; git push) >> ${BASEDIR}/.wiki.log 2>&1
(git add ${TMPDIR}; git commit -m 'update wiki'; git push) >> ${BASEDIR}/.wiki.log 2>&1
