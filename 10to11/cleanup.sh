#!/bin/bash
# stop script run when error occurs
set -euo pipefail

# use beginning with 8LTS, see typo3_src/typo3/sysext/lowlevel/README.rst

SCRIPT_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
# depending on where you have your local extensions, you need to adapt the path here
# this is working out of the box, if you follow
# https://docs.typo3.org/m/typo3/guide-installation/master/en-us/MigrateToComposer/BestPractices.html
PROJECT_ROOT=`readlink -f "${SCRIPT_DIR}/../../../"`
TYPO3_CORE_BIN='./vendor/bin/typo3'

echo -e '* start cleanup in ${PROJECT_ROOT}'

date
echo -e '** cleanup:deletedrecords'
echo -e 'for big so far badly maintained systems right upfront: start with deleted to get rid of those deleted records. Nearly all other tasks start with full pagetree (including deleted records)';
${TYPO3_CORE_BIN} -q cleanup:deletedrecords
date

# now as suggested in typo3_src/typo3/sysext/lowlevel/README.rst
echo -e '** cleanup:orphanrecords'
${TYPO3_CORE_BIN} -q cleanup:orphanrecords
date

echo -e '** cleanup:multiplereferencedfiles --update-refindex'
${TYPO3_CORE_BIN} -q cleanup:multiplereferencedfiles --update-refindex
date

echo -e '** cleanup:deletedrecords'
${TYPO3_CORE_BIN} -q cleanup:deletedrecords
date


echo -e '** cleanup:missingrelations --update-refindex'
${TYPO3_CORE_BIN} -q cleanup:missingrelations --update-refindex
date

echo -e '** cleanup:flexforms'
${TYPO3_CORE_BIN} -q cleanup:flexforms
date

# just point out missing files, but do NOT remove reference to it
echo -e '** cleanup:missingfiles --dry-run --update-refindex'
${TYPO3_CORE_BIN} -q cleanup:missingfiles --dry-run --update-refindex
date

echo -e '** cleanup:lostfiles --update-refindex'
${TYPO3_CORE_BIN} -q cleanup:lostfiles --update-refindex
date

# and again in case the above commands freeed some more stuff
echo -e '** cleanup:orphanrecords'
${TYPO3_CORE_BIN} -q cleanup:orphanrecords
date

echo -e '** cleanup:deletedrecords'
${TYPO3_CORE_BIN} -q cleanup:deletedrecords
date

echo -e '** done!!!'
