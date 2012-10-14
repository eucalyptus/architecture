#!/bin/bash
BASEDIR=$(git rev-parse --show-toplevel)
DESTDIR=${BASEDIR}/wiki
EXCLUDE="TODO|README.wiki|.wiki.log|EUCA-....|Home.wiki|README.md"
EXCLUDE_SUFFIX="pdf|zip|wsdl|git|puml|keep|notes.wiki"
EXCLUDE_DIRS="/bin/|/releases/|/lib/|/wiki/|/.git"
#TAGS="rls-3.0 rls-3.1 rls-3.2 rls-3.3"
TAGS="rls-3.2 rls-3.3"

echo > ${BASEDIR}/.wiki.log
FILELIST=$(cd ${BASEDIR}; 
find features  -type f  | 
egrep -v '^./wiki' | 
egrep -v './features/[^/]*.wiki' | 
egrep -v "${EXCLUDE}" | 
egrep -v "(${EXCLUDE_SUFFIX})$" |
egrep -v "${EXCLUDE_DIRS}"
)
(cd ${DESTDIR}; git checkout master)
for f in  $(echo "${FILELIST}" | sed 's/^\.\///g'); do
  dir=$(dirname ${f//features\//})
  file=$(basename $f)
  t=${dir//\//-}
  dest=${DESTDIR}/$t
#  echo "$f => ${dir}/${file} ($t)"
	if echo $f | egrep "\.(${EXCLUDE_SUFFIX})" &&
 		egrep '{{[^ ]*}}' $f >/dev/null 2>&1; then
		(cd $dir; 
			sed -nf ${BASEDIR}/bin/include.sed $file | sed 'N;N;s/\n//' | sed -f - $file > ${DESTDIR}/${dir//\//-}-${file}
			)
	else
		if grep -v 'tag:' ${DESTDIR}/${dir//\//-}-${file} | diff ${BASEDIR}/$f - >/dev/null 2>&1; then
  		cp -fv ${BASEDIR}/$f ${DESTDIR}/${dir//\//-}-${file} >> ${BASEDIR}/.wiki.log | tee ${BASEDIR}/.wiki.log 2>&1
		fi
	fi
done
for f in ${BASEDIR}/features/*.wiki; do
(cd features; 
	file=$(basename $f)
	sed -nf ${BASEDIR}/bin/include.sed $file | sed 'N;N;s/\n//' | sed -f - $file > ${DESTDIR}/$file
	)
done
for f in ${TAGS}; do
  touch ${DESTDIR}/tag:${f}.md
done
(cd ${DESTDIR};${BASEDIR}//bin/tag-indexer.rb  -m tags)
(cd ${DESTDIR}; git add ./*; git status -sb; git commit -m 'updated'; git push) 2>&1 | tee ${BASEDIR}/.wiki.log 
(cd ${BASEDIR}; git add wiki; git commit -a -m 'update wiki'; git push ) 2>&1 | tee ${BASEDIR}/.wiki.log
