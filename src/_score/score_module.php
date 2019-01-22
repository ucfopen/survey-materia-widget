<?php

namespace Materia;

class Score_Modules_SurveyWidget extends Score_Module
{
	public $allow_distribution = true;

	public function check_answer($log)
	{
		if ($log->text != null && $log->text != '')
		{
			return 100;
		}
	}

}
