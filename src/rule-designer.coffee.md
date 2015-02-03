    teacup = require 'teacup'
    teacup.use require 'teacup-camel-to-kebab'
    assert = require 'assert'
    pkg = require '../package.json'

    component = require '../comp/dist/component'
    $ = component 'component-dom'

    module.exports = rule_designer = (the_sip_domain_name,doc) ->
      _on = => @on arguments...

      assert the_sip_domain_name?, 'the_sip_domain_name is required'
      assert @widget?, 'widget is required'
      assert doc?.prefix?, 'doc.prefix is required'
      assert doc?.attrs?.cdr?, 'doc.attrs.cdr is required'

      gateways = null
      carriers = null

      @db.query "#{pkg.name}/gateways",
        startkey:[the_sip_domain_name]
        endkey:[the_sip_domain_name,{}]
      .then ({rows}) ->
        gateways = rows.map (row) -> row.key[1]

      .then =>
        @db.query "#{pkg.name}/carriers",
          startkey:[the_sip_domain_name]
          endkey:[the_sip_domain_name,{}]
          group_level:2
      .then ({rows}) ->
        carriers = rows.map (row) -> row.key[1]
      .then =>

        @widget.append teacup.render =>
          {p,div,text,label,input,datalist,option,ul,li,button} = teacup

          datalist '#gateway', ->
            option value:v for v in gateways
          datalist '#carrier', ->
            option value:c for c in carriers

          div ->
            p "Add a new prefix (routing)"
            label 'Prefix: '
            input type:'tel', placeholder:'336', value:doc.prefix, readonly:true, required:true
            label 'Billing: '
            input value:doc.attrs.cdr, readonly:true, required:true
          div ->
            text 'Targets: '
            ul '.targets', ->
              if doc.gwlist?
                for target in doc.gwlist
                  li '.target-entry', -> target_field target, _on
            button '.targetAdder', 'Add'
          div '.error', ''
      .catch (error) ->
        console.log "rule-designer: #{error}"

      @click '.targetAdder', (e) =>
        e.preventDefault()
        $ e.target
        .parent()
        .find '.targets'
        .append teacup.render ->
          {li} = teacup
          li '.target-entry', -> target_field {}, _on

      @validate_field 'input[name="carrierid"]', (value) ->
        (not value?) or value in carriers

      @validate_field 'input[name="gwid"]', (value) ->
        (not value?) or value in gateways

      update_doc = =>
        doc._id ?= "rule:#{doc.prefix}"
        doc.type ?= 'rule'
        doc.gwlist = @widget
          .find '.target-entry'
          .map (div) ->
            type = $ div
              .find 'input[type="radio"]'
              .reject (x) -> ($ x).value() is false
              .value()
            switch type
              when 'none'
                $ div
                .remove()
                null
              when 'registrant'
                source_registrant: true
              when 'carrier'
                carrierid =
                  $ div
                  .find 'input[name="carrierid"]'
                  .value()
                assert carrierid in carriers, "#{carrierid} is not a valid carrier"
                {carrierid}
              when 'gateway'
                gwid =
                  $ div
                  .find 'input[name="gwid"]'
                  .value()
                assert gwid in gateways, "#{gwid} is not a valid gateway"
                {gwid}
        doc.gwlist = Array.filter doc.gwlist, (x) -> x?
        doc

      @change (e) =>
        e.preventDefault()
        try
          @widget
          .find '.error'
          .text ''
          updated_doc = update_doc()

          # FIXME: UI "saving"
          @widget
          .find '.error'
          .text 'Saving...'

          @ruleset_db.put doc
          .then (new_doc) =>
            doc = new_doc
            # FIXME: UI "saved"
            @widget
            .find '.error'
            .text 'Saved...'
          .catch (error) ->
            throw error
        catch error
          console.log "Error: #{error}"
          @widget
          .find '.error'
          .text "Error: #{error}"

      return

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

    target_field = (info,_on) ->
      _on 'change', '.target input[type="radio"]', (e) ->
        e.preventDefault()
        $ e.target
        .parent '.target'
        .find '.dep'
        .attr 'disabled', true

        $ e.target
        .parent '.choice'
        .find '.dep'
        .attr 'disabled', null

      {ul,li,label,input,text} = teacup
      name = Math.random()
      ul '.target', ->
        li '.choice', ->
          label ->
            input
              type:'radio'
              name:name
              value:'none'
              checked: not (info.source_registrant is true or info.carrierid? or info.gwid?)
              required:true
            text 'Skip / Remove'
        li '.choice', ->
          label ->
            input
              type:'radio'
              name:name
              value:'registrant'
              checked: info.source_registrant is true
              required:true
            text 'Use Registrant'
        li '.choice', ->
          label ->
            input
              type:'radio'
              name:name
              value:'carrier'
              checked: info.carrierid?
              required:true
            text 'Use Carrier '
          input '.dep',
            list:'carrier'
            name: 'carrierid'
            value: info.carrierid ? ''
            disabled: if info.carrierid? then null else true
        li '.choice', ->
          label ->
            input
              type:'radio'
              name:name
              value:'gateway'
              checked: info.gwid?
              required:true
            text 'Use Gateway '
          input '.dep',
            list:'gateway'
            name: 'gwid'
            value: info.gwid ? ''
            disabled: if info.gwid? then null else true
