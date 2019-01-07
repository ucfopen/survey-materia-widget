<?php
/**
 * Materia
 * It's a thing
 *
 * @package	    Materia
 * @version    1.0
 * @author     UCF New Media
 * @copyright  2011 New Media
 * @link       http://kogneato.com
 */


/**
 * NEEDS DOCUMENTATION
 *
 * The widget managers for the Materia package.
 *
 * @package	    Main
 * @subpackage  scoring
 * @category    Modules
  * @author      ADD NAME HERE
 */
namespace Materia;

class Score_Modules_PrivilegeWalk extends Score_Module
{
	public $allow_distribution = true;

	public function check_answer($log)
	{
		$answers = $this->questions[$log->item_id]->answers;
		foreach($answers as $answer)
		{
			if ($log->text == $answer['text'])
			{
				return $answer['value'];
			}
		}
		return 0;
	}

}
