#!/bin/bash
BASEDIR=$(git rev-parse --show-toplevel)
DESTDIR=${BASEDIR}/wiki
EXCLUDE="TODO|README.wiki|.wiki.log|EUCA-....|Home.wiki|README.md"
EXCLUDE_SUFFIX="pdf|zip|wsdl|git|puml|keep"
EXCLUDE_DIRS="/bin/|/releases/|/lib/|/wiki/|/.git"

echo > ${BASEDIR}/.wiki.log
FILELIST=$(cd ${BASEDIR}; 
find .  -type f  | 
egrep -v '^./wiki' | 
egrep -v "${EXCLUDE}" | 
egrep -v "\.(${EXCLUDE_SUFFIX})$" |
egrep -v "${EXCLUDE_DIRS}"
)
(cd ${DESTDIR}; git checkout master)
for f in  $(echo "${FILELIST}" | sed 's/^\.\///g'); do
  dir=$(dirname ${f//features\//})
  file=$(basename $f)
  t=${dir//\//-}
  dest=${DESTDIR}/$t
  echo "$f => ${dir}/${file} ($t)"
  cp -fv ${BASEDIR}/$f ${DESTDIR}/${dir//\//-}-${file} >> ${BASEDIR}/.wiki.log | tee ${BASEDIR}/.wiki.log 2>&1
done
cp -fv ${BASEDIR}/features/Home.wiki ${DESTDIR}/Home.wiki >> ${BASEDIR}/.wiki.log 2>&1
(cd ${DESTDIR}; git add ./*; git status -sb; git commit -m 'updated'; git push) | tee ${BASEDIR}/.wiki.log 2>&1
(git add ${DESTDIR}; git commit -m 'update wiki'; git push)  | tee ${BASEDIR}/.wiki.log 2>&1
