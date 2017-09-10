<?php
namespace ElementareTeilchen\Upgrader\Xclass;

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

use TYPO3\CMS\Backend\Utility\BackendUtility;
use TYPO3\CMS\Core\DataHandling\Localization\DataMapItem;
use TYPO3\CMS\Core\Utility\MathUtility;

/**
 * This processor analyses the provided data-map before actually being process
 * in the calling DataHandler instance. Field names that are configured to have
 * "allowLanguageSynchronization" enabled are either synchronized from there
 * relative parent records (could be a default language record, or a l10n_source
 * record) or to their dependent records (in case a default language record or
 * nested records pointing upwards with l10n_source).
 *
 * Except inline relational record editing, all modifications are applied to
 * the data-map directly, which ensures proper history entries as a side-effect.
 * For inline relational record editing, this processor either triggers the copy
 * or localize actions by instantiation a new local DataHandler instance.
 *
 * Namings in this class:
 * + forTableName, forId always refers to dependencies data is provided *for*
 * + fromTableName, fromId always refers to ancestors data is retrieved *from*
 */
class DataMapProcessor extends \TYPO3\CMS\Core\DataHandling\Localization\DataMapProcessor
{
    /**
     * @var $logger \TYPO3\CMS\Core\Log\Logger
     */
    protected $logger;

    /**
     * Synchronize a single item
     *
     * @param DataMapItem $item
     * @param array $fieldNames
     * @param string|int $fromId
     */
    protected function synchronizeTranslationItem(DataMapItem $item, array $fieldNames, $fromId)
    {
        if (empty($fieldNames)) {
            return;
        }

        $fieldNameList = 'uid,' . implode(',', $fieldNames);

        $fromRecord = ['uid' => $fromId];
        if (MathUtility::canBeInterpretedAsInteger($fromId)) {
            $fromRecord = BackendUtility::getRecordWSOL(
                $item->getFromTableName(),
                $fromId,
                $fieldNameList
            );
        }

//<et:franz.kugelmann desc="try to fix strict problem, sometimes the above methods returns null
        if (is_null($fromRecord)) {
            if (is_null($this->logger)) $this->logger = \TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance('TYPO3\CMS\Core\Log\LogManager')->getLogger(__CLASS__);
            $this->logger->error('null record returned (fromRecord) for uid ' . $fromId, [$item, $fieldNames]);

            $fromRecord = [];
        }
//</et:franz.kugelmann

        $forRecord = [];
        if (!$item->isNew()) {
            $forRecord = BackendUtility::getRecordWSOL(
                $item->getTableName(),
                $item->getId(),
                $fieldNameList
            );
        }

//<et:franz.kugelmann desc="try to fix strict problem, sometimes the above methods returns null
        if (is_null($forRecord)) {
            if (is_null($this->logger)) $this->logger = \TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance('TYPO3\CMS\Core\Log\LogManager')->getLogger(__CLASS__);
            $this->logger->error('null record returned (forRecord) for uid ' . $item->getId(), $fieldNames);
            $forRecord = [];
        }
//</et:franz.kugelmann

//<et:franz.kugelmann desc="some records are not processed, exception is not catched, try to log and find problem
        try {

            foreach ($fieldNames as $fieldName) {
                $this->synchronizeFieldValues(
                    $item,
                    $fieldName,
                    $fromRecord,
                    $forRecord
                );
            }

        } catch (\RuntimeException $e) {
            if (is_null($this->logger)) $this->logger = \TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance('TYPO3\CMS\Core\Log\LogManager')->getLogger(__CLASS__);
            $this->logger->error('child record problem with field ' . $fieldName . ' for ' . $item->getId(), [$fromRecord, $forRecord]);

        }
//</et:franz.kugelmann
    }

}
