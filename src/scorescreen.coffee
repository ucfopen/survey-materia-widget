SurveyWidget = angular.module 'SurveyWidgetScorescreen', ['ngMaterial', 'ngMessages', 'ngAria']

SurveyWidget.controller 'SurveyWidgetScoreCtrl', ['$scope', '$mdToast', '$mdDialog', ($scope, $mdToast, $mdDialog) ->
	$scope.qset = null
	$scope.instance = null
	$scope.groups = null
	$scope.groupSubscores = null
	$scope.isPreview = false

	graphData = null
	$scope.maxScore = null
	$scope.distributionReady = false
	$scope.invalidGraph = false

	COMPARISON_RESULT_LIMIT = 30

	$scope.start = (instance, qset, scoreTable, isPreview, version = '1') ->
		$scope.instance = instance
		$scope.isPreview = isPreview
		prepareScoreInfo(qset, scoreTable)
		$scope.$apply()

	$scope.update = (qset, scoreTable) ->
		prepareScoreInfo(qset, scoreTable)
		$scope.$apply()

	prepareScoreInfo = (qset, scoreTable) ->
		$scope.qset = qset
		$scope.scoreTable = scoreTable
		generateResponses()

	$scope.cancel = () ->
		$mdDialog.hide()

	generateResponses = ->
		$scope.responses = []
		for score, i in $scope.scoreTable
			$scope.responses[i] = score.data[1]


	Materia.ScoreCore.hideScoresOverview()
	Materia.ScoreCore.hideResultsTable()
	Materia.ScoreCore.start($scope)
]
