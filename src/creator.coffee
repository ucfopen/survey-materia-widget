# Create an angular module to house our controller
SurveyWidget = angular.module 'SurveyWidgetCreator', ['ngMaterial', 'ngMessages', 'ngAnimate', 'ngSanitize', 'angular-sortable-view', 'ngAria']

SurveyWidget.config ['$mdThemingProvider', ($mdThemingProvider) ->
		$mdThemingProvider.theme('default')
			.primaryPalette('teal')
			.accentPalette('blue-grey')
]
SurveyWidget.controller 'SurveyWidgetController', [ '$scope','$mdToast','$mdDialog','$sanitize','$compile', 'Resource', 'sanitizeHelper', '$timeout', ($scope, $mdToast, $mdDialog, $sanitize, $compile, Resource, sanitizeHelper, $timeout) ->

	$scope.acceptedMediaTypes = ['image']
	mediaRef = null

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
	$scope.sequence = 'sequence'

	# Question Type Array
	$scope.questionTypes = [
		{text: 'Multiple Choice',value:'multiple-choice'},
		{text: 'Check All That Apply', value:'check-all-that-apply'},
		{text: 'Free Response', value:'free-response'},
		{text: 'Sequence', value: 'sequence'}
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
		'Set the minimum number of items to be checked. By default, at least one item must be selected. To allow zero responses, select the "None of the Above" option below. Note that doing so will force the minimum response limit to 1.',
		'Set the maximum number of items to be checked. If the box is left blank, the limit is not applied.',
		'Provides a dedicated "None of the Above" option, allowing the user to opt out of all other responses without leaving the question blank. Immediately unchecks all other responses if selected. Note that if a user selects this option, the minumum response limit is set to 1 and cannot be modified.'
	]

	$scope.ready = false
	$scope.cards = []
	$scope.dragging = false
	$scope.dragOpts = {
		containment: ".drag-choice"
	}

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
					question: sanitizeHelper.desanitize(item.questions[0].text)
					questionType: item.options.questionType
					answerType: item.options.answerType
					answers: item.answers
					displayStyle: item.options.displayStyle
					group: item.options.group
					randomize: item.options.randomize
					assets: if item.assets then item.assets else []
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

	$scope.duplicateQuestion = (index) ->
		duplicate = angular.copy($scope.cards[index])
		duplicate.fresh = true
		$scope.cards.splice index + 1, 0, duplicate
		questionCount++
		focusedCard = $scope.cards[index + 1]

	$scope.deleteQuestion = (index) ->
		$scope.cards[index].fresh = false
		questionCount--
		$scope.cards.splice index, 1
		if $scope.cards.length == 0
			$scope.showToast("Must have at least one question.")
			$scope.addQuestion()

	$scope.addQuestion = ->
		$scope.cards.push
			question: ''                                                         # question text
			answers: angular.copy $scope.presets[$scope.presetLikelihood].values # array of answer responses of form [{text: 'answer text'}]
			questionType: $scope.multipleChoice                                  # type of question - MC, check-all-that-apply, free response, etc
			answerType: $scope.presetLikelihood                                  # type of answer: is it a preset range, or custom
			displayStyle: $scope.horizontalScale                                 # should answers be displayed horizontally or via drop-down
			group: 0                                                             # group - NYI
			randomize: false                                                     # answers/options will be presented in a random order
			options: {}                                                          # extra options specific to individual question types
			assets: []                                                           # refers to a media asset attached to this question
			fresh: true                                                          # the question has been added/duplicated but not altered

	$scope.addOption = (cardIndex) ->
		style = $scope.cards[cardIndex].displayStyle
		len = $scope.cards[cardIndex].answers.length
		if (style == $scope.horizontalScale && len >= 5)
			$scope.showToast "Can only have 5 options per scale. Set Display Type to Dropdown to add more.", 10000
			return
		$scope.cards[cardIndex].answers.push { text:'' }
		$scope.cards[cardIndex].fresh = false

	$scope.removeOption = (cardIndex, optionIndex) ->
		$scope.cards[cardIndex].answers.splice optionIndex, 1
		if $scope.cards[cardIndex].answers.length == 0
			toastEnding = if $scope.cards[cardIndex].questionType == $scope.sequence then 'item' else 'question'
			$scope.showToast('Must have at least one ' + toastEnding + '.')
			$scope.addOption(cardIndex)
		$scope.cards[cardIndex].fresh = false

	$scope.handleSequenceKeyDown = (event, cardIndex, itemIndex) ->
		switch event.which
			when 38 #up arrow
				event.preventDefault()
				$scope.moveSequenceItemUp(cardIndex, itemIndex)
				$timeout ->
					event.target.focus()
			when 40 #down arrow
				event.preventDefault()
				$scope.moveSequenceItemDown(cardIndex, itemIndex)
				$timeout ->
					event.target.focus()
			else
				return

	$scope.beginMediaImport = (cardIndex) ->
		Materia.CreatorCore.showMediaImporter($scope.acceptedMediaTypes)
		mediaRef = cardIndex

	$scope.onMediaImportComplete = (media) ->
		asset = media[0]
		$scope.cards[mediaRef].assets[0] = {
			id: asset.id
			type: asset.type
			url: if asset.remote_url then asset.remote_url else Materia.CreatorCore.getMediaUrl(asset.id)
		}

	$scope.removeMedia = (cardIndex) ->
		$scope.cards[cardIndex].assets = []

	$scope.moveSequenceItemUp = (cardIndex, itemIndex, event) ->
		if itemIndex == 0
			$scope.cards[cardIndex].answers.push $scope.cards[cardIndex].answers.shift()
		else
			item = $scope.cards[cardIndex].answers.splice(itemIndex, 1)
			$scope.cards[cardIndex].answers.splice(itemIndex - 1, 0, item[0])
		if event
			$timeout ->
					event.target.focus()
		$scope.cards[cardIndex].fresh = false

	$scope.moveSequenceItemDown = (cardIndex, itemIndex, event) ->
		if itemIndex == $scope.cards[cardIndex].answers.length - 1
			$scope.cards[cardIndex].answers.unshift $scope.cards[cardIndex].answers.pop()
		else
			item = $scope.cards[cardIndex].answers.splice(itemIndex, 1)
			$scope.cards[cardIndex].answers.splice(itemIndex + 1, 0, item[0])
		if event
			$timeout ->
					event.target.focus()
		$scope.cards[cardIndex].fresh = false

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

			when $scope.sequence
				$scope.cards[cardIndex].displayStyle = 'sequence'
				$scope.cards[cardIndex].answerType = $scope.custom
				$scope.cards[cardIndex].answers = [{text: 'Item 1'}, {text: 'Item 2'},{text: 'Item 3'}]
				$scope.cards[cardIndex].randomize = false

		$scope.cards[cardIndex].fresh = false

	$scope.reverseValues = (cardIndex) ->
		$scope.cards[cardIndex].answers = $scope.cards[cardIndex].answers.reverse()
		$scope.cards[cardIndex].fresh = false

	$scope.enforceNoneOfTheAboveRestrictions = (cardIndex) ->
		if !$scope.cards[cardIndex].options.enableNoneOfTheAbove then $scope.cards[cardIndex].options.minResponseLimit = 1

	$scope.updateDisplayStyle = (cardIndex) ->
		responseCount = $scope.cards[cardIndex].answers.length

		if $scope.cards[cardIndex].displayStyle is $scope.horizontalScale && responseCount > 5
			$scope.showToast "Sorry, can't use the Horizontal Scale display option with more than 5 response options."
			$scope.cards[cardIndex].displayStyle = $scope.dropDown
		$scope.cards[cardIndex].fresh = false

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

			if card.questionType is $scope.checkAllThatApply
				if card.options.minResponseLimit is undefined then return false
				if card.options.maxResponseLimit is undefined then return false
		return true

	$scope.onQuestionImportComplete = (items) ->
		for item in items
			questionType = if item.options.questionType then item.options.questionType else $scope.multipleChoice
			answerType = if item.options.answerType then item.options.answerType else $scope.custom
			displayStyle = if item.options.displayStyle then item.options.displayStyle else $scope.dropDown
			group = 0

			for answer in item.answers?
				answer.text = sanitizeHelper.desanitize(answer.text)

			$scope.cards.push
				question: sanitizeHelper.desanitize(item.questions[0].text)
				questionType: questionType
				answerType: answerType
				displayStyle: displayStyle
				answers: item.answers
				displayStyle: item.options.displayStyle
				group: item.options.group
				randomize: item.options.randomize
				assets: if item.assets then item.assets else []
			questionCount++

		$scope.$apply ->
			$scope.showToast "Added " + items.length + " imported questions."

	$scope.onSaveComplete = (title, widget, qset, version) -> true

	Materia.CreatorCore.start $scope
]

