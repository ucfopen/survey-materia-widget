SurveyWidget = angular.module 'SurveyWidgetEngine', ['ngMaterial']

SurveyWidget.config ['$mdThemingProvider', ($mdThemingProvider) ->
		$mdThemingProvider.theme('default')
			.primaryPalette('teal')
			.accentPalette('indigo')
]

SurveyWidget.controller 'SurveyWidgetEngineCtrl', ['$scope', '$mdToast', ($scope, $mdToast) ->

	$scope.qset = null
	$scope.instance = null
	$scope.responses = []

	$scope.horizontalScale = 'horizontal-scale'
	$scope.dropDown = 'drop-down'
	$scope.verticalList = 'vertical-list'
	$scope.textArea = 'text-area'

	SANITIZED_CHARACTERS =
		'&' : '&amp;',
		'>' : '&gt;',
		'<' : '&lt;',
		'"' : '&#34;'

	desanitize = (input) ->
		unless input then return
		for k, v of SANITIZED_CHARACTERS
			re = new RegExp(v, "g")
			input = input.replace re, k
		return input

	desanitizeQset = (qset) ->
		for index, item of qset.items
			item.questions[0].text = desanitize(item.questions[0].text)

			for answer of item.answers
				answer.text = desanitize(answer.text)

		return qset

	$scope.showToast = (message) ->
		$mdToast.show(
			$mdToast.simple()
				.textContent(message)
				.position('bottom right')
				.hideDelay(3000)
		)

	$scope.start = (instance, qset, version) ->
		$scope.instance = instance
		$scope.qset = desanitizeQset(qset)
		$scope.progress = 0
		$scope.$apply()

	$scope.isIncomplete = (index) ->
		$scope.responses[index] == undefined

	$scope.dropDownAnswer = (answerString) ->
		if answerString then return answerString
		return 'Select Answer'

	$scope.updateCompleted = ->
		return false if !$scope.qset

		numQuestions = $scope.qset.items.length
		numAnswered = 0.0
		for response, i in $scope.responses[0...numQuestions]
			numAnswered++ if response?

		$scope.progress = numAnswered / numQuestions * 100

	$scope.submit = ->
		if $scope.progress == 100
			try
				$scope.responses.forEach( (response, i) ->
					answer = {}
					switch $scope.qset.items[i].options.questionType
						when "free-response"
							answer = response

						when "check-all-that-apply"
							checkedItems = []

							for key, check of response
								if check then checkedItems.push $scope.qset.items[i].answers[key].text

							answer = checkedItems.join ", "
						else

							answer = $scope.qset.items[i].answers[~~response].text

					Materia.Score.submitQuestionForScoring $scope.qset.items[i].id, answer
				)
				Materia.Engine.end()
			catch e
				alert 'Unable to save storage data'
		else
			$scope.showIncomplete = true
			$scope.showToast "Must complete all questions."
		return

	Materia.Engine.start($scope)
]
