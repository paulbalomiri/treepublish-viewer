
_= lodash
_.extend TP.viewer, 
  default_register_options:
    name_prefix: 'treepublish_'
    graph: '/introspect/graph'
    code: '/introspect/code'
  register: ( opts={})->
    _.defaults opts, TP.viewer.default_register_options
    unless opts.name_prefix?
      opts.name_prefix= ''
    if Meteor.isClient
      handler= Tracker.autorun (c)->
        choice= Session.get('menuchoice')
        unless c.firstRun
          switch choice
            when 'tree' then Router.go opts.name_prefix + 'graph'
            when 'defs' then Router.go opts.name_prefix + 'code'
            else
              Router.go opts.name_prefix + choice
    Router.map ->
      for name, path of _.pick opts ,['graph','code']
        @route name,
          path: path or name
          template: do->
            switch name
              when 'graph' then 'treepublish_view'
              when 'code' then 'treepublish_schema_editor'
    return handler
