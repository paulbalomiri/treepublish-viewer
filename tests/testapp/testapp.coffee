_ = lodash
if Meteor.isClient
  do(tmpl=Template.simplepage)->
    tmpl.created=->
      @menu=[
          name: 'Tree'
          template: Template.treepublish_view
        ,
          name: 'Defs'
          template: Template.treepublish_schema_editor
      ].map (e)->
        e.link_id= e.name.toLowerCase()+"-menu"
        return e
      Session.set 'menuchoice', @menu[0].link_id 
      self=this
    tmpl.helpers
      menu:->
        Template.instance().menu
      menuchoice:->
        Session.get 'menuchoice'
      template:->
        inst= Template.instance()
        active= Session.get 'menuchoice'
        for e in inst.menu
          if e.link_id==active
            return e.template
  do(tmpl=Template.navbar)->
    tmpl.created=->
      @menu= @data.menu
    tmpl.helpers
      nav_list_link: ->
        inst= Template.instance()
        active= Session.get 'menuchoice'
        return inst.menu.map (entry)->
          entry= _.cloneDeep(entry)
          if active==entry.link_id
            entry.list_entry_classes= 'active'
          return entry

      menu:->
        Template.instance().menu
        
      menuchoice:->
        Session.get 'menuchoice'
    tmpl.events
      'click a.navbar-link':(e,tmpl)->
        Session.set 'menuchoice', e.currentTarget.id
        e.preventDefault()