<?php
declare(strict_types=1);
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

/**
 * Resolves links to records and the parameters given
 */
class RecordLinkHandler extends \TYPO3\CMS\Core\LinkHandling\RecordLinkHandler
{
    /**
     * Returns all valid parameters for linking to a TYPO3 page as a string
     *
     * @param array $parameters
     * @return string
     * @throws \InvalidArgumentException
     */
    public function asString(array $parameters): string
    {
//<et:franz.kugelmann date="2017-06-26" desc="legacy links - as with RteLinkSyntaxUpdater come with these parameters in $parameters['url']">
        if (empty($parameters['identifier']) && !empty($parameters['url']['identifier'])) {
            $parameters['identifier'] = $parameters['url']['identifier'];
        }
        if (empty($parameters['uid']) && !empty($parameters['url']['uid'])) {
            $parameters['uid'] = $parameters['url']['uid'];
        }
//</et:franz.kugelmann

        if (empty($parameters['identifier']) || empty($parameters['uid'])) {
            throw new \InvalidArgumentException('The RecordLinkHandler expects identifier and uid as $parameter configuration.', 1486155150);
        }
        $urn = $this->baseUrn;
        $urn .= sprintf('?identifier=%s&uid=%s', $parameters['identifier'], $parameters['uid']);

        return $urn;
    }

}
