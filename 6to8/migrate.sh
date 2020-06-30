#!/bin/bash

SCRIPT_DIR=`realpath $(dirname $0)`
PROJECT_ROOT=`realpath "${SCRIPT_DIR}/../../../../"`
TYPO3_BIN='${TYPO3_BIN}'
#TYPO3_BIN='./vendor/bin/typo3cms'

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

if [ -z "$machineSpecificSql" ]; then
    echo -e "----------------------------------------------------------------------------------------------"
    echo -e " MIND: for dev runs you can give a second parameter (matching a identifier used in filenames) to run machine specific sql"
    echo -e " like typo3conf/ext/upgrader/6to8/migrate.sh prj7"
    echo -e " but make sure your sql file is there. See our sql-file examples"
    echo -e "----------------------------------------------------------------------------------------------"
fi;

# in case project root is given as parameter (ie. we are called from external script which determined the correct path)
# we use that one
if [ ! -z "$projectRoot" ]; then
    PROJECT_ROOT="$projectRoot"
fi;

# change to PROJECT_DIR. So we can use the typo3cms commands also on commandline
echo -e "\n=== switch from script dir (${SCRIPT_DIR}) to TYPO3 root ${PROJECT_ROOT}"
cd "${PROJECT_ROOT}"

# first flush cache directly, so that old autoloader classes are not a problem for typo3 console
rm -fr typo3temp/var/Cache/*;

# make sure we do the initial upgrade stuff again
${TYPO3_BIN} configuration:remove EXTCONF/helhum-typo3-console/initialUpgradeDone --force

# if db dump file is given as first parameter, reset DB with that dump
if [ -f "${PROJECT_ROOT}/$dumpFile" ]; then

    echo -e "\n=== resetting database, this can take a while"

    echo -e "\n=== resetting database, drop all tables"
    echo "show tables" | ${TYPO3_BIN} database:import | grep -v Tables_in | grep -v "+" | awk '{print "SET FOREIGN_KEY_CHECKS = 0;drop table " $1 ";"}' | ${TYPO3_BIN} database:import

    #zcat ${PROJECT_ROOT}/db_backup_62.sql.gz | ${TYPO3_BIN} database:import
    ${TYPO3_BIN} database:import < "${PROJECT_ROOT}/$dumpFile"

    # check if a parameter was given and an run corresponding sql script
    if [ ! -z "$machineSpecificSql" ]; then
        echo -e "\n=== modify for local dev machines, if needed"
        ${TYPO3_BIN} database:import < "${SCRIPT_DIR}/sql/projectspecific/prepareDev_$machineSpecificSql.sql"
    fi;

else

    echo -e "###################################################################################################"
    echo -e "# since you did not give a (relative) path to sql-dump-file as first parameter, existing DB is used"
    echo -e "###################################################################################################"

fi;

# do some basic DB stuff to prevent exceptions
${TYPO3_BIN} database:import < "${SCRIPT_DIR}/sql/common/preDbCompare.sql"

echo -e "\n=== truncate some cache tables"
${TYPO3_BIN} database:import < "${SCRIPT_DIR}/sql/common/truncateSomeCacheTables.sql"

echo -e "\n=== reduces sys_log"
${TYPO3_BIN} database:import < "${SCRIPT_DIR}/sql/common/reduceSysLog.sql"

echo -e "\n=== run DB compare"
${TYPO3_BIN} database:updateschema safe

${TYPO3_BIN} cache:flush

# migration wizards laufen lassen, alle siehe typo3_src/typo3/sysext/install/ext_localconf.php
echo -e "\n=== run upgrade wizards"
# to make sure we are running all wizards, even newly added ones, just run all with one command
# at least with 4.5.3 you need to put this parameter all in one line without space after ,
${TYPO3_BIN} upgrade:all \
    --arguments=compatibility6Extension[install]=0,compatibility7Extension[install]=0,rtehtmlareaExtension[install]=0,openidExtension[install]=0,DbalAndAdodbExtractionUpdate[install]=0,formLegacyExtractionUpdate[install]=0,mediaceExtension[install]=0



# simpler things can be done via sql
echo -e "\n=== run sql scripts for simpler migration stuff"
${TYPO3_BIN} database:import < "${SCRIPT_DIR}/sql/projectspecific/setRights.sql"


echo -e "\n=== make sure all installed extensions are properly setup"
${TYPO3_BIN} extension:setupactive

echo -e "\n=== update the reference index"
${TYPO3_BIN} cleanup:updatereferenceindex

echo -e "\n=== and finally cleanup DB"
bash ${SCRIPT_DIR}/cleanup.sh

# TODO, activate after all extensions are properly updated and loaded again
# echo -e "\n=== database:updateschema destructive"
#${TYPO3_BIN} database:updateschema --verbose --schema-update-types destructive