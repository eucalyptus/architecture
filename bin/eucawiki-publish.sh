#!/bin/bash
BASEDIR=$(git rev-parse --show-toplevel)
UUID=$(uuidgen)
git remote -v add ${UUID} https://github.com/eucalyptus/eucalyptus.wiki.git
git fetch -k ${UUID}
( cd ${BASEDIR}/features
  WIKIFILES=$(find . -name \*.eucawiki)
  for f in ${WIKIFILES}; do
    WIKIFILE="$(echo $f | sed 's/.eucawiki$//g')"
    FEATURE=$(basename $(dirname ${WIKIFILE}))
    unset VERSION
    if [[ ! -e ${BASEDIR}/features/${FEATURE} ]]; then
      VERSION=${FEATURE}
      FEATURE=$(basename $(dirname $(dirname ${WIKIFILE})))
    fi
    EUCAWIKIFILE=$(basename ${WIKIFILE})
    HASH=$(cd ${BASEDIR}; git ls-tree ${UUID}/master ${EUCAWIKIFILE}|awk '{print $3}')
    echo "Fetching eucawiki: ${EUCAWIKIFILE} -> ${WIKIFILE} (${HASH})"
    git cat-file blob ${HASH} > ${WIKIFILE}
    echo >> ${WIKIFILE}
    echo "[[tag:${FEATURE}]]" >> ${WIKIFILE}
    if [[ -n "${VERSION}" ]]; then
      echo "[[tag:rls-${VERSION}]]" >> ${WIKIFILE}
    fi
  done    
)
git remote -v rm ${UUID}
