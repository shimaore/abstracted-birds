Main file for a CouchApp.
This is ran through browserify, feel free to require()!

    couchapp = require 'couchapp'
    path = require 'path'
    pkg = require '../package.json'

    ddoc =
      _id: "_design/#{pkg.name}"
      version: pkg.version
      rewrite: {}
      views: {}
      shows: {}
      lists: {}
      validate_doc_update: (newDoc,oldDoc,userCtx) ->

    ddoc.views.rulesets =
      map: (doc) ->
        if doc.type is 'rule'
          emit [doc.sip_domain_name,doc.groupid], null
      reduce: '_count'

    ddoc.views.gateways =
      map: (doc) ->
        if doc.type is 'host' and doc.sip_domain_name? and doc.sip_profiles?
          for name, profile of doc.sip_profiles
            if profile.egress_gwid?
              emit [doc.sip_domain_name,profile.egress_gwid], null

    ddoc.views.rules =
      map: (doc) ->
        if doc.type is 'rule'
          {prefix} = doc
          emit ["#{doc.sip_domain_name}:#{doc.groupid}",prefix.split('')...], null
      reduce: '_count'

    ddoc.views.rule_by_destination =
      map: (doc) ->
        if doc.type is 'rule' and doc.attrs?.cdr?
          [prefix_id,destination_id,tarif_id,tarif,min_call_price,illimite_france,illimite_monde,mobile_fr] = doc.attrs.cdr.split '_'

          emit [destination_id,tarif_id,doc.prefix], {prefix_id,tarif,min_call_price,illimite_france,illimite_mond,mobile_fr}

Load attachments, return.

    couchapp.loadAttachments ddoc, path.join __dirname, 'attachments'
    module.exports = ddoc
