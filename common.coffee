_= lodash
share.doc_collection = new Meteor.Collection('doc_collection')

TP.viewer= _.extend TP.viewer or {} , 
  result_collection_appendix: '_result'
  get_env:->
    if Meteor.isClient
      prefix= share.environment?.get()
    else
      prefix= share.environment
  get_prefix: ->
    return TP.viewer.get_env()?.collection_name_prefix
  tp_funcs:
    get_collection_name: (collection)->
      prefix=TP.viewer.get_prefix()     
      if prefix and collection?._name? and collection._name.indexOf(prefix)==0
        return collection._name.slice(prefix.length)
      return
    get_collection_by_name: (name)->
      env=TP.viewer.get_env()
      return env.collections?[name]
    get_links_definition:(collection_name)->
      env=TP.viewer.get_env()
      return env.links?[collection_name]
TP._collection_name_getters.unshift TP.viewer.tp_funcs.get_collection_name
TP._collection_getters.unshift TP.viewer.tp_funcs.get_collection_by_name
TP._links_definition_getters.unshift TP.viewer.tp_funcs.get_links_definition

if Meteor.isClient
  share.environment= new  ReactiveVar(null)
  share.global_collection_stock={}
else
  share.environment= _.extend {_original_environment:true}, 
    collections: TP.collections
    links:TP.links
share.replace_environment= (doc, collection_prefix='tp_sim_')->
  if Meteor.isClient
    old= share.environment.get()
  else
    old= share.environment
  unless old._original_environment
    for name, col of old.collections
      col.find().map (x)->
        col.remove x._id
    for key of old
      delete old[key]
  if Meteor.isClient
    if subscription?
      for subscription in old.subscriptions
        subscription.stop()

  env= share.make_environment doc, collection_prefix
  if Meteor.isClient
    share.environment.set env
  else
    share.environment = env
  env.collection_name_prefix= collection_prefix
  if Meteor. isClient
    env.subscriptions= [
      Meteor.subscribe 'tp-environment', doc?._id or null
    ]
  return env
share.make_environment =  (doc,collection_prefix='tp_sim_')->
  unless doc?
    ret= 
      _original_environment: true
      collections:TP.collections
      links:TP.links
    return ret
  real_collection= Meteor.Collection
  do(isServer=Meteor.isServer) ->
    Meteor= 
      isServer:isServer
      isClient:not isServer
    class Meteor.Collection
      constuctor:(@_name)->
    ret=
      name: doc.name
      collections:collections={}
      links:links={}
      fixtures: fixtures={}
    eval doc.files.collections.content.js
    for name, impl of collections
      if Meteor.isClient
        
        # now create two collections, one for publishing everything, and one for publishing only changed contents.
        # note that modifying the result collection has no effect on the server side
        # share.global_collection_stock is needed as a collection name can only be provided once to a collection constructor 
        for col_name in [name, "#{name}#{TP.viewer.result_collection_appendix}"]
          collections[col_name]= share.global_collection_stock[col_name]?= new real_collection(collection_prefix+col_name)
        
      else
        collections[name] = new real_collection(null)
        collections[name]._name= name
    eval doc.files.links.content.js
    if Meteor.isServer
      #only on the server evaluate the fixtures (will be published)
      eval doc.files.fixtures.content.js
      for col , objects of fixtures
        for fixture in objects
          collections[col].insert fixture
    return ret

if Meteor.isServer
  Meteor.publish 'tp-environment', (doc_id, collection_prefix='tp_sim_')->
    doc= share.doc_collection.findOne(doc_id)
    unless doc?
      return
    env= share.replace_environment doc, ""
    observers= {}
    sub= this
    console.error this
    for name,col of env.collections
      do (name=collection_prefix+name)->
        observers[name]= col.find().observeChanges
          added: (id,fields)->
            console.log "added",name,id,fields
            sub.added name, id, fields
          changed: (id,fields)->
            console.log "changed",name,id,fields
            sub.changed name,id,fields 
          removed: (id)-> 
            console.log "removed",name
            sub.removed name,id
    @onStop ->
        for key, handle of observers
          handle.stop()
share.link_publish_collection= new Meteor.Collection('link_publish_collection')
TP.viewer.link_publish_collection= share.link_publish_collection
share.link_publish_collection.attachSchema
  link:
    type:Object
    link: true

share.link_publish_collection.allow 
  insert: ->true
  remove: ->true
  update:->true
if Meteor.isServer
  getInvocation=->
    DDP._CurrentInvocation.get()
  getCurrentConnectionId = ->
    getInvocation()?.connection?.id
  share.link_publish_collection.before.insert ( user_id, doc)->
    connection_id= getCurrentConnectionId()
    doc.connection_id= connection_id
    return
  publish_opts=
    name:'tp-id-filter'
    out_collection_name: (orig)->
      if orig == "link_publish_collection"
        return orig
      return "tp_sim_#{orig}#{TP.viewer.result_collection_appendix}"
  TP.publish publish_opts, (prefill=true)->
    sub= this
    obs= share.link_publish_collection.find({connection_id: this.connection.id}).observeChanges
      added:(args...)->
        sub.added('link_publish_collection',args...)
      removed:(args...)->
        sub.removed('link_publish_collection',args...)
      changed:(args...)->
        sub.changed('link_publish_collection',args...)
    @onStop ->
      obs.stop()

coffee=
  doc_collection: share.doc_collection
if Meteor.isServer
  share.doc_collection.allow 
    insert: -> true
    update: -> true
    remove: -> true

  Meteor.publish 'treepublish-viewer-schemas', ->
    share.doc_collection.find()
  coffee= Npm.require('coffee-script')
