# Create an angular module to house our controller
PrivilegeWalk = angular.module 'PrivilegeWalkCreator', ['ngMaterial', 'ngMessages', 'ngSanitize', 'angular-sortable-view']

PrivilegeWalk.config ['$mdThemingProvider', ($mdThemingProvider) ->
		$mdThemingProvider.theme('default')
			.primaryPalette('teal')
			.accentPalette('blue-grey')
]
PrivilegeWalk.controller 'PrivilegeWalkController', [ '$scope','$mdToast','$mdDialog','$sanitize','$compile', 'Resource', ($scope, $mdToast, $mdDialog, $sanitize, $compile, Resource) ->

	$scope.groups = [
		{text:'General', color:'#616161'}
	]

	# 700 colors from material-ui
	# TODO track which colors are being used
	$scope.colors = ['#C2185B', '#D32F2F', '#E64A19', '#689F38', '#00796B', '#0097A7', '#0288D1', '#303F9F', '#7B1FA2', '#455A64', '#616161', '#5D4037']


	$scope.presets = [
		{
			name:'Preset: Yes / No',
			values: [{text:'Yes'}, {text:'No'}]
		},
		{
			name: 'Preset: Likelihood',
			values: [{text:'Very Often'}, {text:'Often'}, {text:'Sometimes'}, {text:'Rarely', 'Never'}]
		},
		{
			name: 'Preset: Agreement',
			values: [{text:'Strongly Agree'}, {text:'Somewhat Agree'}, {text:'No Opinion'}, {text:'Somewhat Disagree'}, {text:'Strongly Disagree'}]
		}
	]

	# Preset indicies
	$scope.presetYesNo = 0
	$scope.presetLikelihood = 1
	$scope.presetAgreement = 2
	$scope.custom = -1

	# $scope.rangeOptions = [
	# 	{text:'Very Often', value: 5}
	# 	{text:'Often', value: 4}
	# 	{text:'Sometimes', value: 3}
	# 	{text:'Rarely', value: 2}
	# 	{text:'Never', value: 1}
	# ]

	# $scope.yesNo = [
	# 	{text:'Yes', value: 5}
	# 	{text:'No', value: 1}
	# ]

	# $scope.questionTypes = [
	# 	"Preset: Yes / No"
	# 	"Preset: Scale"
	# 	"Custom"
	# ]

	$scope.displayStyles = [
		{text:'Horizontal Scale', value: '0'}
		{text:'Dropdown Menu', value: '1'}
	]

	$scope.ready = false
	$scope.cards = []
	$scope.dragging = false
	$scope.dragOpts = {containment: ".custom-choice"}

	questionCount = 0
	originatorEv = null

	$scope.initNewWidget = (widget) ->
		$scope.$apply ->
			$scope.title = "My Survey Widget"
			$scope.addQuestion()
			$scope.ready = true

	$scope.initExistingWidget = (title,widget,qset) ->
		$scope.$apply ->
			$scope.title = title
			$scope.groups = qset.options.groups
			for item in qset.items
				$scope.cards.push
					question: item.questions[0].text
					questionType: item.options.questionType
					answers: item.answers
					style: item.options.style
					reversed: item.options.reversed == 'true'
					group: item.options.group
				questionCount++
			$scope.ready = true

	$scope.openColorMenu = ($mdMenu, ev, cardIndex) ->
		originatorEv = ev; # saved for animations
		$mdMenu.open(ev);

	$scope.showEditGroups = (ev) ->
		return false
		# $mdDialog.show(
		# 	contentElement: '#edit-groups-dialog-container'
		# 	parent: angular.element(document.body)
		# 	targetEvent: ev
		# 	clickOutsideToClose: true
		# 	openFrom: ev.currentTarget
		# 	closeTo: originatorEv.currentTarget
		# )

	$scope.setGroupColor = (groupIndex, color) ->
		$scope.groups[groupIndex].color = color

	# TODO make this intelligently pick a color that isn't used
	$scope.addGroup = () ->
		$scope.groups.push(
			{text: 'New Group', color:'#D32F2F'}
		)

	$scope.removeGroup = (index) ->
		# TODO shouldn't be able to delete a used group
		$scope.groups.splice index, 1

	$scope.selectGroup = (cardIndex, groupIndex) ->
		$scope.cards[cardIndex].group = groupIndex

	$scope.swapCards = (index1, index2) ->
		[$scope.cards[index1], $scope.cards[index2]] = [$scope.cards[index2], $scope.cards[index1]]

	$scope.deleteQuestion = (index) ->
		$scope.cards.splice index, 1
		questionCount--
		if $scope.cards.length == 0
			$scope.showToast("Must have at least one question.")
			$scope.addQuestion()

	$scope.addQuestion = ->
		# console.log $scope.presets[0]
		questionCount++
		$scope.cards.push
			question: 'Question '+questionCount
			answers: $scope.presets[$scope.presetYesNo].values
			questionType: $scope.presetYesNo
			style: '0'
			reversed: false
			group: 0

	$scope.addOption = (cardIndex) ->
		style = $scope.cards[cardIndex].style
		len = $scope.cards[cardIndex].answers.length
		if (style == '0' && len >= 5)
			$scope.showToast "Can only have 5 options per scale. Set Display Type to Dropdown to add more.", 10000
			return
		$scope.cards[cardIndex].answers.push {
			text:'', value: 1, id: ''
		}

	$scope.removeOption = (cardIndex, optionIndex) ->
		$scope.cards[cardIndex].answers.splice optionIndex, 1
		if $scope.cards[cardIndex].answers.length == 0
			$scope.showToast("Must have at least one option.")
			$scope.addOption(cardIndex)

	$scope.updateAnswerType = (cardIndex) ->
		
		$scope.cards[cardIndex].style = '0'

		# If it's a preset type, use the range from that preset
		if $scope.cards[cardIndex].questionType >= 0
			index = $scope.cards[cardIndex].questionType
			$scope.cards[cardIndex].answers = $scope.presets[index].values
		# Otherwise give it some default range values 
		else
			$scope.cards[cardIndex].answers = $scope.presets[1].values


		# switch ($scope.cards[cardIndex].questionType)
		# 	when 0
		# 		$scope.cards[cardIndex].answers = $scope.presets[0]
		# 	when 1
		# 		$scope.cards[]
		
		# switch ($scope.cards[cardIndex].questionType)
		# 	when '0'
		# 		$scope.cards[cardIndex].answers = $scope.yesNo
		# 	when '1'
		# 		$scope.cards[cardIndex].answers = $scope.rangeOptions
		# 	when '2'
		# 		custom = JSON.parse(JSON.stringify($scope.rangeOptions))
		# 		$scope.cards[cardIndex].answers = custom
		
		$scope.cards[cardIndex].reversed = false

	$scope.reverseValues = (cardIndex) ->
		$scope.cards[cardIndex].answers = $scope.cards[cardIndex].answers.reverse()

	$scope.showTypeDialog = (ev, questionType) ->
		$scope.dialogText = reversedTooltips[questionType]
		$mdDialog.show
			contentElement: '#info-dialog-container'
			parent: angular.element(document.body)
			targetEvent: ev
			clickOutsideToClose: true
			openFrom: ev.currentTarget
			closeTo: ev.currentTarget

	$scope.cancel = () ->
		$mdDialog.hide()

	$scope.showToast = (message, delay=3000) ->
		$mdToast.show(
			$mdToast.simple()
				.textContent(message)
				.position('top')
				.hideDelay(delay)
		)

	$scope.onSaveClicked = ->
		_isValid = validation()

		if _isValid
			qset = Resource.buildQset $scope.title, $scope.cards, $scope.groups
			if qset then Materia.CreatorCore.save $scope.title, qset
		else
			Materia.CreatorCore.cancelSave "Please make sure every question is complete."
			return false

	validation = ->
		for card in $scope.cards
			if !card.question || !card.answers then return false
			for answer in card.answers
				if !answer.text then return false
		return true

	$scope.onQuestionImportComplete = (items) ->
		for item in qset.items
			$scope.cards.push
				question: item.questions[0].text
				questionType: item.options.questionType
				answers: item.answers
				style: item.options.style
				reversed: item.options.reversed == '1'
				group: item.options.group
			questionCount++

	$scope.onSaveComplete = (title, widget, qset, version) -> true

	Materia.CreatorCore.start $scope
]

PrivilegeWalk.factory 'Resource', ['$sanitize', ($sanitize) ->
	buildQset: (title, questions, groups) ->
		qsetItems = []
		qset = {}

		if title is ''
			Materia.CreatorCore.cancelSave 'Please enter a title.'
			return false

		for question in questions
			item = @processQsetItem question
			if item then qsetItems.push item

		qset.items = qsetItems
		qset.options = {groups: groups}
		return qset

	processQsetItem: (item) ->
		question = $sanitize item.question
		questionType = $sanitize item.questionType
		style = $sanitize item.style
		reversed = $sanitize item.reversed
		group = $sanitize item.group

		# clean out previously generated IDs
		for answer in item.answers
			answer.id = ''

		materiaType: "question"
		id: null
		type: 'QA'
		options:
			questionType: questionType
			style: style
			reversed: reversed
			group: group
		questions: [{ text: question }]
		answers: item.answers
]
