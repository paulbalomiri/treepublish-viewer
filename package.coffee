

Package.describe
  name:"pba:treepublish-viewer"
  description: "creates the base package for the entity system"
Npm.depends 
  "coffee-script": "1.7.1"
  #'fs':"0.2.2"
Package.on_use (api)->
  client= 'client'
  server= 'server'
  both= [client, server]
  both_f= [
    'common.coffee'
    'tree-view.jade'
    'schema-editor.jade'
    'zip-downloader.jade'
    'iron_router.jade'
    'iron_router.coffee'
  ]
  client_f= [
      'style-sheet-generator.coffee'
      'tree-view.coffee'
      'schema-editor.coffee'
      'schema-editor.less'
      'zip-downloader.coffee'
      'extlib/dagre-d3.js'
      'tree-view.less'

      ]
  server_f= ['code-generator.coffee']
  api.use [

      'reactive-var'
      'reactive-dict'
      'mizzao:bootstrap-3@3.3.1_1'
      'pba:zipzap@0.0.0'
      'pba:jquery-svg-class'
      'templating'
      'entity-base'
      'perak:codemirror@1.2.2'
      ], client

  api.use [
    'matb33:collection-hooks@0.7.9'
    'coffeescript'
    'alethes:lodash@0.7.1'
    'mquandalle:jade@0.4.1'
    'pba:treepublish-collection2' 
    'less@1.0.12'
    'aldeed:simple-schema@1.3.0'
    'aldeed:collection2@2.3.2'
    'session'
  ], both
  api.use 'iron:router' , both, 
    weak: true
  api.export 'coffee'
  api.imply 'd3@1.0.0'

  #api.use [ 'coffeescript','underscore', 'meteor', 'blaze','spacebars-compiler', 'jade'], both
  #api.add_files 'entity-base.coffee.md' , both
  api.add_files both_f, both
  api.add_files server_f, server
  api.add_files client_f,client
