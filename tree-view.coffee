
_= lodash
inst_helper= (func)->
  (args...)-> 
    i=Template.instance()
    func.call this,i,args...

env_helper= (func)->
  (args...)-> 
    i=Template.instance()
    func.call this,i.environment.get(),i,args...
do(tmpl=Template.treetest)->
  helpers=
    testgraph:->
      vis= d3.select("#treetest")
            .append("svg");
      vis.args 'height',400
      vis.args 'width',900
  tmpl.helpers helpers
do(tmpl=Template.treepublish_view)->
  make_default_env = ->
    _original_environment:true
    links:TP.links
    collections:TP.collections
  
  tmpl.created=->
    @selected_collection=new ReactiveVar(null)
    self=this
    @environment= share.environment
    unless @environment.get()
      @environment.set make_default_env()
    @subscriptions=
      link_publish_subscription: @data?.link_publish_subscription
    unless @subscriptions.link_publish_subscription
      @subscriptions.link_publish_subscription = Meteor.subscribe 'tp-id-filter'
  tmpl.destroyed= ->
    for name, val of @subscriptions
      if val?
        val.stop
      delete @subscriptions[name]
  tmpl.helpers
    env_name:->
      i=Template.instance()
      i.environment.get().name
    reactive_environment:->
      Template.instance().environment
    selected_collection:->
      Template.instance().selected_collection
  tmpl.events
    'click #show-live': (e,tmpl)->
      tmpl.environment.set make_default_env()
      tmpl.selected_collection.set(null)
do(tmpl=Template.render_collection)->
  tmpl.created=->
    if _.isString(@data.collection)
      @collection_name=new ReactiveVar @data.collection_name
    else
      @collection_name = @data.collection_name
    @environment=@data.reactive_environment
  tmpl.helpers
    collection_name:->
      name= Template.instance().collection_name.get()
      if name?
        return name
      return 
    link_fields: env_helper (e,i)->
      col= i.collection_name.get()
      unless col? and e.links[col]?  
        return 
      else
        ret=[]
        for key, target_collection of e.links[col]      
          link_field_name:key
          target_collection: _.isString(target_collection) and target_collection or false
    
