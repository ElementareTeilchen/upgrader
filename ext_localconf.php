<?php
defined('TYPO3_MODE') or die();

$boot = function () {
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

