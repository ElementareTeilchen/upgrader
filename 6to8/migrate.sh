#!/bin/bash

# hier kommt alles rein, was direkt die Migration von 6.2LTS auf 8LTS betrifft

if [ -z "$2" ]; then
    echo -e "----------------------------------------------------------------------------------------------"
    echo -e " MIND: for dev runs you can give a second parameter (matching a filename) to run machine specific sql"
    echo -e " like typo3conf/ext/upgrader/6to8/migrate.sh prj7"
    echo -e " but make sure your sql file is there"
    echo -e "----------------------------------------------------------------------------------------------"
fi;

SCRIPT_DIR=`realpath $(dirname $0)`
PROJECT_ROOT=`realpath "${SCRIPT_DIR}/../../../../"`

# change to PROJECT_DIR. So we can use the typo3cms commands also on commandline
echo -e "\n=== switch from script dir (${SCRIPT_DIR}) to TYPO3 root ${PROJECT_ROOT}"
cd "${PROJECT_ROOT}"

# first flush cache directly, so that old autoloader classes are not a problem for typo3 console
rm -fr typo3temp/var/Cache/*;

# make sure we do the initial upgrade stuff again
./typo3cms configuration:remove EXTCONF/helhum-typo3-console/initialUpgradeDone true

# if db dump file is given as first parameter, reset DB with that dump
if [ -f "${PROJECT_ROOT}/$1" ]; then

    echo -e "\n=== resetting database, this can take a while"

    echo -e "\n=== resetting database, init local DB"

    if [ ! -z "$2" ]; then
        ./typo3cms database:import < "${SCRIPT_DIR}/sql/projectspecific/initLocalDb_$2.sql"
    fi;

    echo -e "\n=== resetting database, import old DB (and modify for local dev machines, if needed)"
    #zcat ${PROJECT_ROOT}/db_backup_62.sql.gz | ./typo3cms database:import
    ./typo3cms database:import < "${PROJECT_ROOT}/$1"

    # check if a parameter was given and an run corresponding sql script
    if [ ! -z "$2" ]; then
        ./typo3cms database:import < "${SCRIPT_DIR}/sql/projectspecific/prepareDev_$2.sql"
    fi;

else

    echo -e "###################################################################################################"
    echo -e "# since you did not give a (relative) path to sql-dump-file as first parameter, existing DB is used"
    echo -e "###################################################################################################"

fi;

# do some basic DB stuff to prevent exceptions
./typo3cms database:import < "${SCRIPT_DIR}/sql/common/preDbCompare.sql"

echo -e "\n=== truncate some cache tables"
./typo3cms database:import < "${SCRIPT_DIR}/sql/common/truncateSomeCacheTables.sql"

echo -e "\n=== reduces sys_log"
./typo3cms database:import < "${SCRIPT_DIR}/sql/common/reduceSysLog.sql"

echo -e "\n=== run DB compare"
./typo3cms database:updateschema safe

./typo3cms cache:flush

# migration wizards laufen lassen, alle siehe typo3_src/typo3/sysext/install/ext_localconf.php
echo -e "\n=== run upgrade wizards"
# to make sure we are running all wizards, even newly added ones, just run all with one command
# at least with 4.5.3 you need to put this parameter all in one line without space after ,
./typo3cms upgrade:all \
    compatibility6Extension[install]=0,compatibility7Extension[install]=0,rtehtmlareaExtension[install]=0,openidExtension[install]=0,DbalAndAdodbExtractionUpdate[install]=0,formLegacyExtractionUpdate[install]=0,mediaceExtension[install]=0



# simpler things can be done via sql
echo -e "\n=== run sql scripts for simpler migration stuff"
./typo3cms database:import < "${SCRIPT_DIR}/sql/projectspecific/setRights.sql"


echo -e "\n=== make sure all installed extensions are properly setup"
./typo3cms extension:setupactive

echo -e "\n=== update the reference index"
./typo3cms cleanup:updatereferenceindex

echo -e "\n=== and finally cleanup DB"
bash ${SCRIPT_DIR}/cleanup.sh

# TODO, activate after all extensions are properly updated and loaded again
# echo -e "\n=== database:updateschema destructive"
#./typo3cms database:updateschema --verbose --schema-update-types destructive