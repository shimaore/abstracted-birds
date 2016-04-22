Browser main
============

    component = require '../comp/dist/component'
    $ = component 'component-dom'
    ko = require 'knockout'

    fun = (x) -> "(#{x})"

    pkg = require '../package.json'
    cfg = require '../config.json'
    version = "#{pkg.name} version #{pkg.version}"

    page = require 'page'
    teacup = require 'teacup'
    teacup.use (require 'teacup-databind')()

    PouchDB = require 'pouchdb'
    request = (require 'superagent-as-promised') require 'superagent'
    async = require 'async'
    assert = require 'assert'

    base = "#{window.location.protocol}//#{window.location.host}"

    db_path = config.db_path ? "#{base}/#{window.location.pathname.split('/')[1]}"
    db = new PouchDB db_path

    local = require './local.coffee.md'
    {RuleGwlist,rule_gwlist} = (require 'ccnq-ko-rule-gwlist') ko
    {RuleEntry,rule_entry} = (require 'ccnq-ko-rule-entry') ko
    ruleset_base = cfg.ruleset_base ? base

* cfg.ruleset_base (URL) Location of the ruleset database

    extend_ctx = (ctx) ->
      assert ctx.sip_domain_name?
      ctx.gateways = null
      ctx.carriers = null
      Promise.resolve()
      .then ->
        db.query "#{pkg.name}/gateways",
          startkey:[ctx.sip_domain_name]
          endkey:[ctx.sip_domain_name,{}]
      .then ({rows}) ->
        ctx.gateways = (row.key[1] for row in rows)
      .then ->
        db.query "#{pkg.name}/carriers",
          startkey:[ctx.sip_domain_name]
          endkey:[ctx.sip_domain_name,{}]
          group_level:2
      .then ({rows}) ->
        ctx.carriers = (row.key[1] for row in rows)

    ruleset_db_of = (ruleset) ->
      db.get "ruleset:#{ruleset}"
      .then (doc) ->
        assert doc?, "Missing ruleset record for #{ruleset}"
        assert doc.database?, "Missing database for ruleset #{ruleset}"
        assert ruleset_base?, "Missing ruleset_base."
        ruleset_db = new PouchDB "#{ruleset_base}/#{doc.database}"

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

* cfg.get_destinations (URL path) Location of the web service to retrieve all destinations.

    destinations = {}
    request
    .get cfg.get_destinations
    .then (td) ->
      destinations[doc.id] = "#{doc.lib_destination} (#{doc.type})" for doc in td
    .catch (error) ->
      console.log "Error: #{error}"

    page '/ruleset/:ruleset', ({params:{ruleset}}) ->

      sip_domain_name = (ruleset.split /:/)[0]
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

        ctx = {db,sip_domain_name}

        ruleset_db_of ruleset
        .then (ruleset_db) ->
          ctx.ruleset_db = ruleset_db
        .then ->
          extend_ctx ctx
        .then ->
          ids = ("rule:#{tel[0...i]}" for i in [0..tel.length])
          ctx.ruleset_db.allDocs include_docs:true, keys:ids
        .then ({rows}) ->
          how_many = 0

* doc.rule Document in a `ruleset` database, used to describe a route.
* doc.attrs See doc.rule.attrs
* doc.attrs.cdr See doc.rule.attrs
* doc.rule.attrs Attributes inserted as doc.CDR.variables.ccnq_attrs
* doc.CDR.variables.ccnq_attrs See doc.rule.attrs.cdr for a description.
* doc.rule.attrs.cdr (string) Contains `prefix_id`, `destination_id`, `tarif_id`, `tarif`, `min_call_price`, `illimite_france`, `illimite_monde`, `mobile_fr` joined by underscore.

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

          local.get_billing_data cfg, tel
        .catch (error) ->
          console.log "get_billing_data: #{error}"
          null
        .then (cdr) ->

Add new prefix (billing).

* cfg.billing_add (URL) service to add a new prefix

          if not cdr?
            ($ 'div.results').append teacup.render ->
              {p,text,a} = teacup
              p ->
                text " No CDR info is available: "
                a href:cfg.billing_add, "Add new prefix (billing)"
            return

