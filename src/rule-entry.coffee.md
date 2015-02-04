    teacup = require 'teacup'
    teacup.use (require 'teacup-databind')()

    assert = require 'assert'

    module.exports = (ko) ->

      (require './rule-target.coffee.md') ko

      class RuleEntry
        constructor: ({doc,sip_domain_name,ruleset_db}) ->
          assert ruleset_db?, 'ruleset_db is required'
          assert sip_domain_name?, 'sip_domain_name is required'
          assert doc?.prefix?, 'doc.prefix is required'
          assert doc?.attrs?.cdr?, 'doc.attrs.cdr is required'

          # Data
          doc._id ?= "rule:#{@prefix}"
          doc.type ?= 'rule'
          @prefix = doc.prefix
          @cdr = doc.attrs.cdr
          @sip_domain_name = sip_domain_name
          @gwlist = ko.observableArray doc.gwlist

          @ruleset_db = ruleset_db

          @error = ko.observable ''

          # Behavior
          @remove_gw = (target) =>
            @gwlist.remove target
        add_gw: ->
          @gwlist.push {}
        save: ->
          @error "Saving... (#{doc._rev})"
          @ruleset_db.put doc
          .then ({rev}) =>
            doc._rev = rev
            @error 'Saved...'
          .catch (error) ->
            @error "Not saved: #{error}"

      html = ->
        {p,div,text,label,input,datalist,option,ul,li,button,tag} = teacup

        datalist '#gateway', bind: foreach: '$root.gateways', ->
          option bind: value: '$data'
        datalist '#carrier', bind: foreach: '$root.carriers', ->
          option bind: value: '$data'

        div ->
          p "Add a new prefix (routing)"
          label 'Prefix: '
          input
            type:'tel'
            bind:
              value: 'prefix'
            readonly:true
            required:true
          label 'Billing: '
          input
            bind:
              value: 'cdr'
            readonly:true
            required:true
        div ->
          text 'Targets: '
          div bind: foreach: 'gwlist', ->
            div ->
              tag 'rule-target', params: 'data: $data, gateways: $root.gateways, carriers: $root.carriers'
              button bind: click: '$parent.remove_gw', 'Remove'
          button bind: click: 'add_gw', 'Add'
          button bind: click: 'save', 'Save'
        div '.error', bind: text: 'error', '(log)'

      ko.components.register 'rule-entry',
        viewModel: RuleEntry
        template: teacup.render html

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
