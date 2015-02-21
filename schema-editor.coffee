inst_helper= (func, args...)->
    ->
      i=Template.instance()
      func.call this,i,args...
do(tmpl=Template.treepublish_schema_editor) ->
  

  tmpl.created= ->
    self=this
    @ready=new ReactiveVar(false)
    @cur_doc_id = new ReactiveVar(null, ->false)
    @select_val = new ReactiveVar(null)
    @reactive_doc= new ReactiveVar(null)
    @autorun ->
      Meteor.subscribe 'treepublish-viewer-schemas',
        onReady: ->
          if cur_doc= share.doc_collection.findOne()
            self.cur_doc_id.set cur_doc._id
            
          self.ready.set(true)
    @modified_code=new ReactiveVar(false)
    @modified_name=new ReactiveVar(true)
    @modified=new ReactiveVar(true)
    @modified_computation=null
    @autorun (c)->
      if self.ready.get()
        id= self.cur_doc_id.get()
        doc= share.doc_collection.findOne(id)
        console.error 'setting doc treepublish_schema_editor'
        self.reactive_doc.set doc
        if  self.modified_computation? 
          self.modified_computation.stop()
        self.modified_code.set false
        self.modified_computation = Tracker.autorun (comp)=>
          self.reactive_doc.dep.depend()
          unless comp.firstRun
            self.modified_code.set true
    
    @docs= share.doc_collection.find()
    
  tmpl.rendered=->
    
    @autorun =>
      [code,name] = [@modified_code.get() ,@modified_name.get()]
      @modified.set (name or code)
    @autorun =>
      id = @cur_doc_id.get()
      if id
        doc= share.doc_collection.findOne id
        if doc
          $(@find('input.doc-edit.name')).val(doc.name)
          for v in [@modified_code, @modified_name]
            v.set false
          @select_val.set id

  tmpl.helpers
    ready:->
      debugger
      Template.instance().ready.get()
    editor_options:->
      ret=
        lineNumbers:true
        mode: 'coffeescript'
    cur_doc_name:->
      i= Template.instance()
      return i.reactive_doc.get().name
    modified: inst_helper (i)->
      i.modified.get()
    doc_edit: ->
      i= Template.instance()
      return i.reactive_doc.get()
    schemas:->
      i=Template.instance()
      return i.docs
    sel_opt_dyn_attr: inst_helper (i)->
      if @_id == i.reactive_doc.get()?._id
        selected: "selected"

    save_classes:->
      unless Template.instance().modified.get()
        return "disabled"
    load_classes:->
      i=Template.instance()
      if i.select_val.get() == i.reactive_doc.get()._id and (not i.modified.get())
        return "disabled"
    load_label:->
      i=Template.instance()
      if i.select_val.get() == i.reactive_doc.get()._id
        if i.modified.get()
          return 'Reload'
        else
          return 'Reload(Unchanged)' 
      else
        return 'Load'
    doc_reactive_id:->
      Template.instance().cur_doc_id
    reactive_doc: inst_helper (i)->
      i.reactive_doc
    delete_label:->
      i=Template.instance()
      sel = share.doc_collection.findOne i.select_val.get()
      return "'#{sel.name}'"
        

  tmpl.events
    'keyup input.doc-edit.name' : (e,tmpl)->
      debugger
      tmpl.modified_name.set $(e.currentTarget).val()!=tmpl.i.reactive_doc.get().name
    'change select#doc-select': (e,tmpl)->
      tmpl.select_val.set e.currentTarget.value
    'click #show-graph':(e,tmpl)->
      share.replace_environment  tmpl.reactive_doc.get()
      Session.set 'menuchoice', 'tree-menu'
    'click .btn.doc-edit':(e,tmpl)->
      target=$(e.currentTarget) 
      name_input= target.parents('form').first().find('input.doc-edit.name')
      name=name_input.val()
      debugger
      if target.hasClass 'save'
        cur_doc=tmpl.reactive_doc.get()
        if target.hasClass 'new'
          new_doc= _.omit(cur_doc, ['_id'])
          new_doc.name= name
          new_doc._id= share.doc_collection.insert new_doc
          cur_doc_id.set new_doc._id
        else
          share.doc_collection.update cur_doc._id, 
            $set: _.omit cur_doc , '_id'              
      else if target.hasClass 'load'
        doc_select = target.parents('form').first().find('#doc-select')
        tmpl.cur_doc_id.set doc_select.val()

      else if target.hasClass 'delete'
        share.doc_collection.remove(tmpl.select_val.get())
        if tmpl.select_val.get() == tmpl.cur_doc_id.get()
          cur_doc= share.doc_collection.findOne()
          tmpl.cur_doc_id.set(cur_doc._id)
