{render,doctype,html,head,meta,title,link,body,div,script} = require 'teacup'
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
    body ->
      div '#content'
      script type:'text/javascript', src:"#{pkg.name}.min.js"
