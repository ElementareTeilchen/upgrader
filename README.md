This extension is a boilerplate to organize all necessary upgrade steps to bring TYPO3 Installations from 6.2 to 8.7.

Beware:  this is ONLY A BOILERPLATE which needs individual adaptions for each projects.

Basically - if you did all the adaptions - you can then just run a bash script to do the complete upgrade.

    bash ./web/typo3conf/ext/upgrader/6to8/migrate.sh dbdump.sql keyForCurrentMachine
    
Script Parameters:

- Path to your DB dump
- Key for machine environment (like devFranz): This is used currently in the naming of some sql-command-files to allow different things on different machines.
 
You can use the script to run firstly several times on your dev machine until all looks good, then on the staging maschine, and finally for the live upgrade, where you can be pretty sure that all will work well (and fast).

The Xclasses are there to avoid that the upgrade script dies just because of problematic data in DB. We try to catch such exceptions and write them to a log file.