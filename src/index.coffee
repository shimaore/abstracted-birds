{render,doctype,html,head,meta,title,link,body,div,script,address} = require 'teacup'
pkg = require '../package.json'

module.exports = render ->
  doctype()
  html ->
    head ->
      meta charset:'utf-8'
      meta 'http-equiv':'Content-Type', content:'text/html; charset=UTF-8'
      title "#{pkg.title} -- #{pkg.description} (version #{pkg.version})"
      link rel:'stylesheet', type:'text/css', href:'component.css'
      link rel:'stylesheet', type:'text/css', href:'index.css'
      link rel:'stylesheet', type:'text/css', href:'//maxcdn.bootstrapcdn.com/font-awesome/4.2.0/css/font-awesome.min.css'
    body ->
      div '#content'
      script type:'text/javascript', src:"#{pkg.name}.min.js"
      address ->
        "This is #{pkg.name} #{pkg.version}."
