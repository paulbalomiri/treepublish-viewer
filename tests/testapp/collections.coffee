


@collections=collections= TP.collections
@links=links= TP.links
arr= [0..20].map (i)-> "col#{i}"
link_prob=.5
link_cap=10
link_specs= [
    col:true
    obj_gen: (o, col_name)->

  ,

  ]
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

@links_code=cs= new CoffeeCode()
@collection_code=cl= new CoffeeCode()
cs.l 'links:'
cs.in() 
for name,i in arr
  cl.l "collections.#{name}=new Meteor.Collection '#{name}'"
  collections[name]=new Meteor.Collection name
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
      switch Random.choice ['bool', 'string', 'object']
        when 'bool'
          cs.l "#{choice}: true"
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
    #cs.out() if links[name]?