do(tmpl=Template.list_objects)->
  reactive_var_names= ['environment','collection_name', 'selected_id']
  tmpl.created=->
    self= this
    @viewed_obj=new ReactiveVar()
    @objects_in_set=
      ###
      Tristate obj filter:
       true-> is in collection
       false-> is not in collection and not viewed
       "viewed" -> the collapsible is open, and the object is not in the collection
      ###
      get:(obj_id)->
        cur= share.link_publish_collection.find
          'link.link_id':obj_id
        if cur.count() 
          return true
        else if self.viewed_obj.get()==obj_id
          return 'viewed'
        else
          return null
      set:(obj_id, val)->
        if _.isBoolean(val) and val
          old= share.link_publish_collection.findOne
            'link.link_id':obj_id
          unless old
            share.link_publish_collection.insert
              link:
                link_id:obj_id
                link_collection:self.collection_name.get()
          if self.viewed_obj.get()==obj_id
            self.viewed_obj.set(null)
        else
          link= share.link_publish_collection.findOne
              'link.link_id':obj_id
          if val=='viewed'
            self.viewed_obj.set(obj_id)  
          else if not val and self.viewed_obj.get()==obj_id
            self.viewed_obj.set(null)
          if link?
            share.link_publish_collection.remove(link._id)
    @remove_classes={}
    for reactive_var_name in reactive_var_names
      if _.isString @data[reactive_var_name]
        @[reactive_var_name]=ReactiveVar(@data[reactive_var_name])
      else 
        @[reactive_var_name]=@data[reactive_var_name]
    @autorun (c)=>
      @environment.dep.depend()
      @collection_name.dep.depend()
      unless c.firstRun
        console.error('destroying object listing')
        for cname, jq of @remove_classes
          jq.removeClass(cname)
          delete @remove_classes[cname]

  helpers={}
  for   reactive_var_name in reactive_var_names
    helpers[reactive_var_name]= do(name=reactive_var_name)->
      ()->Template.instance()[name]
  _.extend helpers,
    objects: env_helper (e,i)->
      col_name= i.collection_name.get()
      unless col_name and e.collections?[col_name]?
        return
      collection= e.collections[col_name]
      return collection.find()
    object_published_classes: inst_helper (i)->
      switch i.objects_in_set.get(@_id)
        when 'viewed' then 'glyphicon-check viewed'
        when true then 'glyphicon-check'
        else 'glyphicon-unchecked'
      
    collection_name: env_helper (env,inst)->      
      name= inst.collection_name.get()
      if name?
        return name
      return
    links: env_helper (e, inst)-> 
      ret=[]
      links= TP.links_for e.links[inst.collection_name.get()], this
      unless links
        return
      for field , link of links
        ret.push 
          property_name: field
          target_collection: link.link_collection
          target_link: link.link_id
      return ret
  tmpl.helpers helpers
  tmpl.events 
    'mouseenter .object-panel':(e,tmpl)->
      col_name= tmpl.collection_name.get()
      obj= Blaze.getData(e.currentTarget)
      edge_ids= _.compact _.keys(obj).map (k)->
        unless k=='_id'
          return "#"+[col_name, k].join "-"
        return
      tmpl.remove_classes.highlight = $(edge_ids.join(",")).addClass('highlight')
      return 
      
    'mouseleave .object-panel':(e,tmpl)->
      if tmpl.remove_classes.highlight?
        tmpl.remove_classes.highlight.removeClass('highlight')
        delete tmpl.remove_classes.highlight
      return
    'shown.bs.collapse .object-panel':(e,tmpl)->
      col_name= tmpl.collection_name.get()
      obj= Blaze.getData(e.currentTarget)
      unless tmpl.objects_in_set.get(obj._id)
        tmpl.objects_in_set.set(obj._id, 'viewed')
      
      path=[col_name, obj._id ]
      hull=
        set: _.deepSet {} , path, _.omit(obj,'_id')      
        root_keys: _.deepSet {},path,true
      [added,removed]=TP.outer_hull( hull)
      debugger
      # first highlight the selected node
      tmpl.remove_classes['node-primary-highlight']= $("##{col_name}.node").addClass('node-primary-highlight')
      # then highlight the other nodes in the outer hull
      tmpl.remove_classes['node-secondary-highlight'] = $( _.keys(added).map((x)->"##{x}.node").join(','))
        .not(tmpl.remove_classes['node-primary-highlight'])
        .addClass('node-secondary-highlight')
      # and suppress all others
      tmpl.remove_classes['node-suppress'] = $('svg .node')
        .not(tmpl.remove_classes['node-primary-highlight'])
        .not(tmpl.remove_classes['node-secondary-highlight'])
        .addClass('node-suppress')
      edges= []
      for to_col ,o1 of deps
        for to_obj_id, o2 of o1
          for from_col_name, o3 of o2
            for from_id,o4 of o3
              for from_prop_name of o4
                edges.push "#{from_col_name}-#{from_prop_name}"
      edges= _.uniq(edges)
      tmpl.remove_classes['edge-in-dep-set'] = $( edges.map( (x)->"##{x}.edgePath").join ',' ).addClass 'edge-in-dep-set'
      return
    'hidden.bs.collapse .object-panel':(e,tmpl)->
      for c  in ['node-primary-highlight', 'node-secondary-highlight', 'node-suppress', 'edge-highlight','edge-in-dep-set'] 
        tmpl.remove_classes[c]?.removeClass c
      obj= Blaze.getData(e.currentTarget)
      if tmpl.objects_in_set.get(obj._id) == 'viewed'
        tmpl.objects_in_set.set(obj._id, null)
      return
    'click .btn.publish-me': (e,tmpl)->
      obj= Blaze.getData(e.currentTarget)
      if $(e.currentTarget).parents('.panel').find('.panel-collapse.collapse.in').length
        negative_state= 'viewed'
      else
        negative_state= null
      switch tmpl.objects_in_set.get(obj._id)
        when true then tmpl.objects_in_set.set(obj._id, negative_state)
        else tmpl.objects_in_set.set(obj._id, true)
      
      debugger
