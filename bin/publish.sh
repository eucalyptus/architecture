#!/bin/bash
BASEDIR=$(git rev-parse --show-toplevel)
DESTDIR=${BASEDIR}/wiki
EXCLUDE="TODO|README.wiki|.wiki.log|EUCA-....|Home.wiki|README.md"
EXCLUDE_SUFFIX="pdf|zip|wsdl|git|puml|keep|notes.wiki"
EXCLUDE_DIRS="/bin/|/releases/|/lib/|/wiki/|/.git"

echo > ${BASEDIR}/.wiki.log
FILELIST=$(cd ${BASEDIR}; 
find features  -type f  | 
egrep -v '^./wiki' | 
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
  echo "$f => ${dir}/${file} ($t)"
	if echo $f | egrep "\.(${EXCLUDE_SUFFIX})" &&
 		egrep '{{[^ ]*}}' $f >/dev/null 2>&1; then
		(cd $dir; 
			sed -nf ${BASEDIR}/bin/include.sed $file | sed 'N;N;s/\n//' | sed -f - $file > ${DESTDIR}/${dir//\//-}-${file}
			)
	else
  	cp -fv ${BASEDIR}/$f ${DESTDIR}/${dir//\//-}-${file} >> ${BASEDIR}/.wiki.log | tee ${BASEDIR}/.wiki.log 2>&1
	fi
done
(cd features; 
	sed -nf ${BASEDIR}/bin/include.sed Home.wiki | sed 'N;N;s/\n//' | sed -f - Home.wiki > ${DESTDIR}/Home.wiki
	)
(cd ${DESTDIR};${BASEDIR}//bin/tag-indexer.rb  -m tags -v)
(cd ${DESTDIR}; git add ./*; git status -sb; git commit -m 'updated'; git push) | tee ${BASEDIR}/.wiki.log 2>&1
(cd ${BASEDIR}; git add wiki; git commit -a -m 'update wiki'; git push )  | tee ${BASEDIR}/.wiki.log 2>&1
