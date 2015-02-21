_= lodash
class CoffeeCode
    constructor:( @buf="", @indent=0, @indent_chars="  ")->
    l:(code, indent=0)->
      unless @buf=="" or @buf[@buf.length-1] == '\n'
        @buf+= "\n"
      for l in code.split '\n'
        for i in [0..@indent+indent]
          @buf+=@indent_chars
        @buf+=code
    c:(code,indent=0)->
      for l, idx in code.split("\n")
        if idx==0 and l[0]!="\n"
          @buf += l
        else
          @l(l,indent)
    in:(n=1)->@indent+=n
    out:(n=1)->Math.max @indent-=n, 0
    val:->@buf
generate_random_schema= (args)->
  collections= {}
  links = {}
  
  link_prob= parseFloat args.link_prob
  link_cap= parseInt args.link_cap
  collection_count= parseInt args.collection_count
  link_specs= [
      col:true
      obj_gen: (o, col_name)->

    ,

    ]
  arr= [0..collection_count].map (i)-> "col#{i}"
  @links_code=cs= new CoffeeCode()
  @collection_code=cl= new CoffeeCode()
  cs.l '_.extend links,'
  cs.in()
  collections= {}
  for name,i in arr
    cl.l "collections.#{name}=new Meteor.Collection '#{name}'"
    collections[name]={}
    rnd= Random.fraction()
    if rnd < link_prob
      number_of_links= Math.round (rnd/link_prob*arr.length)
      generic_link_count= 0
      for j in [0..number_of_links]
        
        
        #console.log number_of_links
        choice = Random.choice arr
        unless links[name]?
          cs.l "#{name}:"
          links[name]={} 
        cs.in()
        cs.l  "link_to_#{choice}:"
        cs.in()
        switch Random.choice [ 'string', 'object']
          when 'string'
            cs.c "'#{choice}'"
          when 'object'
            
            switch Random.choice ['by_col', 'by_type', 'string', 'object'] 
              
              when 'by_col'
                cs.l "target:"
                switch Random.choice ['fixed_string', 'fixed_instance', 'default_string', 'default_instance']
                  when 'fixed_string'
                    cs.l "fixed: '#{choice}'",1
                  when 'fixed_instance'
                    cs.l "fixed: collections.#{choice}",1
                  when 'default_string'
                    cs.l "default:'#{choice}'", 1
                  when 'default_instance'
                    cs.l "default: collections.#{choice}",1
              when 'by_type'
                cs.l "type:"
                switch Random.choice ['fixed_string',  'default_string']
                  when 'fixed_string'
                    cs.l "fixed: '#{choice}:ref'",1
                  when 'default_string'
                    cs.l "default:'#{choice}:ref'", 1

              when 'string'
                cs.c "'#{choice}'"
              when 'object'
                cs.c "collections.#{choice}"
        cs.out(2)

        links[name]["link_to_#{choice}"]=choice
  ret=
    files:
      collections:
        data: collections
        generator: 'random'
        content:
          coffee: cl.val()
          js: coffee.compile cl.val(),
            bare:true
      links:
        data: links
        generator:'random'
        content:
          coffee: cs.val()
          js: coffee.compile cs.val() ,
            bare:true
file_order= (doc)->
  return [
    ['collections', 'js']
    ['links', 'js']
  ]


rnd_snd = ->
  Random.fraction() * 2 - 1 + Random.fraction() * 2 - 1 + Random.fraction() * 2 - 1
rnd = (mean, stdev) ->
  Math.round rnd_snd() * stdev + mean
choice_discrete= (max= 1, min= 0, mean= (max-min)/2, stdev=mean )->
  index= null
  while (not index?) or index < 0 or index>(max-min)
    index = rnd(mean,stdev)
  return index+min

choice = (arrayOrString,mean,stdev) ->
  index = choice_discrete arrayOrString.length-1, mean,stdev
  
  if typeof arrayOrString == 'string'
    arrayOrString.substr index, 1
  else
    arrayOrString[index]

generate_fixtures_default_opts=
  link_fields_to_fixture_num: 3
  link_field_usage_probability: .5
  generic_link_for_dlink_with_default:.3
  
generate_fixtures= (links,collections, opts={})->
  _.defaults opts, generate_fixtures_default_opts
  get_col_name= (col)->
    if _.isString(col)
      return col
    else
      return col._name
  fixtures= {}
  code= new CoffeeCode()
  for c_name of collections

    f= links[c_name] or {}
    fixtures[c_name]?= _.range(choice_discrete(opts.link_fields_to_fixture_num*_.keys(f).length)+1).map ->
        ret=
          _id: Random.id()
        for key,target_col of f
          if Random.fraction() <= opts.link_field_usage_probability
            if _.isBoolean target_col and target_col
              ret[key]='__any__'
            else if _.isString target_col
              ret[key]=target_col
            else if _.isObject target_col
              if target_col.target?
                if target_col.target.fixed?
                  ret[key]= target_col.target.fixed.args?[0] or target_col.target.fixed
                else if target_col.target.default?
                  if Random.fraction() < opts.generic_link_for_dlink_with_default
                    ret[key]='__any__'
                  else
                    ret[key]=target_col.target.default.args?[0] or target_col.target.default
              else if target_col.type?
                if target_col.type.fixed? 
                  ret[key]= target_col.type.fixed.split(":")[0...-1].join(":")
                else if target_col.type.default?
                  if Random.fraction() < opts.generic_link_for_dlink_with_default
                    ret[key]== '__any__'
                  else
                    ret[key]= target_col.type.default.split(":")[0...-1].join(":")

        return ret
  code.l "_.extend fixtures, "
  code.in()
  for col , content of fixtures
    code.l "#{col}: ["
    code.in()
    first=true
    for fixture in content
      if first
        first= false
      else
        code.l ","
      code.in()
      for link_field, target_col of fixture
        if link_field =='_id'
          code.l "_id: '#{target_col}'"
        else
          if target_col == '__any__'
            target_col= Random.choice _.keys fixtures
            fixture[link_field]=
              link_collection: target_col 
              link_id: Random.choice _.pluck fixtures[target_col] , '_id'
            code.l "#{link_field}:"
            code.l "link_collection: '#{target_col}'" ,1
            code.l "link_id: '#{fixture[link_field].link_id4}'",1
            
          else
            fixture[link_field]= Random.choice _.pluck fixtures[target_col] , '_id'
            code.l "#{link_field}: '#{fixture[link_field]}'"
      code.out()
    code.out()
    code.l "]"
  ret= 
    data: fixtures
    content: code.val()
  return ret
generate_fixtures_from_eval= (id_or_doc,options={})->
  if _.isString id_or_doc
    doc = share.doc_collection.find('id')
    update= true
  else
    doc= id_or_doc
    update= false
  links={}
  collections={}
  Meteor= {}
  class Meteor.Collection
    __is_meteor_mock__:true
    constructor: (@args...)->
  for [file,type ] in file_order(doc)
    eval doc.files[file].content[type]
  fixtures= generate_fixtures links,collections
  doc.files.fixtures=
    data: fixtures.data
    content:
      coffee: fixtures.content
      js: coffee.compile fixtures.content,
        bare:true
  if update and doc._id
    collections.doc_collection.update doc._id ,
      $set: 
        'files.fixtures':doc.files.fixtures
  return doc
Meteor.methods
  generate_random_schema: (args)->
    ret= generate_random_schema(_.omit args, ['name'])
    doc= _.extend ret, _.pick args, 'name'
    generate_fixtures_from_eval(doc)
    id= share.doc_collection.insert doc
    return id 

