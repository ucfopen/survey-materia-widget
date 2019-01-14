SurveyWidget = angular.module 'SurveyWidgetScorescreen', ['ngMaterial', 'ngMessages']

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
		# ensureScoreInGraph() if graphData
		$scope.$apply()

	prepareScoreInfo = (qset, scoreTable) ->
		$scope.qset = qset
		$scope.scoreTable = scoreTable
		generateResponses()
		# createGroups()
		# calculateScore()
		# calculateMaxScore()

	# $scope.handleScoreDistribution = (data) ->
	# 	if data
	# 		graphData = data
	# 		prepareData()
	# 		ensureScoreInGraph()
	# 		drawGraph()
	# 	else
	# 		$scope.invalidGraph = true
	# 	$scope.distributionReady = true
	# 	$scope.$apply()

	# $scope.showCompare = (ev) ->
	# 	if !graphData
	# 		Materia.ScoreCore.requestScoreDistribution()
	# 	$mdDialog.show(
	# 		contentElement: '#distribution-dialog-container'
	# 		parent: angular.element(document.body)
	# 		targetEvent: ev
	# 		clickOutsideToClose: true
	# 		openFrom: '#compare-button'
	# 		closeTo: '#compare-button'
	# 	)

	$scope.cancel = () ->
		$mdDialog.hide()

	# $scope.toggleQuestions = (groupIndex) ->
	# 	$('#group_' + groupIndex + ' .question-container').slideToggle()

	# 	button = $('#group_' + groupIndex + ' button')
	# 	if (button.text().includes('Show'))
	# 		button.text("Hide Questions")
	# 	else
	# 		button.text("Show Questions")

	# createGroups = () ->
	# 	$scope.groups = {}
	# 	$scope.groupSubscores = new Array($scope.qset.options.groups.length).fill(0)

	# 	for item, i in $scope.qset.items
	# 		group = item.options.group
	# 		$scope.groupSubscores[group] += ~~$scope.scoreTable[i].score
	# 		if $scope.groups[group]?
	# 			$scope.groups[group].push(i)
	# 		else
	# 			$scope.groups[group] = [i]

	calculateScore = ->
		total = 0
		for s in $scope.scoreTable
			s.score = ~~s.score
			total += s.score
		$scope.score = total
		$scope.$apply()

	# drawGraph = () ->
	# 	# load chart.js when needed
	# 	# TODO graph should update when attempt number is changed
	# 	$LAB.script("https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.7.2/Chart.min.js")
	# 	.wait ->
	# 		# set the bar colors
	# 		backgroundColors = new Array(graphData.length)
	# 		backgroundColors.fill('rgba(50, 50, 50, 0.8)')
	# 		scoreIndex = graphData.indexOf($scope.score)
	# 		highlightColor = 'rgb(255, 64, 129)'
	# 		backgroundColors[scoreIndex] = highlightColor

	# 		# required for bar chart
	# 		labels = new Array(graphData.length)

	# 		# set the legend box color
	# 		Chart.plugins.register
	# 			beforeDraw: (c) ->
	# 				legend = c.legend.legendItems[0];
	# 				legend.fillStyle = highlightColor

	# 		myChart = new Chart 'graph',
	# 			type: 'horizontalBar'
	# 			data:
	# 				labels: labels
	# 				datasets: [
	# 						label: 'Your Privilege Score'
	# 						data: graphData
	# 						backgroundColor: backgroundColors
	# 				]
	# 			options:
	# 				responsive: true
	# 				maintainAspectRatio: false
	# 				tooltips: enabled: false
	# 				barThickness: 5
	# 				scales:
	# 					yAxes: [
	# 						display: false
	# 					]
	# 					xAxes: [
	# 						ticks:
	# 							min: 0
	# 							max: $scope.maxScore
	# 						scaleLabel:
	# 							display: true
	# 							labelString: 'Privilege Score'
	# 						categoryPercentage: 1
	# 					]

	generateResponses = ->
		$scope.responses = []
		for score, i in $scope.scoreTable
			$scope.responses[i] = score.data[1]

	prepareData = ->
		return unless graphData
		if graphData.length > COMPARISON_RESULT_LIMIT
			# randomize the full list of what we have
			for val, index in graphData
				position = Math.floor Math.random() * (index + 1)
				temp = graphData[index]
				graphData[index] = graphData[position]
				graphData[position] = temp
			# throw away anything past our upward limit
			graphData = graphData.slice 0, COMPARISON_RESULT_LIMIT

	# the scorecore will just return a random sample of scores
	# we need to make sure that the user's score is included in this group
	ensureScoreInGraph = ->
		# scores in graphData is sorted by the server
		for score, i in graphData
			return if score == $scope.score
			# if the user's score is passed, replace the next one with it
			if score < $scope.score
				return graphData[i] = $scope.score

		# if not found by the end, replace the last one with it
		graphData.pop()
		graphData.push $scope.score

	# calculate the max score for the whole widget as well as group maxes
	calculateMaxScore = ->
		$scope.groupMaxscores = new Array($scope.qset.options.groups.length).fill(0)
		max = 0
		for item in $scope.qset.items
			bestAnswer = 0
			for answer in item.answers
				bestAnswer = Math.max(bestAnswer, answer.value)
			max += bestAnswer
			$scope.groupMaxscores[item.options.group] += bestAnswer
		$scope.maxScore = max


	Materia.ScoreCore.hideScoresOverview()
	Materia.ScoreCore.hideResultsTable()
	Materia.ScoreCore.start($scope)
]
