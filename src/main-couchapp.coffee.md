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
        if doc.type is 'host' and doc.sip_domaine_name? and doc.sip_profiles?
          for name, profile of doc.sip_profiles
            if profile.egress_gwid?
              emit [doc.sip_domain_name,profile.egress_gwid], null

    ddoc.views.rules =
      map: (doc) ->
        if doc.type is 'rule'
          {prefix} = doc
          for l in [0..prefix.length]
            emit ["#{doc.sip_domain_name}:#{doc.groupid}",l,prefix.slice 0,l], null
      reduce: '_count'

Load attachments, return.

    couchapp.loadAttachments ddoc, path.join __dirname, 'attachments'
    module.exports = ddoc
