Browser main
============

    component = require '../comp/dist/component'
    $ = component 'component-dom'

    class Ctx
      constructor: (selector,extend) ->
        @widget = $ selector
        if extend?
          this[k] = v for own k,v of extend
      on: ->
        @widget.on arguments...
      change: ->
        @on 'change', arguments...
      click: ->
        @on 'click', arguments...

      validate_field: (selector,validate) ->
        @change selector, (e) ->
          el = $ e.target
          value = el.value()
          valid = validate value
          if valid
            el.removeClass 'error'
          else
            el.addClass 'error'

    pkg = require '../package.json'
    cfg = require '../config.json'
    version = "#{pkg.name} version #{pkg.version}"

    local = require './local.coffee.md'
    rule_designer = require './rule-designer.coffee.md'

    page = require 'page'
    teacup = require 'teacup'

    PouchDB = require 'pouchdb'
    request = require 'superagent-as-promised'
    async = require 'async'
    assert = require 'assert'

    base = "#{window.location.protocol}//#{window.location.host}"
    db_path = "#{base}/#{window.location.pathname.split('/')[1]}"
    db = new PouchDB db_path

    ruleset_db_of = (ruleset) ->
      db.get "ruleset:#{ruleset}", (doc) ->
        assert doc, "Missing ruleset record for #{ruleset}"
        assert doc.database, "Missing database for ruleset #{ruleset}"
        ruleset_db = new PouchDB "#{cfg.ruleset_base}/#{doc.database}"

    page '/', ->
      {ul,div,a,text} = teacup
      ($ '#content').html teacup.render ->
        ul '.rulesets'
        ul '.rules'
        div '.input'
        text version

Enumerate the available rulesets
--------------------------------

      ($ '.rulesets').empty()

In CCNQ4 each ruleset is stored in a separate database. (There will be master records in the provisioning database pointing to each ruleset so that they can be enumerated properly.)

      db.allDocs startkey:'ruleset:', endkey:'ruleset;', include_docs: true
      .then ({rows}) ->
        {li,a} = teacup
        ($ '.rulesets').append teacup.render ->
          for row in rows
            li ->
              a href:"/ruleset/#{row.doc.ruleset}", alt:row.doc.description, -> row.doc.title

Once the user chose a ruleset,

    destinations = {}
    request
    .get cfg.get_destinations
    .then (td) ->
      destinations[doc.id] = "#{doc.lib_destination} (#{doc.type})" for doc in td
    .catch (error) ->
      console.log "Error: #{error}"

    page '/ruleset/:ruleset', ({params:{ruleset}}) ->

      the_sip_domain_name = (ruleset.split /:/)[0]
locate a number's destination ("route") and enumerate the rules in that route (and eventually modify them).

      ($ 'div.input').html teacup.render ->
        {form,input,div} = teacup

Note: don't put the `input` tag inside a form, this way we won't have to deal with default form submission.

        input type:'tel', name:'prefix', placeholder:'336........'
        div '.results'

As the user inputs data, show the possible routes.

      ($ 'div.input input[name="prefix"]').on 'change', (e) ->
        tel = ($ e.target).value()
        return if tel.length < 1

        ctx = null
        ruleset_db_of ruleset
        .then (ruleset_db) ->
          ctx = new Ctx 'div.results', {db,ruleset_db}
        .then ->
          ids = ("rule:#{tel[0...i]}" for i in [0..tel.length])
          ctx.ruleset_db.allDocs include_docs:true, keys:ids
        .then ({rows}) ->
          how_many = 0
          for row in rows.reverse()
            if row.value? and not row.value.deleted
              [prefix_id,destination_id,tarif_id,tarif,min_call_price,illimite_france,illimite_monde,mobile_fr] = row.doc.attrs.cdr.split '_'
              {p,a} = teacup
              ($ 'div.results').append teacup.render ->
                p ->
                  a href:"/destination/#{ruleset}/#{destination_id}", destinations[destination_id] ? "Destination #{destination_id}"
              how_many++
          return unless how_many is 0

No match found.

          local.get_billing_data tel
          .then (cdr) ->
            {p,text,a} = teacup

Add new prefix (billing).

            if not cdr?
              ($ 'div.results').append teacup.render ->
                p ->
                  text " No CDR info is available: "
                  a href:cfg.billing_add, "Add new prefix (billing)"
              return

Add new prefix (routing).

            ($ 'div.results').append teacup.render ->
              p ->
                text "No results for #{tel}. "

            rule_designer.call ctx, the_sip_domain_name, prefix:tel, attrs: {cdr}

Add new prefix
--------------

The rule record must contain:
- _id: "rule:#{prefix}"
- type: "rule"
- prefix: prefix
- attrs: { cdr }
- gwlist: [ { ...}, {...}]
with possible gateways:
{ source_registrant:true }
{ carrierid }
{ gwid }

    page '/rule/:ruleset/:prefix', ({params:{ruleset,prefix}}) ->
      alert 'FIXME'

Per-destination updates
-----------------------

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
            {label,text,input,button,datalist,option} = teacup

            ($ '.input').html teacup.render ->
              label ->
                text 'Target 1'
                input '#target1', list:'gateway_or_carrier', value:the_gwlist?.split(',')[0] ? ''
              label ->
                text 'Target 2'
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
                    doc.gwlist = new_gwlist.join ','

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
