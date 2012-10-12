#!/bin/bash
BASEDIR=$(git rev-parse --show-toplevel)
TMPDIR=${BASEDIR}/wiki
EXCLUDE="TODO|README.wiki|.wiki.log|EUCA-....|Home.wiki"
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
for f in  $(echo "${FILELIST}" | sed 's/^\.\///g'); do
	t=:${f//\//:}
	t=${t//features:/}
	dest=${TMPDIR}/$(dirname ${t//://})/$t
	dest_img=${TMPDIR}/$(dirname ${f//features/})/$(basename $f)
  echo "$f => $dest ($dest_img)"
  mkdir -p $(dirname $dest)
  cp -fv ${BASEDIR}/$f ${TMPDIR}/$dest >> ${BASEDIR}/.wiki.log >> ${BASEDIR}/.wiki.log 2>&1
	if file ${BASEDIR}/$f | grep image >/dev/null 2>&1; then
		cp -fv ${BASEDIR}/$f ${TMPDIR}/$dest >> ${BASEDIR}/.wiki.log >> ${BASEDIR}/.wiki.log 2>&1
	fi
done
cp -fv ${BASEDIR}/Home.wiki ${TMPDIR}/Home.wiki >> ${BASEDIR}/.wiki.log 2>&1
(cd ${TMPDIR}; git add *; git status -sb; git commit -m 'updated'; git push) | tee ${BASEDIR}/.wiki.log 2>&1
(git add ${TMPDIR}; git commit -m 'update wiki'; git push) >> ${BASEDIR}/.wiki.log 2>&1
