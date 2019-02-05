<?php
/**
 * @group App
 * @group Materia
 * @group Score
 * @group Enigma
 */
class Test_Score_Modules_SurveyWidget extends Score_Module
{

	protected function _get_qset()
	{

		return json_decode('
			{
				"items": [
				{
					"materiaType": "question",
					"id": "",
					"type": "QA",
					"created_at": 1547743689,
					"questions": [
						{
							"text": "How do you typically check for daily weather updates?"
						}
					],
					"answers": [
						{
							"text": "Built-in notifications on my phone",
							"id": ""
						},
						{
							"text": "A dedicated weather app on my phone",
							"id": ""
						},
						{
							"text": "Social media (Twitter, Facebook, etc)",
							"id": ""
						},
						{
							"text": "TV news",
							"id": ""
						}
					],
					"options": {
						"questionType": "check-all-that-apply",
						"answerType": "-1",
						"displayStyle": "vertical-list",
						"group": "0"
					},
					"assets": []
				},
				{
					"materiaType": "question",
					"id": "",
					"type": "QA",
					"created_at": 1547743689,
					"questions": [
						{
							"text": "Generally speaking, do you plan in advance for inclement weather before leaving home?"
						}
					],
					"answers": [
						{
							"text": "Very Often",
							"id": ""
						},
						{
							"text": "Often",
							"id": ""
						},
						{
							"text": "Sometimes",
							"id": ""
						},
						{
							"text": "Rarely",
							"id": ""
						},
						{
							"text": "Never",
							"id": ""
						}
					],
					"options": {
						"questionType": "multiple-choice",
						"answerType": "1",
						"displayStyle": "horizontal-scale",
						"group": "0"
					},
					"assets": []
				},
				{
					"materiaType": "question",
					"id": "",
					"type": "QA",
					"created_at": 1547743689,
					"questions": [
						{
							"text": "Large weather events (snow storms, hurricanes, nor\'easters) cause me stress well in advance."
						}
					],
					"answers": [
						{
							"text": "Strongly Agree",
							"id": ""
						},
						{
							"text": "Somewhat Agree",
							"id": ""
						},
						{
							"text": "No Opinion",
							"id": ""
						},
						{
							"text": "Somewhat Disagree",
							"id": ""
						},
						{
							"text": "Strongly Disagree",
							"id": ""
						}
					],
					"options": {
						"questionType": "multiple-choice",
						"answerType": "2",
						"displayStyle": "horizontal-scale",
						"group": "0"
					},
					"assets": []
				},
				{
					"materiaType": "question",
					"id": "",
					"type": "QA",
					"created_at": 1547743689,
					"questions": [
						{
							"text": "Do you keep an umbrella in your car or on your person when traveling to work?"
						}
					],
					"answers": [
						{
							"text": "Yes",
							"id": ""
						},
						{
							"text": "No",
							"id": ""
						}
					],
					"options": {
						"questionType": "multiple-choice",
						"answerType": "0",
						"displayStyle": "horizontal-scale",
						"group": "0"
					},
					"assets": []
				},
				{
					"materiaType": "question",
					"id": "",
					"type": "QA",
					"created_at": 1547743689,
					"questions": [
						{
							"text": "I feel comfortable driving in severe weather conditions."
						}
					],
					"answers": [
						{
							"text": "Strongly Agree",
							"id": ""
						},
						{
							"text": "Somewhat Agree",
							"id": ""
						},
						{
							"text": "No Opinion",
							"id": ""
						},
						{
							"text": "Somewhat Disagree",
							"id": ""
						},
						{
							"text": "Strongly Disagree",
							"id": ""
						}
					],
					"options": {
						"questionType": "multiple-choice",
						"answerType": "2",
						"displayStyle": "horizontal-scale",
						"group": "0"
					},
					"assets": []
				},
				{
					"materiaType": "question",
					"id": "",
					"type": "QA",
					"created_at": 1547743689,
					"questions": [
						{
							"text": "Thinking back, what was the most severe or stressful weather event you\'ve had to endure?"
						}
					],
					"answers": [
						{
							"text": "Enter Your Response Here.",
							"id": ""
						}
					],
					"options": {
						"questionType": "free-response",
						"answerType": "-1",
						"displayStyle": "text-area",
						"group": "0"
					},
					"assets": []
				}
			],
			"options": {
				"groups": [
					{
						"text": "General",
						"color": "#616161"
					}
				]
			}
		}');
	}

	protected function _makeWidget($partial = 'false')
	{
		$this->_asAuthor();

		$title = 'SURVEY WIDGET SCORE MODULE TEST';
		$widget_id = $this->_find_widget_id('Simple Survey');
		$qset = (object) ['version' => 1, 'data' => $this->_get_qset()];
		return \Materia\Api::widget_instance_save($widget_id, $title, $qset, false);
	}

	public function test_check_answer()
	{
		$inst = $this->_makeWidget('false');
		$play_session = \Materia\Api::session_play_create($inst->id);
		$qset = \Materia\Api::question_set_get($inst->id, $play_session);

		$logs = array();

		$logs[] = json_decode('{
			"text":"Built-in notifications on my phone",
			"type":1004,
			"value":"",
			"item_id":"'.$qset->data['items'][0]['id'].'",
			"game_time":10
		}');
		$logs[] = json_decode('{
			"text":"Often",
			"type":1004,
			"value":"",
			"item_id":"'.$qset->data['items'][1]['id'].'",
			"game_time":11
		}');
		$logs[] = json_decode('{
			"text":"Strongly Agree",
			"type":1004,
			"value":"",
			"item_id":"'.$qset->data['items'][2]['id'].'",
			"game_time":12
		}');
		$logs[] = json_decode('{
			"text":"Yes",
			"type":1004,
			"value":"",
			"item_id":"'.$qset->data['items'][3]['id'].'",
			"game_time":13
		}');
		$logs[] = json_decode('{
			"text":"Strongly Agree",
			"type":1004,
			"value":"",
			"item_id":"'.$qset->data['items'][4]['id'].'",
			"game_time":14
		}');
		$logs[] = json_decode('{
			"text":"Hurricane Irma",
			"type":1004,
			"value":"",
			"item_id":"'.$qset->data['items'][5]['id'].'",
			"game_time":15
		}');

		$logs[] = json_decode('{
			"text":"",
			"type":2,
			"value":"",
			"item_id":0,
			"game_time":16
		}');

		$output = \Materia\Api::play_logs_save($play_session, $logs);

		$scores = \Materia\Api::widget_instance_scores_get($inst->id);

		$this_score = \Materia\Api::widget_instance_play_scores_get($play_session);

		$this->assertInternalType('array', $this_score);
		$this->assertEquals(100, $this_score[0]['overview']['score']);
	}
}
