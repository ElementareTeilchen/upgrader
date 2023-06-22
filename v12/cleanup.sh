#!/bin/bash

SCRIPT_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
# depending on where you have your local extensions, you need to adapt the path here
# this is working out of the box, if you follow
# https://docs.typo3.org/m/typo3/guide-installation/master/en-us/MigrateToComposer/BestPractices.html
PROJECT_ROOT=`readlink -f "${SCRIPT_DIR}/../../../"`
TYPO3_CONSOLE_BIN='./vendor/bin/typo3'

echo -e "* start cleanup in ${PROJECT_ROOT}"

date +"%d.%m.%Y %T"
echo -e '* typo3 -q cleanup:orphanrecords'
${TYPO3_CONSOLE_BIN} -q cleanup:orphanrecords

date +"%d.%m.%Y %T"
echo -e '* cleanup:deletedrecords'
${TYPO3_CONSOLE_BIN} cleanup:deletedrecords

date +"%d.%m.%Y %T"
echo -e '* cleanup:missingrelations --update-refindex'
${TYPO3_CONSOLE_BIN} cleanup:missingrelations --update-refindex

date +"%d.%m.%Y %T"
echo -e '* typo3 -q cleanup:flexforms'
${TYPO3_CONSOLE_BIN} -q cleanup:flexforms

echo -e '** done!!!'
