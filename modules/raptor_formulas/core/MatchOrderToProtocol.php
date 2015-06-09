<?php
/**
 * @file
 * ------------------------------------------------------------------------------------
 * Created by SAN Business Consultants for RAPTOR phase 2
 * Open Source VA Innovation Project 2011-2014
 * VA Innovator: Dr. Jonathan Medverd
 * SAN Implementation: Andrew Casertano, Frank Font, et al
 * Contacts: acasertano@sanbusinessconsultants.com, ffont@sanbusinessconsultants.com
 * ------------------------------------------------------------------------------------
 *  
 */

namespace raptor_formulas;

require_once 'LanguageInference.php';

/**
 * Logic for scoring order match
 *
 * @author Frank Font of SAN Business Consultants
 */
class MatchOrderToProtocol 
{
    private $m_oLI = NULL;
    function __construct()
    {
        $this->m_oLI = new \raptor_formulas\LanguageInference();
    }
    
    /**
     * The original order should already be analyzed into clues map
     * Higher score means better match.
     * 
     * @param type $cluesmap map of clues
     * @param type $psn protocol short name
     * @param type $longname
     * @param type $modality_abbr
     * @param type $contrast_yn
     * @param type $kwmap map of keywords for each protocol shortname
     * @return array[score,why]
     */
    public function getProtocolMatchScore(
              $cluesmap
            , $psn
            , $longname
            , $modality_abbr
            , $contrast_yn
            , $kwmap
            , $codemap=NULL)
    {
        $explained = array();
        $matchscore = 0;
        if($modality_abbr == $cluesmap['modality_abbr'])
        {
            $matchscore++;
            $explained[] = '+1 modality_match';
        }
        if($matchscore > 0 || trim($cluesmap['modality_abbr']) == '' )
        {
            //Do not add to score if contrast setting is not compatible
            if($cluesmap['contrast'] === NULL || $contrast_yn === NULL 
                    || ($contrast_yn == 1 && $cluesmap['contrast'] === TRUE)
                    || ($contrast_yn == 0 && $cluesmap['contrast'] === FALSE))
            {
                $matchscore++;  //Give it one more just because we got past the contrast filter.
                $explained[] = '+1 y/n_contrast_match';
                if($codemap != NULL)
                {
                    //A code map as provided for the protocol we are checking.
                    if(is_array($cluesmap['codemap']))
                    {
error_log("LOOK $psn we have codemap for both clue and protocol !!!!" 
        . "\n\tCODEMAP=" . print_r($codemap,TRUE)
        . "\n\tCLUEMAP=".print_r($cluesmap['codemap'],TRUE));
                        //A code map was provided for the order we are checking
                        foreach($cluesmap['codemap'] as $groupname=>$group)
                        {
error_log("LOOK $psn we have codemap check now for $groupname");
                            if(isset($codemap[$groupname]))
                            {
error_log("LOOK $psn we have codemap check now for match IN $codemap $groupname");
                                foreach($group as $onecode)
                                {
error_log("\nLOOK\t\t $psn onecode=$onecode we have codemap check now for match IN $codemap $groupname");
                                    if(isset($codemap[$groupname][$onecode]))
                                    {
error_log("\nLOOK\t\t HIT!!!! $psn onecode=$onecode we have codemap check now for match IN $codemap $groupname");
                                        //The protocol has a mapping in this group
                                        $matchscore+=10;  //Big match
                                        $explained[] = "+10 {$groupname}_match";
                                        break;  //One match per group is enough
                                    }
                                }
                            }
                        }
                    }
                }
                if(isset($kwmap[$psn]))
                {
                    $matches=0;
                    //We have keywords, so factor them in
                    foreach($kwmap[$psn] as $wg=>$kwg)
                    {
                        $kwmatches = $this->countMatchingWords($kwg, $cluesmap['keywords']);
                        if($kwmatches > 0)
                        {
                            $addscore = (5 - $wg) * $kwmatches;
                            $matchscore += $addscore;
                            $explained[] = "+$addscore kw{$wg}_matches";
                        }
                        $matches+=$kwmatches;
                    }
                } else {
                    //Use the protocol library long name as a clue (not as good as real keywords)
                    $tempkw = $this->m_oLI->inferOrderPhraseKeywords(strtoupper($longname));
                    $matches = $this->countMatchingWords($tempkw, $cluesmap['keywords']);
                }
                if($matches > 0)
                {
                    $addscore = ($matches + 1);
                    $matchscore += $addscore;    //MUST add one more because of THRESHOLD logic elsewhere!!!
                    $explained[] = "+{$addscore} simplematch_bonus";
                }
            }
        }
        $scoredetails = array('score'=>$matchscore,'why'=>$explained);
        return $scoredetails;
    }
    
    /**
     * @return int number of words that matched between the lists
     */
    public function countMatchingWords($list1,$list2)
    {
        $count = 0;
        if(is_array($list1) && is_array($list2))
        {
            foreach($list1 as $word1)
            {
                if(trim($word1) > '')
                {
                    foreach($list2 as $word2)
                    {
                        if($word1 == $word2)
                        {
                            $count++;
                        }
                    }
                }
            }
        }
        return $count;
    }
}
