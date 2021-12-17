<?php
defined('TYPO3_MODE') or die();

$boot = function () {

    // activate the xclasses in case the original UpgradeWizard dies with an Exception because some data in DB in not as expected

    // only neede for migration 6 -> 8
#    $GLOBALS['TYPO3_CONF_VARS']['SYS']['Objects']['TYPO3\\CMS\\Install\\Updates\\RowUpdater\\RteLinkSyntaxUpdater'] =
#        array('className' => 'ElementareTeilchen\\Upgrader\\Xclass\\RowUpdaterWizard\\RteLinkSyntaxUpdater');

    // probably not needed, because issue is in dataMapProcessor
#    $GLOBALS['TYPO3_CONF_VARS']['SYS']['Objects']['TYPO3\\CMS\\Install\\Updates\\RowUpdater\\L10nModeUpdater'] =
#        array('className' => 'ElementareTeilchen\\Upgrader\\Xclass\\RowUpdaterWizard\\L10nModeUpdater');

#    $GLOBALS['TYPO3_CONF_VARS']['SYS']['Objects']['TYPO3\\CMS\\Core\\DataHandling\\Localization\\DataMapProcessor'] =
#        array('className' => 'ElementareTeilchen\\Upgrader\\Xclass\\DataMapProcessor');
#    $GLOBALS['TYPO3_CONF_VARS']['SYS']['Objects']['TYPO3\\CMS\\Core\\LinkHandling\\RecordLinkHandler'] =
#        array('className' => 'ElementareTeilchen\\Upgrader\\Xclass\\RecordLinkHandler');


    // configure the TYPO3 logger to log wizards stuff to a special logfile
    // the logger sees our xclasses in the original namespace
    $GLOBALS['TYPO3_CONF_VARS']['LOG']['TYPO3']['CMS']['Install']['Updates']['writerConfiguration'] = array(
        \TYPO3\CMS\Core\Log\LogLevel::INFO => array(
            'TYPO3\\CMS\\Core\\Log\\Writer\\FileWriter' => array(
                'logFile' => \TYPO3\CMS\Core\Core\Environment::getVarPath() .'/log/upgradeWizards.log'
            )
        )
    );
};

$boot();
unset($boot);