do(tmpl=Template.collection_graph)->
  mknode=(id)->
    id:id
    _id:id
    name:id      
  tmpl.created=->
    @collection_selector= @data?.collection_selector or new ReactiveVar(null)
    @environment=@data.reactive_environment
    @render=new dagreD3.render()
    @g=new ReactiveVar(null)
    @autorun (c)=>
      e=@environment.get()
      for name, collection of e.collections
        unless name[-TP.viewer.result_collection_appendix.length..-1]==TP.viewer.result_collection_appendix
          # this is not a resultset collection
          continue
        handler= null
        cols_in_resultset= {}
        Tracker.nonreactive ->
          #search the published ids
          cur= collection.find {},
            fields:
              _id:1
          display_name= name[0...-TP.viewer.result_collection_appendix.length]
          handler= cur.observeChanges
            added:(id)->
              console.error "added to resultset: #{id}"
              unless cols_in_resultset[display_name]?
                cols_in_resultset[display_name]=selector=$("svg .node##{display_name}")
                selector.addClass('in-resultset')
            removed:(id)->
              cols_in_resultset[display_name].removeClass('in-resultset')
              delete cols_in_resultset[display_name]
        c.onInvalidate ->
          handler.stop()
          for name, selector of cols_in_resultset
            selector.removeClass('in-resultset')
    @autorun =>
      e=@environment.get()
      g= new dagreD3.graphlib.Graph().setGraph({});
      graph_data=@data?.graph_data or _.clone e.links
      for col of e.collections
        unless col[-TP.viewer.result_collection_appendix.length..-1]==TP.viewer.result_collection_appendix
  
          graph_data[col]?={}
      for collection_name, links of graph_data
        unless g.hasNode(collection_name)
          if collection_name == 'tp_sim_col14'
            debugger
          g.setNode collection_name , _.omit(mknode(collection_name),'_id')
        for link_property, linked_collection of links
          val= TP.get_collection_name_from_link_spec(linked_collection)
          if val == '__any__'
            linked_collections= _.keys(graph_data).map mknode
          else if _.isString val
            linked_collections= [mknode(val)]
          for node in [linked_collections...]
            unless node._id?
              debugger
            unless g.hasNode(node._id)
               if node._id == 'tp_sim_col14'
                  debugger
              g.setNode node._id, _.omit(node), '_id'

          for linked_collection in linked_collections
            prop_name= "#{collection_name}.#{link_property}[target:#{linked_collection._id}]"
            g.setEdge collection_name, linked_collection._id, 
              id: [collection_name, prop_name].join('-')
              label: prop_name
              classed: do ->
                switch val
                  when '__any__' 
                    'possible-edge':true
                  else ''
      g.nodes().forEach (v)->
        node = g.node(v);
        node.rx = node.ry = 5;
      @g.set(g)
  tmpl.rendered=->
    @autorun =>
      @svg=d3.select(@find('svg.link_graph'))
      @inner= inner= @svg.select('g')
      @zoom = d3.behavior.zoom().on "zoom", ->
        inner.attr("transform", "translate(#{d3.event.translate}) scale(#{ d3.event.scale})");
      @svg.call(@zoom)
      
      @render(@inner,@g.get())
      initialScale=.75
      #@svg.attr('height', @g.graph().height * initialScale + 40);
      self= this
  tmpl.events
    'mouseenter .node':(e,tmpl)->
      $(e.currentTarget).children('rect').css
        fill:"red"
      tmpl.collection_selector.set e.currentTarget.id

    'mouseleave .node':(e,tmpl)->
      $(e.currentTarget).children('rect').css
        fill:""
      
      
  helpers= {}
  tmpl.helpers helpers