SurveyWidget = angular.module 'SurveyWidgetEngine', ['ngMaterial', 'angular-sortable-view']

SurveyWidget.config ['$mdThemingProvider', ($mdThemingProvider) ->
		$mdThemingProvider.theme('default')
			.primaryPalette('teal')
			.accentPalette('indigo')
]


SurveyWidget.directive 'focusMe', ['$timeout', '$parse', ($timeout, $parse) ->
	link: (scope, element, attrs) ->
		model = $parse(attrs.focusMe)
		scope.$watch model, (value) ->
			if value
				$timeout ->
					element[0].focus()
			value
]

SurveyWidget.controller 'SurveyWidgetEngineCtrl', ['$scope', '$mdToast', '$timeout', ($scope, $mdToast, $timeout) ->

	$scope.qset = null
	$scope.instance = null
	$scope.responses = []

	$scope.horizontalScale = 'horizontal-scale'
	$scope.dropDown = 'drop-down'
	$scope.verticalList = 'vertical-list'
	$scope.textArea = 'text-area'
	$scope.sequence = 'sequence'

	$scope.dragOpts = {
		containment: ".drag-choice"
	}

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
		for item, index in qset.items
			if item.options.randomize
				item.answers = shuffle item.answers

		$scope.instance = instance
		$scope.qset = desanitizeQset(qset)
		$scope.progress = 0
		$scope.$apply()

	shuffle = (array) ->
		temp = null
		currentPass = array.length

		while currentPass
			swapIndex = Math.floor(Math.random() * currentPass--)

			temp = array[currentPass]
			array[currentPass] = array[swapIndex]
			array[swapIndex] = temp

		array

	$scope.isIncomplete = (index) ->
		$scope.responses[index] == undefined

	$scope.dropDownAnswer = (answerString) ->
		if answerString then return answerString
		return 'Select Answer'

	$scope.toggleSequence = (index) ->
		$scope.responses[index] = !$scope.responses[index]
		$scope.updateCompleted()

	$scope.handleSequenceKeyDown = (event, questionIndex, itemIndex) ->
		return if $scope.responses[questionIndex]
		switch event.which
			when 38 #up arrow
				event.preventDefault()
				$scope.moveSequenceItemUp(questionIndex, itemIndex)
				$timeout ->
					event.target.focus()
			when 40 #down arrow
				event.preventDefault()
				$scope.moveSequenceItemDown(questionIndex, itemIndex)
				$timeout ->
					event.target.focus()
			else
				return

	$scope.moveSequenceItemUp = (questionIndex, itemIndex) ->
		if itemIndex == 0
			$scope.qset.items[questionIndex].answers.push $scope.qset.items[questionIndex].answers.shift()
		else
			item = $scope.qset.items[questionIndex].answers.splice(itemIndex, 1)
			$scope.qset.items[questionIndex].answers.splice(itemIndex - 1, 0, item[0])

	$scope.moveSequenceItemDown = (questionIndex, itemIndex) ->
		if itemIndex == $scope.qset.items[questionIndex].answers.length - 1
			$scope.qset.items[questionIndex].answers.unshift $scope.qset.items[questionIndex].answers.pop()
		else
			item = $scope.qset.items[questionIndex].answers.splice(itemIndex, 1)
			$scope.qset.items[questionIndex].answers.splice(itemIndex + 1, 0, item[0])

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

						when $scope.sequence
							answersText = $scope.qset.items[i].answers.map (answer) ->
								answer.text
							answer = answersText.join "\n"
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
