    teacup = require 'teacup'
    teacup.use (require 'teacup-databind')()
    assert = require 'assert'

    module.exports = (ko) ->
      class RuleTarget
        constructor: ({data,gateways,carriers}) ->
          assert data?, 'data is required'
          assert gateways?, 'gateways is required'
          assert carriers?, 'carriers is required'

          # Data
          @source_registrant = ko.observable data.source_registrant
          @gwid = ko.observable data.gwid
          @carrierid = ko.observable data.carrierid

          @gatewayValid = ko.pureComputed => (not @gwid()?) or @gwid() in gateways
          @carrierValid = ko.pureComputed => (not @carrierid()?) or @carrierid() in carriers

          # Initial values
          chosen = if @source_registrant() is true
              'registrant'
            else if @carrierid()?
              'carrier'
            else if @gwid()?
              'gateway'
          @chosen = ko.observable chosen
          @carrier_chosen = ko.pureComputed => @chosen() is 'carrier'
          @gateway_chosen = ko.pureComputed => @chosen() is 'gateway'
          @visible = ko.pureComputed => @chosen() isnt 'none'

          # Behaviors
          return

      html = ->
        name = Math.random()
        {a,ul,li,label,input,text} = teacup
        ul '.target', bind: visible: 'visible', ->
          li '.choice', ->
            label ->
              input
                type:'radio'
                name:name
                value:'registrant'
                required:true
                bind:
                  checked: 'chosen'
              text 'Use Registrant'
          li '.choice', ->
            label ->
              input
                type:'radio'
                name:name
                value:'carrier'
                bind:
                  checked: 'chosen'
                required:true
              text 'Use Carrier '
            input
              list:'carrier'
              name: 'carrierid'
              bind:
                value: 'carrierid'
                enable: 'carrier_chosen'
              required:true
          li '.choice', ->
            label ->
              input
                type:'radio'
                name:name
                value:'gateway'
                bind:
                  checked: 'chosen'
                required:true
              text 'Use Gateway '
            input
              list:'gateway'
              name: 'gwid'
              bind:
                value: 'gwid'
                enable: 'gateway_chosen'
              required: true

      ko.components.register 'rule-target',
        viewModel: RuleTarget
        template: teacup.render html
