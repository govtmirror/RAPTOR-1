<?php
/**
 * @file
 * ------------------------------------------------------------------------------------
 * Created by SAN Business Consultants for RAPTOR phase 2
 * Open Source VA Innovation Project 2011-2015
 * VA Innovator: Dr. Jonathan Medverd
 * SAN Implementation: Andrew Casertano, Frank Font, et al
 * Contacts: acasertano@sanbusinessconsultants.com, ffont@sanbusinessconsultants.com
 * ------------------------------------------------------------------------------------
 * Copyright 2015 SAN Business Consultants, a Maryland USA company (sanbusinessconsultants.com)
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ------------------------------------------------------------------------------------
 */ 


namespace raptor;

require_once 'EditListsBasePage.php';

/**
 * This class returns the page to edit keyword list
 *
 * @author Frank Font of SAN Business Consultants
 */
class EditListAtRiskAllergyContrastPage extends EditListsBasePage
{
    private static $reqprivs = array('EARM1'=>1);
    
    function __construct()
    {
        parent::__construct(self::$reqprivs,'raptor_atrisk_allergy_contrast');

        global $base_url;
        
        $url = $base_url.'/raptor/editatriskallergycontrast';
        $name = 'Edit Allergy Contrast List';
        $description = 'These keywords are used to detect possible contrast allergies in patient.';
        $listname = 'Allergy Contrast';

        $this->setName($name);
        $this->setListName($listname);
        $this->setDescription($description);
        $this->setURL($url);
    }
}
