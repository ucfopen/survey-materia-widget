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


	$scope.showToast = (message) ->
		$mdToast.show(
			$mdToast.simple()
				.textContent(message)
				.position('bottom right')
				.hideDelay(3000)
		)

	$scope.start = (instance, qset, version) ->
		$scope.instance = instance
		$scope.qset = qset
		$scope.progress = 0
		$scope.$apply()

	$scope.isIncomplete = (index) ->
		switch $scope.qset.items[index].options.questionType

			when 'check-all-that-apply'
				minResponses = $scope.qset.items[index].options.minResponseLimit
				unless minResponses then return false
				responses = 0
				for i, value of $scope.responses[index]
					if value is true then responses++

				responses < minResponses
			else
				$scope.responses[index] == undefined

	$scope.updateCompleted = ->
		return false if !$scope.qset

		numQuestions = $scope.qset.items.length
		numAnswered = 0.0
		for response, i in $scope.responses[0...numQuestions]
			numAnswered++ if response?

		$scope.progress = numAnswered / numQuestions * 100

	$scope.updateCheckAllThatApply = (qIndex, responseIndex) ->

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
