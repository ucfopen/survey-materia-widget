# Create an angular module to house our controller
SurveyWidget = angular.module 'SurveyWidgetCreator', ['ngMaterial', 'ngMessages', 'ngSanitize', 'angular-sortable-view']

SurveyWidget.config ['$mdThemingProvider', ($mdThemingProvider) ->
		$mdThemingProvider.theme('default')
			.primaryPalette('teal')
			.accentPalette('blue-grey')
]
SurveyWidget.controller 'SurveyWidgetController', [ '$scope','$mdToast','$mdDialog','$sanitize','$compile', 'Resource', ($scope, $mdToast, $mdDialog, $sanitize, $compile, Resource) ->

	$scope.groups = [
		{text:'General', color:'#616161'}
	]

	# 700 colors from material-ui
	# TODO track which colors are being used
	$scope.colors = ['#C2185B', '#D32F2F', '#E64A19', '#689F38', '#00796B', '#0097A7', '#0288D1', '#303F9F', '#7B1FA2', '#455A64', '#616161', '#5D4037']

	# Multiple Choice answer presets
	$scope.presets = [
		{
			name:'Preset: Yes / No',
			type: 'multiple-choice',
			values: [{text:'Yes'}, {text:'No'}]
		},
		{
			name: 'Preset: Likelihood',
			type: 'multiple-choice',
			values: [{text:'Very Often'}, {text:'Often'}, {text:'Sometimes'}, {text:'Rarely'}, {text:'Never'}]
		},
		{
			name: 'Preset: Agreement',
			type: 'multiple-choice',
			values: [{text:'Strongly Agree'}, {text:'Somewhat Agree'}, {text:'No Opinion'}, {text:'Somewhat Disagree'}, {text:'Strongly Disagree'}]
		}
	]

	# Preset indicies
	$scope.presetYesNo = 0
	$scope.presetLikelihood = 1
	$scope.presetAgreement = 2
	$scope.custom = -1

	# Question Type Aliases
	$scope.multipleChoice = 'multiple-choice'
	$scope.checkAllThatApply = 'check-all-that-apply'
	$scope.freeResponse = 'free-response'

	# Question Type Array
	$scope.questionTypes = [
		{text: 'Multiple Choice',value:'multiple-choice'},
		{text: 'Check All That Apply', value:'check-all-that-apply'},
		{text: 'Free Response', value:'free-response'}
	]

	# Answer Display Types
	$scope.horizontalScale = 'horizontal-scale'
	$scope.dropDown = 'drop-down'
	$scope.verticalList = 'vertical-list'

	$scope.displayStyles = [
		{text: 'Horizontal Scale', value: 'horizontal-scale'},
		{text: 'Drop Down', value: 'drop-down'}
	]

	$scope.helperMessages = [
		'Set the minimum number of items to be checked. By default, at least one item must be selected. To allow zero responses, select the "None of the Above" option below.',
		'Set the maximum number of items to be checked. If the box is left blank, the limit is not applied.'
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
			for item, index in qset.items
				$scope.cards.push
					question: item.questions[0].text
					questionType: item.options.questionType
					answerType: item.options.answerType
					answers: item.answers
					displayStyle: item.options.displayStyle
					group: item.options.group
					options: {}

				# conditional options
				# ----------------------------
				# check-all-that-apply options
				if $scope.cards[index].questionType is $scope.checkAllThatApply
					$scope.cards[index].options.enableNoneOfTheAbove = if item.options.enableNoneOfTheAbove then item.options.enableNoneOfTheAbove else false
					$scope.cards[index].options.minResponseLimit = if item.options.minResponseLimit then item.options.minResponseLimit else 1
					$scope.cards[index].options.maxResponseLimit = if item.options.maxResponseLimit then item.options.maxResponseLimit else null
					$scope.cards[index].options.noneOfTheAboveText = if item.options.noneOfTheAboveText then item.options.noneOfTheAboveText else "None of the above."

				questionCount++
			$scope.ready = true

	# NYI - used for groups
	# $scope.openColorMenu = ($mdMenu, ev, cardIndex) ->
	# 	originatorEv = ev; # saved for animations
	# 	$mdMenu.open(ev);

	$scope.swapCards = (index1, index2) ->
		[$scope.cards[index1], $scope.cards[index2]] = [$scope.cards[index2], $scope.cards[index1]]

	$scope.deleteQuestion = (index) ->
		$scope.cards.splice index, 1
		questionCount--
		if $scope.cards.length == 0
			$scope.showToast("Must have at least one question.")
			$scope.addQuestion()

	$scope.addQuestion = ->
		questionCount++
		$scope.cards.push
			question: ''																	# question text
			answers: angular.copy $scope.presets[$scope.presetLikelihood].values			# array of answer responses of form [{text: 'answer text'}]
			questionType: $scope.multipleChoice												# type of question - MC, check-all-that-apply, free response, etc
			answerType: $scope.presetLikelihood												# type of answer: is it a preset range, or custom
			displayStyle: $scope.horizontalScale											# should answers be displayed horizontally or via drop-down
			group: 0																		# group - NYI
			options: {}																		# extra options specific to individual question types

	$scope.addOption = (cardIndex) ->
		style = $scope.cards[cardIndex].displayStyle
		len = $scope.cards[cardIndex].answers.length
		if (style == $scope.horizontalScale && len >= 5)
			$scope.showToast "Can only have 5 options per scale. Set Display Type to Dropdown to add more.", 10000
			return
		$scope.cards[cardIndex].answers.push { text:'' }

	$scope.removeOption = (cardIndex, optionIndex) ->
		$scope.cards[cardIndex].answers.splice optionIndex, 1
		if $scope.cards[cardIndex].answers.length == 0
			$scope.showToast("Must have at least one option.")
			$scope.addOption(cardIndex)

	# Called when EITHER the question type or answer type changes (when MC is selected)
	# Populates the response section depending on question type and whether or not presets are selected
	$scope.updateResponseType = (cardIndex) ->
		
		switch ($scope.cards[cardIndex].questionType)

			when $scope.multipleChoice
				$scope.cards[cardIndex].displayStyle = $scope.horizontalScale

				# If it's a preset type, use the range from that preset
				if $scope.cards[cardIndex].answerType >= 0
					index = $scope.cards[cardIndex].answerType
					$scope.cards[cardIndex].answers = angular.copy $scope.presets[index].values
				# Otherwise give it some default range values 
				else
					$scope.cards[cardIndex].answers = angular.copy $scope.presets[1].values

			when $scope.checkAllThatApply
				$scope.cards[cardIndex].displayStyle = $scope.verticalList

				$scope.cards[cardIndex].answerType = $scope.custom
				$scope.cards[cardIndex].answers = [{text: 'Option 1'}, {text: 'Option 2'},{text: 'Option 3'}]

				# Optional parameters for min, max, and "None of the Above" responses
				$scope.cards[cardIndex].options.minResponseLimit = 1
				$scope.cards[cardIndex].options.maxResponseLimit = null
				$scope.cards[cardIndex].options.enableNoneOfTheAbove = false
				$scope.cards[cardIndex].options.noneOfTheAboveText = "None of the above."

			when $scope.freeResponse
				$scope.cards[cardIndex].displayStyle = 'text-area'
				$scope.cards[cardIndex].answerType = $scope.custom		
				$scope.cards[cardIndex].answers = [{text: 'Enter Your Response Here.'}]		
		
	$scope.reverseValues = (cardIndex) ->
		$scope.cards[cardIndex].answers = $scope.cards[cardIndex].answers.reverse()
	
	$scope.updateDisplayStyle = (cardIndex) ->
		responseCount = $scope.cards[cardIndex].answers.length

		if $scope.cards[cardIndex].displayStyle is $scope.horizontalScale && responseCount > 5
			$scope.showToast "Sorry, can't use the Horizontal Scale display option with more than 5 response options."
			$scope.cards[cardIndex].displayStyle = $scope.dropDown

	# ------------------------------// groups //-------------------------------------
	# Groups -- to be re-instated
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

	# ------------------------------// groups //-------------------------------------

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
		for item in items
			$scope.cards.push
				question: item.questions[0].text
				questionType: item.options.questionType
				answerType: item.options.answerType
				answers: item.answers
				displayStyle: item.options.displayStyle
				group: item.options.group
			questionCount++
		
		$scope.$apply ->
			$scope.showToast "Added " + items.length + " imported questions."

	$scope.onSaveComplete = (title, widget, qset, version) -> true

	Materia.CreatorCore.start $scope
]

SurveyWidget.factory 'Resource', ['$sanitize', ($sanitize) ->
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

	processQsetItem: (q) ->
		
		questionText = $sanitize q.question
		questionType = $sanitize q.questionType
		answerType = $sanitize q.answerType
		displayStyle = $sanitize q.displayStyle
		group = $sanitize q.group

		# clean out previously generated IDs
		for answer in q.answers
			answer.id = ''

		item =
			materiaType: "question"
			id: null
			type: 'QA'
			options:
				questionType: questionType
				answerType: answerType
				displayStyle: displayStyle
				group: group
			questions: [{ text: questionText }]
			answers: q.answers

		for key, value of q.options
			item.options[key] = value

		return item	
]
