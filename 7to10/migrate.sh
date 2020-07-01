#!/bin/bash

SCRIPT_DIR=`realpath $(dirname $0)`
# depending on where you have your local extensions, you need to adapt the path here
# this is working out of the box, if you follow
# https://docs.typo3.org/m/typo3/guide-installation/master/en-us/MigrateToComposer/BestPractices.html
# this might be overwritten in call from upgrade scripts on online runs
PROJECT_ROOT=`realpath "${SCRIPT_DIR}/../../../"`

# check if we are in composer mode
if [[ -d "${PROJECT_ROOT}/vendor/bin" ]]; then
    COMPOSER_MODE=true
else
    COMPOSER_MODE=false
fi

if [ "${COMPOSER_MODE}" = true ]; then
    TYPO3_CONSOLE_BIN='./vendor/bin/typo3cms'
    TYPO3_CORE_BIN='./vendor/bin/typo3'
else
    TYPO3_CONSOLE_BIN='./web/typo3cms'
    TYPO3_CORE_BIN='./web/typo3/sysext/core/bin/typo3'
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

# first flush cache hardcoded
echo -e "* rm -fr var/cache/*;"
rm -fr var/cache/*;

# if valid path to db dump is given, initialize DB with this dump
if [ -f "${PROJECT_ROOT}/$dumpFile" ]; then
    echo -e "* resetting database, drop all tables"
    echo "show tables" | ${TYPO3_CONSOLE_BIN} database:import | grep -v Tables_in | grep -v "+" | awk '{print "SET FOREIGN_KEY_CHECKS = 0;drop table " $1 ";"}' | ${TYPO3_CONSOLE_BIN} database:import
    echo -e "* resetting database, import old DB, this can take a while (and modify for local dev machines, if needed)"
    ${TYPO3_CONSOLE_BIN} database:import < "${PROJECT_ROOT}/$dumpFile"

    # check if the parameter was given to run the specific local sql script
    if [ ! -z "$machineSpecificSql" ]; then
        ${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/projectspecific/prepareDev_$machineSpecificSql.sql"
    fi;

else
    echo -e "* use existing database for this migration, since no dump file is given as parameter"
fi;

# need to fix stuff in DB for most typo3cms commands to run properly
echo -e "* fix blocking DB issues, delete some old data"
${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/common/preUpgradeRun.sql"

echo -e "* drop obsolete cache tables starting with cf_"
echo "show tables like 'cf_%'" | ${TYPO3_CONSOLE_BIN} database:import | grep -v Tables_in | grep -v "+" | awk '{print "drop table " $1 ";"}' | ${TYPO3_CONSOLE_BIN} database:import

# make sure we do the initial upgrade stuff again, no matter where current DB comes from
echo -e "* re-activate initial upgrade step"
${TYPO3_CONSOLE_BIN} configuration:remove EXTCONF/helhum-typo3-console/initialUpgradeDone --force

#echo -e "* reduces sys_log"
${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/common/reduceSysLog.sql"

echo -e "* prepare site configuration"
${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/common/sitePreparation.sql"

echo -e "* run DB compare"
${TYPO3_CONSOLE_BIN} database:updateschema "safe"

echo -e "* dumpautoload"
if [ "${COMPOSER_MODE}" = true ]; then
    composer dumpautoload;
else
    ${TYPO3_CORE_BIN} dumpautoload
fi

echo -e "* flush cache"
${TYPO3_CONSOLE_BIN} -q cache:flush

echo -e "* quitely activate core extensions we definitely want to have (just to be sure they are installed properly)"
${TYPO3_CORE_BIN} extension:activate -q lowlevel
${TYPO3_CORE_BIN} extension:activate -q tstemplate
${TYPO3_CORE_BIN} extension:activate -q reports
${TYPO3_CORE_BIN} extension:activate -q recycler
${TYPO3_CORE_BIN} extension:activate -q opendocs
${TYPO3_CORE_BIN} extension:activate -q info
${TYPO3_CORE_BIN} extension:activate -q belog
${TYPO3_CORE_BIN} extension:activate -q beuser
${TYPO3_CORE_BIN} extension:activate -q setup
${TYPO3_CORE_BIN} extension:activate -q rte_ckeditor
${TYPO3_CORE_BIN} extension:activate -q setup
${TYPO3_CORE_BIN} extension:activate -q viewpage
${TYPO3_CORE_BIN} extension:activate -q fluid_styled_content
echo -e "** fill your extensions here"
# required by EXT:news
#${TYPO3_CORE_BIN} extension:activate -q scheduler

echo -e "* quitely activate local extensions we definitely want to have (just to be sure they are installed properly)"
${TYPO3_CORE_BIN} extension:activate -q upgrader
echo -e "** fill your extensions here"

echo -e "* set wanted stuff in LocalConfiguration.php"
${TYPO3_CONSOLE_BIN} configuration:set SYS/features/fluidBasedPageModule true

#${TYPO3_CONSOLE_BIN} configuration:set FE/cHashExcludedParameters "L, pk_campaign, pk_kwd, utm_source, utm_medium, utm_campaign, utm_term, utm_content,tx_news_pi1[overwriteDemand][categories]"

# you might need to fix some glitches before running the wizards
#${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/projectspecific/contentElementsPreWizard.sql"

echo -e "* run upgrade wizards - core"
${TYPO3_CONSOLE_BIN} coreupgrader:upgrade

echo -e "* re-run upgrade wizards which need confirmations"
${TYPO3_CONSOLE_BIN} upgrade:run separateSysHistoryFromLog --no-interaction --confirm all
${TYPO3_CONSOLE_BIN} upgrade:run cshmanualBackendUsers --no-interaction --confirm all
${TYPO3_CONSOLE_BIN} upgrade:run pagesLanguageOverlay --no-interaction --confirm all
${TYPO3_CONSOLE_BIN} upgrade:run pagesLanguageOverlayBeGroupsAccessRights --no-interaction --confirm all
${TYPO3_CONSOLE_BIN} upgrade:run pagesSlugs --no-interaction --confirm all
${TYPO3_CONSOLE_BIN} upgrade:run backendUsersConfiguration --no-interaction --confirm all
# this wizard is only informing - doing nothing
${TYPO3_CONSOLE_BIN} upgrade:run argon2iPasswordHashes --no-interaction --confirm all
${TYPO3_CONSOLE_BIN} upgrade:run databaseRowsUpdateWizard --no-interaction --confirm all

echo -e "* run upgrade wizards - extensions"
echo -e "** fill your extensions here"


# simpler things can be done via sql
echo -e "* run sql scripts for simpler migration stuff"
echo -e "** run: sys_template.sql"
${TYPO3_CONSOLE_BIN} database:import < "${SCRIPT_DIR}/sql/projectspecific/sys_template.sql"

echo -e "* alter all remaining myisam -> innodb"
echo "show table status where Engine='MyISAM';" | ${TYPO3_CONSOLE_BIN} database:import | awk 'NR>1 {print "ALTER TABLE "$1" ENGINE = InnoDB;"}' | ${TYPO3_CONSOLE_BIN} database:import

echo -e "* check if a wizard is still missing - add it to the script a few lines above"
${TYPO3_CONSOLE_BIN} upgrade:list

echo -e "* uninstall EXT:upgrader"
${TYPO3_CORE_BIN} extension:deactivate -q upgrader

#echo -e "* temporarily add admin user in case online users are unknown or not available locally"
#${TYPO3_CORE_BIN} backend:createadmin admin your..fancy..pwd

echo -e "* exit for now, we suggest to run full script as soon as all extensions are ready and you start with the final iterations"
exit;

echo -e "* update the reference index - might take a while"
${TYPO3_CORE_BIN} -q referenceindex:update

# activate only if we are pretty sure all is fine (after several successful migrations)
echo -e "* database:updateschema destructive"
# first time rename to zzz_deleted
${TYPO3_CONSOLE_BIN} database:updateschema "destructive"
# second time really drop
${TYPO3_CONSOLE_BIN} database:updateschema -v "destructive"

#echo -e "* and finally cleanup DB, done in fullMigration.sh"
#bash ${SCRIPT_DIR}/cleanup.sh
