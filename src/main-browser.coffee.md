Browser main
============

    component = require '../dist/component'
    $ = component 'component-dom'

    pkg = require '../package.json'
    version = "#{pkg.name} version #{pkg.version}"

    page = require 'page'
    teacup = require 'teacup'

    ###
    pouchdb = require 'pouchdb'
    request = require 'superagent'

    base = "#{window.location.procotol}/#{window.location.host}"
    db_path = "#{base}/#{pathname.split('/')[0]}"
    db = new PouchDB db_path
    ###

    page '/', ->
      ($ 'body').html teacup.render ->
        div 'Hello world'

    page()
