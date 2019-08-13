SurveyWidget = angular.module 'SurveyWidgetEngine', ['ngMaterial', 'angular-sortable-view', 'ngAria']

SurveyWidget.config ['$mdThemingProvider', ($mdThemingProvider) ->
		$mdThemingProvider.theme('default')
			.primaryPalette('teal')
			.accentPalette('indigo')
]

SurveyWidget.controller 'SurveyWidgetEngineCtrl', ['$scope', '$mdToast','$mdDialog', '$timeout', '$mdLiveAnnouncer', ($scope, $mdToast, $mdDialog, $timeout, $mdLiveAnnouncer) ->

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

			for answer in item.answers
				answer.text = desanitize(answer.text)
		return qset

	locateAndScrollToIncomplete = () ->
		for index, question of $scope.qset.items
			if $scope.isIncomplete(index)
				cardElement = document.getElementsByClassName("card")[index]
				cardElement.scrollIntoView()
				$mdLiveAnnouncer.announce("Question " + ( parseInt(index) + 1 ) + " must be completed.")
				return

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
		switch $scope.qset.items[index].options.questionType

			when 'check-all-that-apply'
				minResponses = $scope.qset.items[index].options.minResponseLimit
				unless minResponses then minResponses = 1
				responses = 0
				for i, value of $scope.responses[index]
					if value is true then responses++

				responses < minResponses
			else
				$scope.responses[index] == undefined

	$scope.showHelpDialog = (ev, message) ->
		$scope.dialogText = message
		$mdDialog.show
			contentElement: '#info-dialog-container'
			parent: angular.element(document.body)
			targetEvent: ev
			clickOutsideToClose: true
			openFrom: ev.currentTarget
			closeTo: ev.currentTarget

	$scope.cancel = () ->
		$mdDialog.hide()

	$scope.dropDownAnswer = (questionIndex, answerIndex) ->
		if answerIndex then return $scope.qset.items[questionIndex].answers[answerIndex].text
		return 'Select Answer'

	$scope.markSequenceComplete = (index) ->
		$scope.responses[index] = true
		$scope.updateCompleted()

	$scope.handleSequenceKeyDown = (event, questionIndex, itemIndex) ->
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
		text = $scope.qset.items[questionIndex].answers[itemIndex].text
		newIndex = 0
		if itemIndex == 0
			$scope.qset.items[questionIndex].answers.push $scope.qset.items[questionIndex].answers.shift()
			newIndex = $scope.qset.items[questionIndex].answers.length
		else
			item = $scope.qset.items[questionIndex].answers.splice(itemIndex, 1)
			$scope.qset.items[questionIndex].answers.splice(itemIndex - 1, 0, item[0])
			newIndex = itemIndex
		$scope.markSequenceComplete(questionIndex)
		$mdLiveAnnouncer.announce(text + " now " + newIndex + " of " + $scope.qset.items[questionIndex].answers.length)

	$scope.moveSequenceItemDown = (questionIndex, itemIndex) ->
		text = $scope.qset.items[questionIndex].answers[itemIndex].text
		newIndex = 0
		if itemIndex == $scope.qset.items[questionIndex].answers.length - 1
			$scope.qset.items[questionIndex].answers.unshift $scope.qset.items[questionIndex].answers.pop()
			newIndex = 1
		else
			item = $scope.qset.items[questionIndex].answers.splice(itemIndex, 1)
			$scope.qset.items[questionIndex].answers.splice(itemIndex + 1, 0, item[0])
			newIndex = itemIndex + 2
		$scope.markSequenceComplete(questionIndex)
		$mdLiveAnnouncer.announce(text + " now " + newIndex + " of " + $scope.qset.items[questionIndex].answers.length)

	$scope.updateCompleted = ->
		return false if !$scope.qset

		numQuestions = $scope.qset.items.length
		numAnswered = 0.0
		for response, i in $scope.responses[0...numQuestions]
			# numAnswered++ if response?
			numAnswered++ unless $scope.isIncomplete(i)

		$scope.progress = numAnswered / numQuestions * 100

	$scope.updateCheckAllThatApply = (qIndex, responseIndex) ->
		# special case for handling "None of the Above" selection:
		# The "None of the Above" option is always the last item in the response array
		if $scope.qset.items[qIndex].options.enableNoneOfTheAbove && responseIndex == $scope.qset.items[qIndex].answers.length
			# If None of the Above is true...
			if $scope.responses[qIndex][responseIndex] is true
				# Uncheck all other options except the final checkbox
				for i, response of $scope.responses[qIndex]
					if i < $scope.qset.items[qIndex].answers.length then $scope.responses[qIndex][i] = false

		# If "None of the Above" is enabled and user selects anything else, set "None of the Above" option to false
		else if $scope.qset.items[qIndex].options.enableNoneOfTheAbove
			$scope.responses[qIndex][$scope.qset.items[qIndex].answers.length] = false

		maxChecked = $scope.qset.items[qIndex].options.maxResponseLimit

		if maxChecked
			checkedCount = 0
			for i, value of $scope.responses[qIndex]
				if value is true then checkedCount++

			if checkedCount > maxChecked
				$scope.showToast "You can only select " + maxChecked + " items!"
				$scope.responses[qIndex][responseIndex] = false

		$scope.updateCompleted()

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
								if parseInt(key) is $scope.qset.items[i].answers.length and check then checkedItems.push $scope.qset.items[i].options.noneOfTheAboveText
								else if check then checkedItems.push $scope.qset.items[i].answers[key].text

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
			locateAndScrollToIncomplete()
		return

	Materia.Engine.start($scope)
]
