This extension is a boilerplate to organize all necessary upgrade steps to bring TYPO3 Installations to higher levels. Thanks to Helmut Hummel for his great EXT:typo3_console, which is heavily used here.

Beware:  this is ONLY A BOILERPLATE which needs individual adaptions for each projects.

Basically - if you did all the adaptions - you can then just run a bash script to do the complete upgrade. We have boilerplates for most recent TYPO3-Versions.
Since TYPO3 11 we also use versioning and keep only stuff for the latest LTS version. Check out release v10.0.0 to get all boilerplates for older TYPO3-Versions.
We suggest to use ddev for local development.
```
    # with ddev
    ddev exec bash packages/upgrader/10to11/migrate.sh -dump11.sql
    # regular console
    bash packages/upgrader/10to11/migrate.sh -dump11.sql            
```
Script Parameters:

-d (relative) path to your DB dump  
-s Key for machine environment (like devFranz): This is used currently in the naming of some sql-command-files to allow different things on different machines. Rarely needed nowadays.  
-p path to your project root, if you want to bring that in as parameter from another script
 
You can use the script to run firstly several times on your dev machine until all looks good, then on the staging machine, and finally for the live upgrade, where you can be pretty sure that all will work well (and fast).

# Questions and answers

We welcome pull requests also for this little documentation, if you have questions or experiences you want to share.

## Which upgrades can be tackled with this extension
* TYPO3 10LTS
We are using EXT:core_upgrader which was developed by @IchHabRecht for us and you.  
* TYPO3 11LTS
We removed all outdated stuff to keep the boilerplate lean and simple. Also TYPO3 Upgrade Wizards got better, less to do for us! 

## How is the best procedure for organizing an upgrade with this extension
Check out https://docs.typo3.org/m/typo3/guide-installation/11.5/en-us/Major/Index.html
We aim to run all steps mentioned there in a single script run when going live.

Since we try to tackle also upgrades with more than one version up, here is how we suggest to do:  
* Clone your existing project (new DB, new folder), very easy with ddev
* leave DB-dump for later use, you will probably have to run the script several times until all is fine
* uninstall all local extensions (from typo3conf/ext)
* switch to your new TYPO3 version with composer 
* upgrade and install all local extensions to versions which are compatible to your new TYPO3 version. You can also add upgraded extensions later on, if you want to try the upgrader as soon as possible.
* install EXT:upgrader (copy it from https://github.com/elementareteilchen/upgrader to your local package folder)
* work through what you need to change in your specific project for migrate.sh to run smoothly. See sql-files to get some ideas. We plan to add more examples from what we had to do in different projects to give more ideas how things can be done.
* run the migration with the original sql dump (so far we never needed to set back the filestructure i.e. in fileadmin, no changes there - you could do that with rsync if needed)
* fix what went wrong and re-run the script, again with the original sql dump
* if all looks good on your machine, run the script on a staging server or the soon-to-be-live environment
* if all looks good on the customer servers too, run the upgrade. We often do the following steps:
  * lock the backend for the current TYPO3
  * export db dump and rsync fileadmin to the location of the new TYPO3 version
  * `bash packages/upgrader/10to11/migrate.sh -dump11.sql | tee migration.log`
  * do stuff which still needs to be done manually, ideally nothing
  * test your new live instance
  * switch domain (or whatever you need to switch) to get the new system live
  * enjoy the praise of your customer and editors :)
