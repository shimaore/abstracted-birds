Browser main
============

    component = require '../dist/component'
    $ = component 'component-dom'

    pkg = require '../package.json'
    version = "#{pkg.name} version #{pkg.version}"

    page = require 'page'
    teacup = require 'teacup'

    pouchdb = require 'pouchdb'
    request = require 'superagent'

    base = "#{window.location.protocol}/#{window.location.host}"
    db_path = "#{base}/#{pathname.split('/')[0]}"
    db = new PouchDB db_path

    page '/', ->
      ($ 'body').html teacup.render ->
        ul '.rulesets'

Enumerate the available rulesets.

      ($ '.rulesets').empty()

In CCNQ3 this means using a view to enumerate the `sip_domain_name` + `groupid` combinations.

      ###
      db.view "#{pkg.name}/rulesets",
        reduce: true
      .then ({rows}) ->
        {ul,li} = teacup
        ($ '.rulesets').append teacup.render ->
          for row in rows
            li ->
              a href:"./ruleset/#{row.key.join ':'}", # FIXME Need some description.
      ###

In CCNQ4 each ruleset will be stored in a separate database. (There will be master records in the provisioning database pointing to each ruleset so that they can be enumerated even if the underlying implementation does not support allDBs.)

      db.allDocs startkey:'ruleset:', endkey:'ruleset;', include_docs: true
      .then ({rows}) ->
        {ul,li} = teacup
        ($ '.rulesets').append teacup.render ->
          for row in rows
            li ->
              a href:'./ruleset/#{row.doc.ruleset}', alt:row.doc.description, -> row.doc.title

Once the user chose a ruleset, enumerate the available routes inside the rule.

      page '/ruleset/:ruleset', ->

    page()
