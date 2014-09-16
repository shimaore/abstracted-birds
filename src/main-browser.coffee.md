Browser main
============

    component = require '../dist/component'
    Router = component 'component-router'
    $ = component 'component-dom'

    pkg = require '../package.json'
    version = "#{pkg.name} version #{pkg.version}"
