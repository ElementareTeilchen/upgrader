#!/bin/bash

SCRIPT_DIR=`realpath $(dirname $0)`
# this is overwritten in call from upgrade scripts on online runs
PROJECT_ROOT=`realpath "${SCRIPT_DIR}/../../../../"`

# check if we are in composer mode (used locally at ET)
if [[ -d "${PROJECT_ROOT}/vendor/bin" ]]; then
    COMPOSER_MODE=true
else
    COMPOSER_MODE=false
fi

if [ "${COMPOSER_MODE}" = true ]; then
    TYPO3_CONSOLE_BIN='./vendor/bin/typo3cms'
else
    TYPO3_CONSOLE_BIN='./typo3cms'
fi

# first get named parameters (only 1 character possible), see https://unix.stackexchange.com/questions/129391/passing-named-arguments-to-shell-scripts
while getopts ":d:r:s:" opt; do
  case $opt in
    d) dumpFile="$OPTARG"
    ;;
    r) projectRoot="$OPTARG"
    ;;
    s) machineSpecificSql="$OPTARG"
    ;;
    \?) echo "option -$OPTARG not given" >&2
    ;;
  esac
done


# in case project root is given as parameter (ie. we are called from external script which determined the correct path)
# we use that one
if [ ! -z "$projectRoot" ]; then
    PROJECT_ROOT="$projectRoot"
fi;


# change to PROJECT_DIR. So we can use the typo3cms commands also on commandline
echo -e "* switch to TYPO3 root"
cd "${PROJECT_ROOT}"


# first flush cache directly, so that old autoloader classes are not a problem for typo3 console
rm -fr typo3temp/var/Cache/*;

#${TYPO3_CONSOLE_BIN} install:generatepackagestates

# make sure we do the initial upgrade stuff again
${TYPO3_CONSOLE_BIN} configuration:remove EXTCONF/helhum-typo3-console/initialUpgradeDone --force

# if valid path to db dump is given, initialize DB with this dump
if [ -f "${PROJECT_ROOT}/$dumpFile" ]; then
    echo -e "* resetting database, drop all tables"
    echo "show tables" | ${TYPO3_CONSOLE_BIN} database:import | grep -v Tables_in | grep -v "+" | awk '{print "SET FOREIGN_KEY_CHECKS = 0;drop table " $1 ";"}' | ${TYPO3_CONSOLE_BIN} database:import

    echo -e "* resetting database, import old DB, this can take a while (and modify for local dev machines, if needed)"
    ${TYPO3_CONSOLE_BIN} database:import < "${PROJECT_ROOT}/$dumpFile"

    # check if a parameter was given and an run corresponding sql script
    if [ ! -z "$machineSpecificSql" ]; then
        ${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/projectspecific/prepareDev_$machineSpecificSql.sql"
    fi;

else
    echo -e "* use existing database for this migration, since no dump file is given as parameter"
fi;


echo -e "* do some basic DB stuff to prevent exceptions"
${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/common/preDbCompare.sql"

echo -e "* truncate some cache tables"
${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/common/truncateSomeCacheTables.sql"

echo -e "* reduces sys_log"
${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/common/reduceSysLog.sql"

echo -e "* run DB compare"
${TYPO3_CONSOLE_BIN} database:updateschema safe

${TYPO3_CONSOLE_BIN} cache:flush

# migration wizards laufen lassen, alle siehe typo3_src/typo3/sysext/install/ext_localconf.php
echo -e "* run upgrade wizards"
# to make sure we are running all wizards, even newly added ones, just run all with one command
# at least with 4.5.3 you need to put this parameter all in one line without space after ,
${TYPO3_CONSOLE_BIN} upgrade:all \
    --arguments=compatibility6Extension[install]=0,compatibility7Extension[install]=0,rtehtmlareaExtension[install]=0,openidExtension[install]=0,DbalAndAdodbExtractionUpdate[install]=0,formLegacyExtractionUpdate[install]=0,mediaceExtension[install]=0



# simpler things can be done via sql
echo -e "* run sql scripts for simpler migration stuff"
#${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/projectspecific/setRights.sql"


echo -e "* make sure all installed extensions are properly setup"
${TYPO3_CONSOLE_BIN} extension:setupactive

echo -e "* install language packs"
${TYPO3_CONSOLE_BIN} language:update

echo -e "* update the reference index"
${TYPO3_CONSOLE_BIN} cleanup:updatereferenceindex
