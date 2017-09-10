<?php
declare(strict_types=0);
namespace ElementareTeilchen\Upgrader\Xclass\RowUpdaterWizard;

/*
 * This file is part of the TYPO3 CMS project.
 *
 * It is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, either version 2
 * of the License, or any later version.
 *
 * For the full copyright and license information, please read the
 * LICENSE.txt file that was distributed with this source code.
 *
 * The TYPO3 project - inspiring people to share!
 */

use TYPO3\CMS\Core\Authentication\BackendUserAuthentication;
use TYPO3\CMS\Core\Database\ConnectionPool;
use TYPO3\CMS\Core\DataHandling\DataHandler;
use TYPO3\CMS\Core\DataHandling\Localization\DataMapProcessor;
use TYPO3\CMS\Core\DataHandling\Localization\State;
use TYPO3\CMS\Core\Utility\GeneralUtility;
use TYPO3\CMS\Core\Versioning\VersionState;
use TYPO3\CMS\Lang\LanguageService;

/**
 * Migrate values for database records having columns
 * using "l10n_mode" set to "mergeIfNotBlank" or "exclude".
 */
class L10nModeUpdater extends \TYPO3\CMS\Install\Updates\RowUpdater\L10nModeUpdater
{
    /**
     * Update single row if needed
     *
     * @param string $tableName
     * @param array $inputRow Given row data
     * @return array Modified row data
     */
    public function updateTableRow(string $tableName, array $inputRow): array
    {
        $currentId = $inputRow['uid'];

        if (empty($this->payload[$tableName]['localizations'][$currentId])) {
            return $inputRow;
        }

        // disable DataHandler hooks for processing this update
        if (!empty($GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['t3lib/class.t3lib_tcemain.php'])) {
            $dataHandlerHooks = $GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['t3lib/class.t3lib_tcemain.php'];
            unset($GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['t3lib/class.t3lib_tcemain.php']);
        }

        if (empty($GLOBALS['LANG'])) {
            $GLOBALS['LANG'] = GeneralUtility::makeInstance(LanguageService::class);
        }
        if (!empty($GLOBALS['BE_USER'])) {
            $adminUser = $GLOBALS['BE_USER'];
        }
        // the admin user is required to defined workspace state when working with DataHandler
        $fakeAdminUser = GeneralUtility::makeInstance(BackendUserAuthentication::class);
        $fakeAdminUser->user = ['uid' => 0, 'username' => '_migration_', 'admin' => 1];
        $fakeAdminUser->workspace = ($inputRow['t3ver_wsid'] ?? 0);
        $GLOBALS['BE_USER'] = $fakeAdminUser;

        $tablePayload = $this->payload[$tableName];
        $parentId = $tablePayload['localizations'][$currentId];
        $parentTableName = ($tableName === 'pages_language_overlay' ? 'pages' : $tableName);

        $liveId = $currentId;
        if (!empty($inputRow['t3ver_wsid'])
            && !empty($inputRow['t3ver_oid'])
            && !VersionState::cast($inputRow['t3ver_state'])
                ->equals(VersionState::NEW_PLACEHOLDER_VERSION)) {
            $liveId = $inputRow['t3ver_oid'];
        }

        $dataMap = [];

        // simulate modifying a parent record to trigger dependent updates
        if (in_array('exclude', $tablePayload['fieldModes'])) {
            $parentRecord = $this->getRow($parentTableName, $parentId);
            foreach ($tablePayload['fieldModes'] as $fieldName => $fieldMode) {
                if ($fieldMode !== 'exclude') {
                    continue;
                }
                $dataMap[$parentTableName][$parentId][$fieldName] = $parentRecord[$fieldName];
            }
//<et:franz.kugelmann date="2017-06-19" desc="catch exceptions to avoid blocking the whole wizard just because of some bad data">
            #$dataMap = DataMapProcessor::instance($dataMap, $fakeAdminUser)->process();
            try {
                if (is_array($dataMap)) {
                    $dataMap = DataMapProcessor::instance($dataMap, $fakeAdminUser)->process();
                }
            } catch (\Exception $e) {
                if (is_null($this->logger)) $this->logger = \TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance('TYPO3\CMS\Core\Log\LogManager')->getLogger(__CLASS__);
                $this->logger->error('RowUpdater Exception: ' . $e->getMessage(), [$dataMap]);
            }

            unset($dataMap[$parentTableName][$parentId]);
            if (empty($dataMap[$parentTableName])) {
                unset($dataMap[$parentTableName]);
            }
        }

        // define localization states and thus trigger updates later
        if (State::isApplicable($tableName)) {
            $stateUpdates = [];
            foreach ($tablePayload['fieldModes'] as $fieldName => $fieldMode) {
                if ($fieldMode !== 'mergeIfNotBlank') {
                    continue;
                }
                if (!empty($inputRow[$fieldName])) {
                    $stateUpdates[$fieldName] = State::STATE_CUSTOM;
                } else {
                    $stateUpdates[$fieldName] = State::STATE_PARENT;
                }
            }

            $languageState = State::create($tableName);
            $languageState->update($stateUpdates);
            // only consider field names that still used mergeIfNotBlank
            $modifiedFieldNames = array_intersect(
                array_keys($tablePayload['fieldModes']),
                $languageState->getModifiedFieldNames()
            );
            if (!empty($modifiedFieldNames)) {
                $dataMap = [
                    $tableName => [
                        $liveId => [
                            'l10n_state' => $languageState->toArray()
                        ]
                    ]
                ];
            }
        }

        if (empty($dataMap)) {
            return $inputRow;
        }

        // let DataHandler process all updates, $inputRow won't change
        $dataHandler = GeneralUtility::makeInstance(DataHandler::class);
        $dataHandler->enableLogging = false;
        $dataHandler->start($dataMap, [], $fakeAdminUser);
        $dataHandler->process_datamap();

        if (!empty($dataHandlerHooks)) {
            $GLOBALS['TYPO3_CONF_VARS']['SC_OPTIONS']['t3lib/class.t3lib_tcemain.php'] = $dataHandlerHooks;
        }
        if (!empty($adminUser)) {
            $GLOBALS['BE_USER'] = $adminUser;
        }

        // the unchanged(!) state as submitted
        return $inputRow;
    }
}
