This extension is a boilerplate to organize all necessary upgrade steps to bring TYPO3 Installations to higher levels. Thanks to Helmut Hummel for his great EXT:typo3_console, which is heavily used here.

Beware:  this is ONLY A BOILERPLATE which needs individual adaptions for each projects.

Basically - if you did all the adaptions - you can then just run a bash script to do the complete upgrade. We currently support several upgrade variants, more are coming.

    bash ./web/typo3conf/ext/upgrader/6to8/migrate.sh -d dbdump.sql -s keyForCurrentMachine
    bash ./web/typo3conf/ext/upgrader/7to10/migrate.sh -d dbdump.sql -s keyForCurrentMachine
    
Script Parameters:

-d (relative) path to your DB dump  
-s Key for machine environment (like devFranz): This is used currently in the naming of some sql-command-files to allow different things on different machines.  
-p path to your project root, if you want to bring that in as parameter from another script
 
You can use the script to run firstly several times on your dev machine until all looks good, then on the staging machine, and finally for the live upgrade, where you can be pretty sure that all will work well (and fast).

The Xclasses are there to avoid that the upgrade script dies just because of problematic data in DB. We try to catch such exceptions and write them to a log file.

# Questions and answers

We welcome pull requests also for this little documentation, if you have questions or experiences you want to share.

## Which upgrades can be tackled with this extension
The current version is optimized for upgrades to v10. If you want to run an upgrade to v8, you will probably need to swap in composer_v8.json. Also check ext_localconf.php if you want to activate stuff there.

* 6to8: our most tested variant
* 7to8: worked for some project, very similar to 6to8
* 7to10: already used for some projects, using EXT:core_upgrader which was developed by @IchHabRecht for us
* 8to10: we are working on that and will use it for several projects, stay tuned  

## What about upgrading from 4.5?

We did not try integrating necessary steps for upgrading from 4.5. Since we run the script only from within a working TYPO3 8 with PHP7, we would expect some problems with the upgrade-wizards in 6.2. Especially the FAL-Migration is a huge task there.
We are willing to do some evaluation and try to find solutions there if enough people are in need of this step and we can raise enough funds.   
If you already have scripted solutions for this step, we appreciate pull requests.

## How is the best procedure for organizing an upgrade with this extension
Check out https://docs.typo3.org/m/typo3/guide-installation/master/en-us/Upgrade/Index.html

Since we try to tackle also upgrades with more than one version up, here is how we suggest to do:  
* Clone your existing project (new DB, new folder)
* leave DB-dump for later use, you will probably have to run the script several times until all is fine
* uninstall all local extensions (from typo3conf/ext)
* switch to your new TYPO3 version with composer, see https://docs.typo3.org/m/typo3/guide-installation/master/en-us/Composer/Index.html 
* upgrade and install all local extensions to versions which are compatible to your new TYPO3 version. You can also add upgraded extensions later on, if you want to try the upgrader as soon as possible.
* install EXT:upgrader (copy it from https://github.com/elementareteilchen/upgrader)
* work through what you need to change in your specific project for migrate.sh to run smoothly. See sql-files to get some ideas. We plan to add more examples from what we had to do in different projects to give more ideas how things can be done.
* run the migration with the original sql dump (so far we never needed to set back the filestructure i.e. in fileadmin, no changes there - you could do that with rsync if needed)
* fix what went wrong and re-run the script, again with the original sql dump
