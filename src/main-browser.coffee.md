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
    async = require 'async'

    base = "#{window.location.protocol}//#{window.location.host}"
    db_path = "#{base}/#{window.location.pathname.split('/')[1]}"
    db = new pouchdb db_path

    page '/', ->
      {ul,div,a} = teacup
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

Note: don't put the `input` tag inside a form, this way we won't have to deal with default form submission.

        input type:'tel', placeholder:'336........'
        div '.results'

As the user inputs data, show the possible routes.

      ($ 'div.input input').on 'change', ->
        tel = ($ 'div.input input').value()
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
      alert 'FIXME'

Per-destination updates.

    page '/destination/:destination_id', (params:{destination_id}) ->
      ($ '.rules').empty()
      db.query "#{pkg.name}/rule_by_destination", startkey:[destination_id], endkey:[destination_id,{}], reduce: false, include_docs: true
      .then ({rows}) ->
        {li,input,a,span,datalist,p,label,button,option} = teacup
        the_gwlist = null
        the_sip_domain_name = null
        for row in rows
          [dest,tarif_id,prefix] = row.key
          [dummy,sip_domain_name,groupid,prefix] = row.id.split ':'
          ($ '.rules').append teacup.render ->
            li ->
              input type:'checkbox', value:row.id, checked:true
              a href:"/rule/#{sip_domain_name}:#{groupid}/#{prefix}", " #{prefix}"
              span ", tarif #{tarif_id}, targets: #{row.doc.gwlist}"

Let's hope the gwlist is the same for all rules.

          the_gwlist ?= row.doc.gwlist

If not all rules point to the same destination, let the user know.

          if the_gwlist? and the_gwlist isnt row.doc.gwlist
            the_gwlist = false

Let's hope the sip_domain_name is the same for all rules.

          the_sip_domain_name ?= sip_domain_name

          if the_sip_domain_name? and the_sip_domain_name isnt sip_domain_name
            the_sip_domain_name = false

        if the_sip_domain_name is false
          ($ '.rules').prepend teacup.render ->
            p 'The rules are not matching, cannot proceed.'
          return

        if the_gwlist is false
          ($ '.rules').prepend teacup.render ->
            p 'Warning: the targets are not matching, proceed with caution.'
          the_gwlist = null

        db.query "#{pkg.name}/gateways", startkey:[the_sip_domain_name], endkey:[the_sip_domain_name,{}]
        .then ({rows}) ->
          gateways = (row.key[1] for row in rows)

          db.query "#{pkg.name}/carriers", startkey:[the_sip_domain_name], endkey:[the_sip_domain_name,{}], group_level:2
          .then ({rows}) ->
            carriers = ("##{row.key[1]}" for row in rows)

            ($ '.input').html teacup.render ->
              label for:'target1', 'Target 1'
              input '#target1', list:'gateway_or_carrier', value:the_gwlist?.split(',')[0] ? ''
              label for:'target2', 'Target 2'
              input '#target2', list:'gateway_or_carrier', value:the_gwlist?.split(',')[1] ? ''

              button 'Change!'

              datalist '#gateway_or_carrier', ->
                option value:v for v in gateways
                option value:c for c in carriers

            console.log {gateways,carriers}

When the button is clicked,

            ($ '.input button').on 'click', ->

retrieve the two target values

              target1 = ($ '.input #target1').value()
              target2 = ($ '.input #target2').value()

build the new gwlist

              new_gwlist = (target for target in [target1,target2] when target in gateways or target in carriers)
              unless new_gwlist.length > 0
                alert 'You must provide at least one valid target.'
                return

gather the list of rules' ids,

              ids = []
              ($ '.rules input:checked').each ->
                ids.push ($ @).value()

and update the values

However we can't just submit thousands of records at once, CouchDB and/or the browser with complain.
Batch them in packs of 500.

              submit_batch = (batch,next) ->
                db.allDocs keys:batch, include_docs:true
                .then ({rows}) ->
                  docs = (row.doc for row in rows when row.doc? and not row.value.deleted)
                  for doc in docs
                    doc.gwlist = new_gwlist

                  db.bulkDocs docs
                  .then (res) ->
                    failed = []
                    for row in res
                      if not row.ok
                        failed.push row.id
                    if failed.length > 0
                      next "#{failed.length} failed"
                    else
                      next null

              batch_size = 500
              batches = []
              for s in [0..ids.length] by batch_size
                batches.push ids[s..s+batch_size]

              async.eachSeries batches, submit_batch, (err) ->
                if err
                  alert err
                else
                  page '/'

Default (normally is an internal error).

    page '*', ({path}) ->
      if path.match /\/index\.html$/
        page '/'
      else
        # FIXME Automatically report the issue using RabbitMQ or similar!
        alert "Oops, wrong request for #{path}. Please report this bug."

Start the application.

    page()
