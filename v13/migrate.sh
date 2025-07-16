#!/bin/bash
# stop script run when error occurs
set -e

SCRIPT_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
# depending on where you have your local extensions, you need to adapt the path here
# this is working out of the box, if you follow
# https://docs.typo3.org/m/typo3/guide-installation/master/en-us/MigrateToComposer/BestPractices.html
# this might be overwritten in call from upgrade scripts on online runs
projectRoot=`readlink -f "${SCRIPT_DIR}/../../../"`
phpBin=''
composerBin='composer'


# first get named parameters (only 1 character possible), see https://unix.stackexchange.com/questions/129391/passing-named-arguments-to-shell-scripts
while getopts ":d:r:s:p:c:" opt; do
  case $opt in
    d) dumpFile="$OPTARG"
    ;;
    r) projectRoot="$OPTARG"
    ;;
    p) phpBin="$OPTARG"
    ;;
    c) composerBin="$OPTARG"
    ;;
    \?) echo "option -$OPTARG not given" >&2
    ;;
  esac
done

# now use default values or given parameter
PROJECT_ROOT="${projectRoot}"
TYPO3_CONSOLE_BIN="${phpBin} ./vendor/bin/typo3"
COMPOSER_BIN="${phpBin} ${composerBin}"

# change to PROJECT_DIR to have the same commands here as you would use manually on command line
echo -e "* switch to TYPO3 root"
cd "${PROJECT_ROOT}"

# if valid path to db dump is given, initialize DB with this dump
if [ -f "${PROJECT_ROOT}/$dumpFile" ]; then
    echo -e "* resetting database, drop all tables"
    echo "show tables" | ${TYPO3_CONSOLE_BIN} database:import | grep -v Tables_in | grep -v "+" | awk '{print "SET FOREIGN_KEY_CHECKS = 0;drop table " $1 ";"}' | ${TYPO3_CONSOLE_BIN} database:import
    echo -e "* resetting database, import old DB, this can take a while (and modify for local dev machines, if needed)"
    ${TYPO3_CONSOLE_BIN} database:import < "${PROJECT_ROOT}/$dumpFile"
else
    echo -e "* use existing database for this migration, since no dump file is given as parameter"
fi;

# we might need to fix stuff in DB for commands to run properly
echo -e "* fix blocking DB issues"
${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/common/preUpgradeRun.sql"

echo -e "* drop obsolete cache tables starting with cf_"
echo "show tables like 'cf_%'" | ${TYPO3_CONSOLE_BIN} database:import | grep -v Tables_in | grep -v "+" | awk '{print "drop table " $1 ";"}' | ${TYPO3_CONSOLE_BIN} database:import

# make sure we do the initial upgrade stuff again, no matter where current DB comes from
echo -e "* re-activate initial upgrade step"
${TYPO3_CONSOLE_BIN} configuration:remove EXTCONF/helhum-typo3-console/initialUpgradeDone --force

echo -e "* reduces sys_log"
${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/common/reduceSysLog.sql"

echo -e "* run common cleanup queries"
${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/common/cleanup.sql"

echo -e "* setup all existing extensions"
${TYPO3_CONSOLE_BIN} extension:setup

echo -e "* flush/warmup cache"
${TYPO3_CONSOLE_BIN} -q cache:flush
${TYPO3_CONSOLE_BIN} -q cache:warmup

# you might need to fix some glitches before running the wizards
echo -e "* fix some glitches before running the wizards"
${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/projectspecific/preWizard.sql"

echo -e "* run upgrade wizards - core"
${TYPO3_CONSOLE_BIN} upgrade:run

# in case you want to avoid needing to interact as much as possible when running the script, try this instead of the previous line
#${TYPO3_CONSOLE_BIN} upgrade:run --no-interaction
#echo -e "* re-run upgrade wizards which need confirmations - if you want them to run"
#${TYPO3_CONSOLE_BIN} upgrade:run svgFilesSanitization

echo -e "* run upgrade wizards - extensions"
echo -e "** TODO: fill your extensions here"

# simpler things can be done via sql - the names of the files don't matter, just make sure the path is correct
echo -e "* run sql scripts for simpler migration stuff"
echo -e "** run: content.sql"
${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/projectspecific/content.sql"
echo -e "** run: rights.sql"
${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/projectspecific/rights.sql"
echo -e "** run: template.sql"
${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/projectspecific/template.sql"
#echo -e "** run: youNameIt.sql"
#${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/projectspecific/youNameIt.sql"

echo -e "* alter all remaining myisam -> innodb"
echo "show table status where Engine='MyISAM';" | ${TYPO3_CONSOLE_BIN} database:import | awk '{print "ALTER TABLE "$1" ENGINE = InnoDB;"}' | ${TYPO3_CONSOLE_BIN} database:import

echo -e "* check if a wizard is still missing - add it to the script a few lines above"
${TYPO3_CONSOLE_BIN} upgrade:list

echo -e "* update language packs"
${TYPO3_CONSOLE_BIN} language:update

#echo -e "* temporarily add admin user in case online users are unknown or not available locally"
#${TYPO3_CONSOLE_BIN} backend:createadmin admin your..fancy..pwd

echo -e "* exit for now, we suggest to run full script as soon as all extensions are ready and you start with the final iterations"
exit;

# activate only if you are pretty sure all is fine (after several successful migration runs)
echo -e "* database:updateschema destructive"
# first time rename to zzz_deleted
${TYPO3_CONSOLE_BIN} database:updateschema "destructive"
# second time really drop
${TYPO3_CONSOLE_BIN} database:updateschema -v "destructive"

echo -e "* and finally cleanup DB, might better be placed in bin/online/fullMigration.sh if you have that"
bash ${SCRIPT_DIR}/cleanup.sh
