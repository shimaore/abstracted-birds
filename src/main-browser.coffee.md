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

    base = "#{window.location.protocol}//#{window.location.host}"
    db_path = "#{base}/#{window.location.pathname.split('/')[1]}"
    db = new pouchdb db_path

    page '/', ->
      {ul,div} = teacup
      ($ '#content').html teacup.render ->
        ul '.rulesets'
        ul '.rules'
        div '.input'

Enumerate the available rulesets.

      ($ '.rulesets').empty()

In CCNQ3 this means using a view to enumerate the `sip_domain_name` + `groupid` combinations.

      ###
      db.view "#{pkg.name}/rulesets",
        reduce: true
      .then ({rows}) ->
        {li,a} = teacup
        ($ '.rulesets').append teacup.render ->
          for row in rows
            li ->
              a href:"/ruleset/#{row.key.join ':'}", # FIXME Need some description.
      ###

In CCNQ4 each ruleset will be stored in a separate database. (There will be master records in the provisioning database pointing to each ruleset so that they can be enumerated even if the underlying implementation does not support allDBs.)

      db.allDocs startkey:'ruleset:', endkey:'ruleset;', include_docs: true
      .then ({rows}) ->
        {li,a} = teacup
        ($ '.rulesets').append teacup.render ->
          for row in rows
            li ->
              a href:"/ruleset/#{row.doc.ruleset}", alt:row.doc.description, -> row.doc.title

Once the user chose a ruleset,


    td = require './telephonie_destinations.json'
    destinations = {}
    destinations[doc.id] = "#{doc.lib_destination} (#{doc.type})" for doc in td

    page '/ruleset/:ruleset', ({params:{ruleset}}) ->

enumerate the available routes inside the rule.

      ###
      db.query "#{pkg.name}/rules", startkey:[ruleset,''], endkey:[ruleset,{}], reduce:true, group_level:2
      .then ({rows}) ->
        {li,a} = teacup
        ($ '.rules').append teacup.render ->
          for row in rows
            prefix = row.key.slice(1).join ''
            li "#prefix-#{prefix}", ->
              a href:"/rule/#{ruleset}/#{prefix}", "#{if prefix is '' then 'Default route' else prefix} (#{row.value-1})"
              # TODO: query whether that rule has a record, display associated data
      ###

But that's not really helpful.
What is helpful is to be able to locate a number's destination ("route") and be able to look at the rules in that route (and eventually modify them).

      {form,input,div} = teacup
      ($ 'div.input').html teacup.render ->
        form ->
          input type:'tel'
        div '.results'

As the user inputs data, show the possible routes.

      ($ 'div.input input').on 'change', ->
        tel = ($ @).value()
        return if tel.length < 1
        ids = ("rule:#{ruleset}:#{tel[0...i]}" for i in [0..tel.length])

        db.allDocs include_docs:true, keys:ids
        .then ({rows}) ->
          for row in rows.reverse()
            if row.value? and not row.value.deleted
              [prefix_id,destination_id,tarif_id,tarif,min_call_price,illimite_france,illimite_monde,mobile_fr] = row.doc.attrs.cdr.split '_'
              {p,a} = teacup
              ($ 'div.results').append teacup.render ->
                p ->
                  a href:"/destination/#{destination_id}", destinations[destination_id] ? "Destination #{destination_id}"

    page '/rule/:ruleset/:prefix', ({params:{ruleset,prefix}}) ->


Default (normally is an internal error).

    page '*', ({path}) ->
      if path.match /\/index\.html$/
        page '/'
      else
        # FIXME Automatically report the issue using RabbitMQ or similar!
        alert "Oops, wrong request for #{path}. Please report this bug."

Start the application.

    page()
