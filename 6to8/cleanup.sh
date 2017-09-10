#!/bin/bash

# use beginning with 8LTS, see typo3_src/typo3/sysext/lowlevel/README.rst

SCRIPT_DIR=`realpath $(dirname $0)`
PROJECT_ROOT=`realpath "${SCRIPT_DIR}/../../../../"`

echo -e '\n=== start cleanup in ${PROJECT_ROOT}'

date
echo -e '\n=== cleanup:deletedrecords'
echo -e 'for big so far badly maintained systems right upfront: start with deleted to get rid of those deleted records. Nearly all other tasks start with full pagetree (including deleted records)';
${PROJECT_ROOT}/typo3/sysext/core/bin/typo3 cleanup:deletedrecords
date

# now as suggested in typo3_src/typo3/sysext/lowlevel/README.rst
echo -e '\n=== cleanup:orphanrecords'
${PROJECT_ROOT}/typo3/sysext/core/bin/typo3 cleanup:orphanrecords
date

echo -e '\n=== cleanup:versions'
${PROJECT_ROOT}/typo3/sysext/core/bin/typo3 cleanup:versions
date

echo -e '\n=== cleanup:multiplereferencedfiles --update-refindex'
${PROJECT_ROOT}/typo3/sysext/core/bin/typo3 cleanup:multiplereferencedfiles --update-refindex
date

echo -e '\n=== cleanup:deletedrecords'
${PROJECT_ROOT}/typo3/sysext/core/bin/typo3 cleanup:deletedrecords
date


echo -e '\n=== cleanup:missingrelations --update-refindex'
${PROJECT_ROOT}/typo3/sysext/core/bin/typo3 cleanup:missingrelations --update-refindex
date

echo -e '\n=== cleanup:flexforms'
${PROJECT_ROOT}/typo3/sysext/core/bin/typo3 cleanup:flexforms
date

echo -e '\n=== cleanup:rteimages --update-refindex'
${PROJECT_ROOT}/typo3/sysext/core/bin/typo3 cleanup:rteimages --update-refindex
date

# just point out missing files, but do NOT remove reference to it
echo -e '\n=== cleanup:missingfiles --dry-run --update-refindex'
${PROJECT_ROOT}/typo3/sysext/core/bin/typo3 cleanup:missingfiles --dry-run --update-refindex
date

echo -e '\n=== cleanup:lostfiles --update-refindex'
${PROJECT_ROOT}/typo3/sysext/core/bin/typo3 cleanup:lostfiles --update-refindex
date

# and again in case the above commands freeed some more stuff
echo -e '\n=== cleanup:orphanrecords'
${PROJECT_ROOT}/typo3/sysext/core/bin/typo3 cleanup:orphanrecords
date

echo -e '\n=== cleanup:deletedrecords'
${PROJECT_ROOT}/typo3/sysext/core/bin/typo3 cleanup:deletedrecords
date

echo -e '\n=== done!!!'
