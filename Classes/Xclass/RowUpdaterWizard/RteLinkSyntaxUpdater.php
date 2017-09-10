<?php
declare(strict_types=1);
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

use Psr\Log\LoggerInterface;
use TYPO3\CMS\Core\LinkHandling\Exception\UnknownLinkHandlerException;
use TYPO3\CMS\Core\LinkHandling\Exception\UnknownUrnException;
use TYPO3\CMS\Core\LinkHandling\LinkService;
use TYPO3\CMS\Core\Log\LogManager;
use TYPO3\CMS\Core\Utility\GeneralUtility;
use TYPO3\CMS\Frontend\Service\TypoLinkCodecService;

/**
 * Move '<link ...' syntax to '<a href' in rte fields
 */
class RteLinkSyntaxUpdater extends \TYPO3\CMS\Install\Updates\RowUpdater\RteLinkSyntaxUpdater
{
    /**
     * @var $logger \TYPO3\CMS\Core\Log\Logger
     */
    protected $logger;

    /**
     * Finds all <link> tags and calls the typolink codec service and the link service (twice) to get a string
     * representation of the href part, and then builds an anchor tag.
     *
     * @param string $tableName
     * @param string $fieldName
     * @param array $row
     * @param bool $isFlexformField If true the content is htmlspecialchar()'d and must be treated as such
     * @return mixed the modified content
     */
    protected function transformLinkTagsIfFound(string $tableName, string $fieldName, array $row, bool $isFlexformField)
    {
        $content = $row[$fieldName];
        if (is_string($content)
            && !empty($content)
            && (stripos($content, '<link') !== false || stripos($content, '&lt;link') !== false)
        ) {
            $result = preg_replace_callback(
                $this->regularExpressions[$isFlexformField ? 'flex' : 'default'],
                function ($matches) use ($isFlexformField) {
                    $typoLink = $isFlexformField ? htmlspecialchars_decode($matches['typolink']) : $matches['typolink'];
                    $typoLinkParts = GeneralUtility::makeInstance(TypoLinkCodecService::class)->decode($typoLink);
                    $anchorTagAttributes = [
                        'target' => $typoLinkParts['target'],
                        'class' => $typoLinkParts['class'],
                        'title' => $typoLinkParts['title'],
                    ];

                    $link = $typoLinkParts['url'];
                    if (!empty($typoLinkParts['additionalParams'])) {
                        $link .= (strpos($link, '?') === false ? '?' : '&') . ltrim($typoLinkParts['additionalParams'], '&');
                    }

                    try {
                        $linkService = GeneralUtility::makeInstance(LinkService::class);
                        // Ensure the old syntax is converted to the new t3:// syntax, if necessary
                        $linkParts = $linkService->resolve($link);
                        $anchorTagAttributes['href'] = $linkService->asString($linkParts);
                        $newLink = '<a ' . GeneralUtility::implodeAttributes($anchorTagAttributes, true) . '>' .
                            ($isFlexformField ? htmlspecialchars_decode($matches['content']) : $matches['content']) .
                            '</a>';
                        if ($isFlexformField) {
                            $newLink = htmlspecialchars($newLink);
                        }
//<et:franz.kugelmann date="2017-06-19" desc="catch exceptions AND LOG to avoid blocking the whole wizard just because of some bad old links">
                    } catch (UnknownLinkHandlerException $e) {
                        if (is_null($this->logger)) $this->logger = \TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance('TYPO3\CMS\Core\Log\LogManager')->getLogger(__CLASS__);
                        $this->logger->error('UnknownLinkHandlerException for ' . $link, [$linkParts]);
                        $newLink = $matches[0];
                    } catch (UnknownUrnException $e) {
                        if (is_null($this->logger)) $this->logger = \TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance('TYPO3\CMS\Core\Log\LogManager')->getLogger(__CLASS__);
                        $this->logger->error('UnknownUrnException for ' . $link, [$linkParts]);
                        $newLink = $matches[0];

                    } catch (\TYPO3\CMS\Core\Resource\Exception\InvalidPathException $e) {
                        if (is_null($this->logger)) $this->logger = \TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance('TYPO3\CMS\Core\Log\LogManager')->getLogger(__CLASS__);
                        $this->logger->error('invalid linkdata filepath for ' . $link, [$linkParts]);
                        $newLink = $matches[0];
                    }

                    catch (\InvalidArgumentException $e) {
                        if (is_null($this->logger)) $this->logger = \TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance('TYPO3\CMS\Core\Log\LogManager')->getLogger(__CLASS__);
                        $this->logger->error('invalid linkdata record for ' . $link, [$linkParts]);
                        $newLink = $matches[0];
//</et:franz.kugelmann>
                    }

                    return $newLink;
                },
                $content
            );
            if ($result !== null) {
                $content = $result;
            } else {
                $this->logger->error('Converting links failed due to PCRE error', [
                    'table' => $tableName,
                    'field' => $fieldName,
                    'uid' => $row['uid'] ?? null,
                    'errorCode' => preg_last_error()
                ]);
            }
        }
        return $content;
    }
}
