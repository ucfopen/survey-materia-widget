describe('Creator Controller', function() {
	require('angular/angular.js')
	require('angular-mocks/angular-mocks.js')
	require('angular-animate')
	require('angular-aria')
	require('angular-messages')
	require('angular-sanitize')
	require('angular-material')
	require('angular-sortable-view/src/angular-sortable-view')

	beforeEach(() => {
		jest.resetModules()

		// mock materia
		global.Materia = {
			CreatorCore: {
				start: jest.fn(),
				alert: jest.fn(),
				cancelSave: jest.fn(),
				showMediaImporter: jest.fn(),
				getMediaUrl: jest.fn().mockImplementation((filename) => {
					return 'http://localhost/media/' + filename
				}),
				save: jest.fn().mockImplementation((title, qset) => {
					//the creator core calls this on the creator when saving is successful
					$scope.onSaveComplete()
					return {title: title, qset: qset}
				})
			}
		}

		// load qset
		widgetInfo = require('./demo.json')
		qset = widgetInfo.qset

		// load the required code
		angular.mock.module('SurveyWidgetCreator')
		require('./creator.coffee')

		// mock scope
		$scope = {
			$apply: jest.fn().mockImplementation(fn => {
				if(fn) return fn()
				else return function() {}
			})
		}

		// initialize the angular controller
		inject(function(_$controller_, _$timeout_){
			$timeout = _$timeout_
			// instantiate the controller
			$controller = _$controller_('SurveyWidgetController', { $scope: $scope })
		})
	})

	it('should edit a new widget', function(){
		$scope.initNewWidget(widgetInfo)
		expect($scope.title).toBe("My Survey Widget")
		expect($scope.ready).toBe(true)
		expect($scope.cards.length).toBe(1)
	})

	it('should handle imported media', function(){
		$scope.initNewWidget(widgetInfo)
		expect($scope.cards[0].assets).toEqual([])

		Materia.CreatorCore.showMediaImporter = jest.fn().mockImplementationOnce((types) => {
			expect(types).toEqual($scope.acceptedMediaTypes)
			$scope.onMediaImportComplete([{
				id: "1.png",
				name: "Mocked-Media",
				remote_url: null,
				type: "png"
			}])
		})

		$scope.beginMediaImport(0)
		expect(Materia.CreatorCore.showMediaImporter).toHaveBeenCalledTimes(1)
		expect(Materia.CreatorCore.showMediaImporter).toHaveBeenCalledWith(['image'])
		expect($scope.cards[0].assets[0].url).toBe('http://localhost/media/1.png')
		expect($scope.cards[0].assets[0].name).toBe('Mocked-Media')
	})

	it('should handle imported media with a remote url', function(){
		$scope.initNewWidget(widgetInfo)
		expect($scope.cards[0].assets).toEqual([])

		Materia.CreatorCore.showMediaImporter = jest.fn().mockImplementationOnce((types) => {
			$scope.onMediaImportComplete([{
				id: "1.png",
				name: "Mocked-Media",
				remote_url: 'http://remoteurl/media/1.png',
				type: "png"
			}])
		})

		$scope.beginMediaImport(0)
		expect(Materia.CreatorCore.showMediaImporter).toHaveBeenCalledTimes(1)
		expect($scope.cards[0].assets[0].url).toBe('http://remoteurl/media/1.png')
	})
})