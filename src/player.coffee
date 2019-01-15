PrivilegeWalk = angular.module 'PrivilegeWalkEngine', ['ngMaterial']

PrivilegeWalk.config ['$mdThemingProvider', ($mdThemingProvider) ->
		$mdThemingProvider.theme('default')
			.primaryPalette('teal')
			.accentPalette('indigo')
]

PrivilegeWalk.controller 'PrivilegeWalkEngineCtrl', ['$scope', '$mdToast', ($scope, $mdToast) ->
	
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
		$scope.responses[index] == undefined

	$scope.updateCompleted = ->
		return false if !$scope.qset

		numQuestions = $scope.qset.items.length
		numAnswered = 0.0
		for response, i in $scope.responses[0...numQuestions]
			numAnswered++ if response?

		$scope.progress = numAnswered / numQuestions * 100

	# TODO can remove this?
	createStorageTable = (tableName, columns) ->
		args = columns
		args.splice(0, 0, tableName)
		Materia.Storage.Manager.addTable.apply(this, args)

	# TODO can remove this?
	insertStorageRow = (tableName, values) ->
		args = values
		args.splice(0, 0, tableName)
		Materia.Storage.Manager.insert.apply(this, args)

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
