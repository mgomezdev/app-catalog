Ext = window.Ext4 || window.Ext

Ext.require [
  'Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper'
  'Rally.apps.roadmapplanningboard.Writer'
  'Rally.apps.roadmapplanningboard.Proxy'
  'Rally.apps.roadmapplanningboard.Model'
  'Rally.data.Field'
  'Rally.apps.roadmapplanningboard.AppModelFactory'
]

describe 'Rally.apps.roadmapplanningboard.Writer', ->

  helpers
    createRequest: (records) ->
      operation:
        records: records
      records: records

  beforeEach ->

    Rally.test.apps.roadmapplanningboard.helper.TestDependencyHelper.loadDependencies()

    @field = Ext.create 'Rally.data.Field',
        name: 'collectionField'
        type: 'collection'
    @Model = Ext.define Rally.test.generateName(),
      extend: 'Rally.apps.roadmapplanningboard.Model'
      fields: [ @field,
        name: 'id'
        type: 'string'
        persist: false
      ,
        name: 'ref'
        type: 'string'
        persist: false
      ,
        name: 'somefield'
        type: 'string'
      ]
      proxy:
        type: 'roadmap'
        url: 'someurl'

    @record = new @Model
      id: 'foo'
      ref: 'myRef'
      collectionField: [{id: 1}, {id :2}]
    @record.phantom = false # pretend the record is persisted

    @writeSpy = @spy @record.getProxy().getWriter(), 'write'
    @ajax.whenCreating('collectionField', false).respondWith({})
    @ajax.whenDeleting('collectionField', '1', false).respondWith({})

    @writer = Ext.create('Rally.apps.roadmapplanningboard.Writer')
    @stub @writer, 'writeRecords', (request) -> request

  describe 'when changing data', ->

    beforeEach ->
      @record.set 'somefield', 'newValue'
      @record.save()

    it 'should set the action to update', ->
      expect(@writeSpy.lastCall.returnValue.action).toBe 'update'

    it 'should send the correct data', ->
      expect(@writeSpy.lastCall.returnValue.jsonData).toEqual { id: 'foo', somefield: 'newValue' }

  describe 'when removing from collection relationship', ->

    beforeEach ->
      @record.set 'collectionField', [{id: 1}]
      @save = =>
        @record.save()

    it 'should call the write method', ->
      @save()
      expect(@writeSpy).toHaveBeenCalledOnce()

    it 'should set urlParams on request', ->
      @save()
      returnValue = @writeSpy.lastCall.returnValue
      expect(returnValue.urlParams).toEqual returnValue.params

    it 'should set the url correctly', ->
      @save()
      expect(@writeSpy.lastCall.returnValue.url).toBe 'someurl/collectionField/2'

  describe 'when adding to collection relationship', ->

    beforeEach ->
      @newValue = [{id: 1}, {id: 2}, {id: 3}]
      @record.set 'collectionField', @newValue
      @record.save()

    it 'should call the write method', ->
      expect(@writeSpy).toHaveBeenCalledOnce()

    it 'should set the url correctly', ->
      expect(@writeSpy.lastCall.returnValue.url).toBe 'someurl/collectionField'

    it 'should send the correct data', ->
      expect(@writeSpy.lastCall.returnValue.jsonData).toEqual {id: 3}