do(tmpl= Template.treepublish_random_schema_generator)->
  tmpl.created=->
    @generating=new ReactiveVar(false)
    @cur_doc_id = @data?.doc_reactive_id or new ReactiveVar(null)
    @errors=new ReactiveVar([])
    @generator_defaults=
      name: "Random schema"
      link_prob:.3
      link_cap:10
      collection_count:20
    self=this
    ###
    @autorun ->
      self.errors.dep.depend()
      self.generating.set(false)
    ###
    @autorun =>
      id=@cur_doc_id.get()
      if id?
        @cur_doc= share.doc_collection.findOne(id)
      @values= _.defaults {} , @cur_doc?.generator_defaults or  @generator_defaults , @generator_defaults
  
  param_gen= (name)->
    coffee_name = name.replace('-','_')
    ret= {
      helper:{}
    }
    
      
    ret.helper["#{coffee_name}_default"] = ->
        i= Template.instance()
        debugger
        return i.values?[coffee_name] or i.generator_defaults?[coffee_name] or ""
    ret.getter=(tmpl)->
        ret={} 
        ret[coffee_name]=tmpl.find("##{name}").value
        return ret
    return ret

  params= ['link-prob','link-cap', 'collection-count', 'name'].map (x)->param_gen(x)
  
  helpers= 
    generating: ->
      i=Template.instance()
      i.generating.get()

    errors:->
      debugger
      i=Template.instance()
      ret=i.errors.get()
      if ret? and ret.length
        return ret.map (error)->
          text:error
      else
        return
  helpers= _.extend (helpers or {}), _.pluck(params, 'helper')...

  param_getter= (tmpl)->
    _.extend {}, _.pluck(params, 'getter').map((g)->g(tmpl) )...

  tmpl.helpers helpers
  tmpl.events
    'click .action.generate-new': (e,tmpl)->
      form_params= param_getter tmpl

      tmpl.generator_defaults = _.clone form_params
       
      r=/(.*[^0-9])([0-9]+)$/
      if m= r.exec(tmpl.generator_defaults.name )
        tmpl.generator_defaults.name  = m[1] + (parseInt(m[2])+1)
      else
        tmpl.generator_defaults.name  += " #2"
      tmpl.errors.set([])
      
      tmpl.generating.set(true)
      timeout= 3000
      to_handler= Meteor.setTimeout (()->tmpl.errors.get().push("#{new Date()}:The operation timed out without a result after #{timeout/1000}s!"); tmpl.generating.set(false)), timeout
      Meteor.call 'generate_random_schema', form_params, ( error,new_schema_id)->
        Meteor.clearTimeout(to_handler)
        tmpl.generating.set(false)
        if error
          tmpl.errors.get().push "#{new Date()}:"+error
        else
          tmpl.cur_doc_id.set(new_schema_id)

do(tmpl=Template.treepublish_schema_viewer)->
  
  tmpl.created= ->
    @reactive_doc=@data.reactive_doc
    self= this
    @active_file= new ReactiveVar(null, ->false)
    @active_type= new ReactiveVar(null, ->false)
    
    @reactive_doc_id =new ReactiveVar(null)
    @autorun ->
      doc = self.reactive_doc.get()
      if doc?._id
        self.reactive_doc_id.set(doc._id)
      else
        self.reactive_doc_id.set(null)
    @autorun =>
      #set file
      self.reactive_doc_id.dep.depend()
      doc= null
      Tracker.nonreactive ->
        doc = self.reactive_doc.get()
      if doc?
        file = _.keys(doc.files)[0]
        self.active_file.set(file)
    @autorun ->
      #set file type
      active_file = self.active_file.get()
      debugger
      Tracker.nonreactive ->
        active_type = self.active_type.get()
        cur_doc=self.reactive_doc.get()
        if cur_doc?
          if cur_doc?.files?[active_file]?.content?[active_type]?
            self.active_type.dep.changed()
          else 
            self.active_type.set _.keys(cur_doc.files[active_file].content)[0]
    content_watch_handler=null
    @autorun ->
      debugger
      #set editor contents (file type change)
      type=self.active_type.get()
      Tracker.nonreactive ->
        unless self.reactive_doc.get()?
          return
        
        if content_watch_handler? 
          content_watch_handler.stop()
        Session.set 'content_editor_text' , self.reactive_doc.get().files[self.active_file.get()].content[self.active_type.get()]
    
        content_watch_handler = self.autorun (c)->
          #Content change reactivity
          [active_file, active_type] = []
          doc= null
          Tracker.nonreactive ->
            [active_file, active_type] = [self.active_file.get(), self.active_type.get()]
            doc= self.reactive_doc.get()
          if doc?
            doc.files[active_file].content[active_type] = Session.get('content_editor_text')
            unless c.firstRun
              console.error "setting reactivity treepublish_schema_viewer"
              self.reactive_doc.set doc
  tmpl.helpers
    tab_titles: ->
    id: inst_helper (i)->
      return i.reactive_doc.get()?._id
    file_tab: inst_helper (i)->
      ret_l=[]
      active= i.active_file.get()
      for key, val of  i.reactive_doc.get().files
        ret=
          key:key
          active: key==active
          name: val.base_name or key
          file_tab_classes: key==active and "active" 
        ret_l.push ret
      return ret_l

    file_type_tab: inst_helper (i)->
      ret= []
      file= i.active_file.get()
      active_type= i.active_type.get()
      for key, f of i.reactive_doc.get().files[file].content
        key:key
        active: key==active_type 
        file_type_tab_classes: key==active_type and "active"
        name: "#{file}.#{key}"
        content: f
  tmpl.events
    'click #file-tab a[role="tab"]':(e,tmpl)->
      debugger
      tmpl.active_file.set Blaze.getData(e.currentTarget).key
      return
    'click #file-type-tab a[role="tab"]':(e,tmpl)->

      tmpl.active_type.set Blaze.getData(e.currentTarget).key
      
          
