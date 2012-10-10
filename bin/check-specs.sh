#!/bin/bash
TOP=$(git rev-parse --show-toplevel)
source ${TOP}/lib/shell-colors
REQUIRED="overview.wiki architecture.wiki confluence.url theme.jira"
OPTIONAL="references.wiki feature-xrefs.wiki"
GENERATED="references-docs.wiki"
REQUIRED_RLS="overview.wiki constraints.wiki epic.jira theme.jira"
OPTIONAL_RLS="labels.jira references.wiki feature-xrefs.wiki"
GENERATED_RLS="references-docs.wiki functional.wiki"

function check_dir() {
  MISSING=""
  EMPTY=""
  OK=""
  FEATUREDIR=$1
  FEATURE=$(echo "$1" | awk -F/ '{print $2}')
  RELEASE=$(echo "$1" | awk -F/ '{print $3}')
  if [ -n "${RELEASE}" ];then
    FEATURE="${FEATURE}/${RELEASE}"
  fi
  shift
  REQ=$@
  for part in ${REQ}; do
    file=${FEATUREDIR}/$part
    if [ ! -e $file  ]; then
      MISSING="${MISSING} $part"
    elif ! egrep '..*' $file >/dev/null 2>&1; then
      EMPTY="${EMPTY} $part"
    else
      OK="${OK} $part"
    fi
  done
  if [ -n "${MISSING}" ]; then
    printf "${fstring}" "${FEATURE}" "${CE_LightRed}missing${CE_Reset}" "${MISSING}"
  fi
  if [ -n "${EMPTY}" ]; then
    printf "${fstring}" "${FEATURE}" "${CE_Yellow}empty${CE_Reset}" "${EMPTY}"
  fi
  if [ -z "${MISSING}" ] && [ -z "${EMPTY}" ]; then
    printf "${fstring}" "${FEATURE}" "${CE_LightGreen}OK${CE_Reset}" "${OK}"
  fi 
}


CHECK_FEATURES=${@:-features/\*}
(cd ${TOP}
  fstring="%-20.20s %-20.20b %s\n"
  for featuredir in ${CHECK_FEATURES}; do
  check_dir $featuredir $REQUIRED
  if [ -e $featuredir/?.? ]; then 
    for releasedir in $featuredir/?.?; do
      check_dir $releasedir $REQUIRED_RLS
    done
  fi
  done
)
