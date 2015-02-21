Meteor.startup ->
  Tracker.autorun ->
    css= Session.get('generated_css')
    style= ""
    if css?
      for rule_selector, rule of css
        draft= $(document.createElement('div'))
        draft.css(rule)
        style += "#{rule_selector} { #{ draft.attr('style')} };"
    style_elem=$('style#style_sheet_generator')
    if style_elem.length
      style_elem.text(style)
    else
      style_elem= document.createElement('style')
      style_elem.appendChild document.createTextNode style
      style_elem.setAttribute 'id' , "style_sheet_generator"
      document.head.appendChild style_elem