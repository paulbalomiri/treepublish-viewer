_= lodash

default_tmpl_vars=
  version: '0.0.0'
  both_dep: []
  both_f: []
  client_dep:[]
  client_f:[]
  description:[]
  name: "NONAME_package" 
  server_dep:[]
  server_f:[]
  exports_c:[]
  exports_s:[]
  exports_both:[]
project_js_template = "var "
first= true
for key of default_tmpl_vars
  if first
    first=false
  else
    project_js_template += ","
  project_js_template += key
project_js_template += ";\n"
for key of default_tmpl_vars
  project_js_template += "#{key} = ${JSON.stringify(#{key})};\n"
project_js_template += '''
Package.describe({
  name: package_name,
  description: description,
  version: version
});

Package.on_use(function(api) {
  api.use(both_dep, ['client', 'server']);
  api.use(server_dep, 'server');
  api.use(client_dep, 'client');
  api["export"](exports_c, 'client');
  api["export"](exports_s, 'server');
  api["export"](exports_both, ['client','server']);
  api.add_files(both_f, ['client', 'server']);
  api.add_files(server_f, 'server');
  return api.add_files(client_f, 'client');
});

  '''
default_file_dirs=
  collections: 'schema'
  links:'schema'
  fixtures:'fixtures'
do(tmpl=Template.treepublish_zip_generator)->
  tmpl.events 'click #zip-download': (e,tmpl)->
    
    doc= tmpl.data.reactive_doc.get()
    zip = new ZipZap();
    package_dir= doc.name.toString().replace('_',"-").replace(" " , "-")
    content_file_names= {}
    for base_name, file of doc.files
      sub_dir= file.subdir or default_file_dirs[base] or ''
      
      if file.content.coffee?
        filename= "#{package_dir}/#{sub_dir}/#{base_name}.coffee"
        filename.replace "//", "/"
        if sub_dir.length
          content_file_names["#{base_name}.coffee"]= "#{sub_dir}/#{base_name}.coffee"
        else
          content_file_names["#{base_name}.coffee"]="#{base_name}.coffee"
        zip.file filename, file.content.coffee
    project_buf = _.template project_js_template, _.extend default_tmpl_vars, 
      version: doc.version or '0.0.0'
      both_dep: ['coffeescript']
      both_f: _.values content_file_names
    debugger  
    zip.file "#{package_dir}/project.js", project_buf
    zip.saveAs "#{package_dir}.zip"
    debugger


