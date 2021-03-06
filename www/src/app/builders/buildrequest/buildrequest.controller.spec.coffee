if window.__karma__?
    beforeEach module 'app'

    describe 'buildrequest controller', ->
        buildbotService = mqService = $scope = $httpBackend = $rootScope = null
        $timeout = createController = $stateParams = null
        goneto  = null
        # overrride "$state"
        beforeEach module(($provide) ->
            $provide.value "$state",
                            go: (args...) -> goneto = args
            $provide.value "$stateParams",
                            buildrequest: 1
            null  # those module callbacks need to return null!
        )

        injected = ($injector) ->
            $httpBackend = $injector.get('$httpBackend')
            decorateHttpBackend($httpBackend)
            $rootScope = $injector.get('$rootScope')
            $scope = $rootScope.$new()
            mqService = $injector.get('mqService')
            $timeout = $injector.get('$timeout')
            $stateParams = $injector.get('$stateParams')
            $controller = $injector.get('$controller')
            $q = $injector.get('$q')
            # stub out the actual backend of mqservice
            spyOn(mqService,"setBaseUrl").and.returnValue(null)
            spyOn(mqService,"startConsuming").and.returnValue($q.when( -> ))
            spyOn(mqService,"stopConsuming").and.returnValue(null)
            buildbotService = $injector.get('buildbotService')
            createController = ->
                return $controller 'buildrequestController',
                    $scope: $scope
        beforeEach(inject(injected))

        afterEach ->
            $httpBackend.verifyNoOutstandingExpectation()
            $httpBackend.verifyNoOutstandingRequest()
        it 'should query for buildrequest', ->
            $httpBackend.expectDataGET('buildrequests/1')
            $httpBackend.expectDataGET('buildsets/1')
            controller = createController()
            $httpBackend.flush()
            $scope.buildrequest.claimed = true
            $httpBackend.expectDataGET('builds?buildrequestid=1')
            $httpBackend.flush()
            expect($scope.builds[0].buildid).toBeDefined()
            $timeout.flush()
            $httpBackend.verifyNoOutstandingRequest()

        it 'should query for builds again if first query returns 0', ->
            $httpBackend.expectDataGET('buildrequests/1')
            $httpBackend.expectDataGET('buildsets/1')
            controller = createController()
            $httpBackend.flush()
            $scope.buildrequest.claimed = true
            $httpBackend.expectDataGET 'builds?buildrequestid=1',
                                        nItems:0
            $httpBackend.flush()
            expect($scope.builds.length).toBe(0)
            $httpBackend.expectDataGET 'builds?buildrequestid=1',
                                        nItems:0
            $timeout.flush()
            $httpBackend.flush()
            expect($scope.builds.length).toBe(0)
            $httpBackend.expectDataGET 'builds?buildrequestid=1',
                                        nItems:1
            $timeout.flush()
            $httpBackend.flush()
            expect($scope.builds[0].buildid).toBeDefined()
            $timeout.flush()
            $httpBackend.verifyNoOutstandingRequest()

        it 'should go to build page if build started', ->
            $stateParams.redirect_to_build = 1
            $httpBackend.expectDataGET('buildrequests/1')
            $httpBackend.expectDataGET('buildsets/1')
            controller = createController()
            $httpBackend.flush()
            $scope.buildrequest.claimed = true
            $httpBackend.expectDataGET 'builds?buildrequestid=1',
                                        nItems:0
            $httpBackend.flush()
            expect($scope.builds.length).toBe(0)
            $httpBackend.expectDataGET 'builds?buildrequestid=1',
                                        nItems:1
            $timeout.flush()
            $httpBackend.flush()
            expect($scope.builds[0].buildid).toBeDefined()
            $timeout.flush()
            $httpBackend.verifyNoOutstandingRequest()
            expect(goneto).toEqual([ 'build', { builder : 2, build : 1 } ])