Add new prefix (routing).

          ($ 'div.results').append teacup.render ->
            {p,text,div,tag} = teacup
            p ->
              text "No results for #{tel}. "
            p ->
              rule_entry 'doc'
              , -> 'Installing...'

          ctx.doc = new RuleEntry prefix:tel, attrs: {cdr}

          ko.applyBindings ctx

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

    insert_rule_by_destination = (db) ->
      _id = "_design/#{pkg.name}"

Inject the design document into the ruleset database so that we can query it.

      db.get _id
      .catch (error) ->
        {_id}
      .then (ddoc) ->
        ddoc.views ?= {}
        ddoc.views.rule_by_destination =
          map: fun (doc) ->
            if doc.type is 'rule' and doc.attrs?.cdr?
              [prefix_id,destination_id,tarif_id,tarif,min_call_price,illimite_france,illimite_monde,mobile_fr] = doc.attrs.cdr.split '_'

              emit [destination_id,tarif_id,doc.prefix], {prefix_id,tarif,min_call_price,illimite_france,illimite_monde,mobile_fr}
          reduce: '_count'
        db.put ddoc
      .catch (error) ->
        alert "Design: #{error}, assuming things are working."

    page '/destination/:ruleset/:destination_id', (params:{ruleset,destination_id}) ->

      [sip_domain_name,groupid] = ruleset.split ':'

      ($ '.rules').empty()
      ctx = {}

      ruleset_db_of ruleset

We need to insert into the ruleset DB this view:

      .then (ruleset_db) ->
        ctx.ruleset_db = ruleset_db
        insert_rule_by_destination ruleset_db

List the rules matching the given destination.

      .then ->
        ctx.ruleset_db.query "#{pkg.name}/rule_by_destination", startkey:[destination_id], endkey:[destination_id,{}], reduce: false, include_docs: true
      .then ({rows}) ->
        the_gwlist = null
        the_sip_domain_name = null
        for row in rows
          [dest,tarif_id,prefix] = row.key
          [dummy,prefix] = row.id.split ':'
          ($ '.rules').append teacup.render ->
            {li,input,a,span} = teacup
            li ->
              input type:'checkbox', value:row.id, checked:true
              a href:"/rule/#{sip_domain_name}:#{groupid}/#{prefix}", " #{prefix}"
              span ", tarif #{tarif_id}, targets: #{JSON.stringify row.doc.gwlist}"

Let's check the `gwlist` is the same for all rules.

          the_gwlist ?= row.doc.gwlist

If not all rules point to the same destination, let the user know.

          if the_gwlist? and the_gwlist isnt row.doc.gwlist
            the_gwlist = false

Let's check the `sip_domain_name` is the same for all rules.

          the_sip_domain_name ?= sip_domain_name

          if the_sip_domain_name? and the_sip_domain_name isnt sip_domain_name
            the_sip_domain_name = false

Check whether our assumptions hold:

        if not the_sip_domain_name?
          ($ '.rules').prepend teacup.render ->
            {p} = teacup
            p 'Invalid rules, cannot proceed.'
          return

        if the_sip_domain_name is false
          ($ '.rules').prepend teacup.render ->
            {p} = teacup
            p 'The rules are not matching, cannot proceed.'
          return

        if not the_gwlist?
          ($ '.rules').prepend teacup.render ->
            {p} = teacup
            p 'Invalid rules, cannot proceed.'
          return

        if the_gwlist is false
          ($ '.rules').prepend teacup.render ->
            {p} = teacup
            p 'Warning: the targets are not matching, proceed with caution.'
          the_gwlist = null

        ctx.the_gwlist = the_gwlist
        ctx.sip_domain_name = the_sip_domain_name

      .then ->
        extend_ctx ctx
      .then ->

        ($ 'div.results').append teacup.render ->
          {p,button} = teacup
          p ->
            rule_gwlist 'gwlist'
            , -> 'Installing...'
            button '#gwlist-save', 'Save Changes'

        ctx.gwlist = new RuleGwlist ctx.the_gwlist
        ko.applyBindings ctx

build the new gwlist

        $('#gwlist-save').on 'click', ->

              new_gwlist = ctx.gwlist.toJS()

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
                ctx.ruleset_db.allDocs keys:batch, include_docs:true
                .then ({rows}) ->
                  docs = (row.doc for row in rows when row.doc? and not row.value.deleted)
                  for doc in docs
                    doc.gwlist = new_gwlist

                  ctx.ruleset_db.bulkDocs docs
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