SurveyWidget.factory 'Resource', ['$sanitize', 'sanitizeHelper', ($sanitize, sanitizeHelper) ->
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
		question = sanitizeHelper.sanitize(item.question)
		questionType = item.questionType
		answerType = item.answerType
		displayStyle = item.displayStyle
		group = item.group

		# clean out previously generated IDs and sanitize answer text
		for answer in item.answers
			answer.id = ''
			answer.text = sanitizeHelper.sanitize(answer.text)

		processed =
			materiaType: "question"
			id: null
			type: 'Survey'
			options:
				questionType: questionType
				answerType: answerType
				displayStyle: displayStyle
				group: group
				randomize: item.randomize
			questions: [{ text: question }]
			answers: item.answers
			assets: item.assets

		for key, value of item.options
			processed.options[key] = value

		return processed
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

SurveyWidget.service 'sanitizeHelper', [() ->
	SANITIZE_CHARACTERS =
		'&' : '&amp;',
		'>' : '&gt;',
		'<' : '&lt;',
		'"' : '&#34;'

	sanitize = (input) ->
		unless input then return
		for k, v of SANITIZE_CHARACTERS
			re = new RegExp(k, "g")
			input = input.replace re, v
		return input

	desanitize = (input) ->
		unless input then return
		for k, v of SANITIZE_CHARACTERS
			re = new RegExp(v, "g")
			input = input.replace re, k
		return input

	sanitize: sanitize
	desanitize: desanitize
]
