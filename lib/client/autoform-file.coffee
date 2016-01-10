AutoForm.addInputType 'fileUpload',
  template: 'afFileUpload'
  valueOut: ->
    @val()

getCollection = (context) ->
  if typeof context.atts.collection == 'string'
    FS._collections[context.atts.collection] or window[context.atts.collection]

getDocument = (context) ->
  console.log(Template.instance())
  #  console.log(@)
  collection = getCollection context
  #console.log Template.instance()
  id = Template.instance()?.value?.get?()
  #  console.log(@);
  console.log id
  collection?.findOne(id)

Template.afFileUpload.onCreated ->
  self = @
  @value = new ReactiveVar @data.value

  @_stopInterceptValue = false
  @_interceptValue = (ctx) =>
#    console.log 'ctx.value'
#    console.log ctx.value
#    console.log @_stopInterceptValue
    unless @_stopInterceptValue
      t = Template.instance()
      #      console.log t
      if t.value.get() isnt false and t.value.get() isnt ctx.value and ctx.value?.length > 0
        console.log('t.value.get()')
        console.log(t.value.get())
        #        t.value.set ctx.value
        ctx.value = t.value.get()
        @_stopInterceptValue = true

  @_insert = (file) ->
    collection = getCollection self.data
    #    console.log collection
    if Meteor.userId
      file.owner = Meteor.userId()

    if typeof self.data.atts?.onBeforeInsert is 'function'
      file = (self.data.atts.onBeforeInsert file) or file

    collection.insert file, (err, fileObj) ->
#      console.log fileObj
#      console.log err
      if typeof self.data.atts?.onAfterInsert is 'function'
        self.data.atts.onAfterInsert err, fileObj

      if err then return console.log err
#      console.log '_inert'
#      console.log fileObj._id
      #      console.log self.value.get()
      #      console.log @value.get()
      #      t.value.set fileObj._id

      self.value.set fileObj._id
      #      @value.set fileObj._id

      console.log 'after set'
      console.log self.value.get()

  @autorun ->
    _id = self.value.get()
    _id and Meteor.subscribe 'autoformFileDoc', self.data.atts.collection, _id

Template.afFileUpload.onRendered ->
  self = @
  $(self.firstNode).closest('form').on 'reset', ->
    self.value.set false

Template.afFileUpload.helpers
  label: ->
    @atts.label or 'Choose file'
  removeLabel: ->
    @atts.removeLabel or 'Remove'
  value: ->
    doc = getDocument @
    doc?.isUploaded() and doc._id
  schemaKey: ->
    @atts['data-schema-key']
  previewTemplate: ->
    @atts?.previewTemplate or if getDocument(@)?.isImage() then 'afFileUploadThumbImg' else 'afFileUploadThumbIcon'
  previewTemplateData: ->
    console.log('2. previewTemplateData');
    #    Template.instance()._interceptValue @
    file: getDocument @
    atts: @atts
  file: ->
    console.log '1. file'
    Template.instance()._interceptValue @
    getDocument @
  removeFileBtnTemplate: ->
    @atts?.removeFileBtnTemplate or 'afFileRemoveFileBtnTemplate'
  selectFileBtnTemplate: ->
    @atts?.selectFileBtnTemplate or 'afFileSelectFileBtnTemplate'
  uploadProgressTemplate: ->
    @atts?.uploadProgressTemplate or 'afFileUploadProgress'

Template.afFileUpload.events
  'click .js-af-select-file': (e, t) ->
#    t.value.set false
    t.$('.js-file').click()

  'change .js-file': (e, t) ->
    console.log 'onChange'
    console.log e.target.files[0]
    t._insert e.target.files[0]

  "dragover .js-af-select-file": (e) ->
    e.stopPropagation()
    e.preventDefault()

  "dragenter .js-af-select-file": (e) ->
    e.stopPropagation()
    e.preventDefault()

  "drop .js-af-select-file": (e, t) ->
    e.stopPropagation()
    e.preventDefault()
    t._insert new FS.File e.originalEvent.dataTransfer.files[0]

  'click .js-af-remove-file': (e, t) ->
    e.preventDefault()
    #console.log('onRemove')
    #console.log(t.value)
    #console.log(@_stopInterceptValue)
    t.value.set false

Template.afFileUploadThumbImg.helpers
  url: ->
    console.log Template.instance()
    @file.url store: @atts.store

Template.afFileUploadThumbIcon.helpers
  url: ->
    @file.url store: @atts.store
  icon: ->
    switch @file.extension()
      when 'pdf'
        'file-pdf-o'
      when 'doc', 'docx'
        'file-word-o'
      when 'ppt', 'avi', 'mov', 'mp4'
        'file-powerpoint-o'
      else
        'file-o'
