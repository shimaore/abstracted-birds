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
          emit [doc.sip_domain_name,doc.groupid]
      reduce: '_count'

    ddoc.views.gateways =
      map: (doc) ->
        if doc.type is 'host' and doc.sip_profiles?
          for name, profile of doc.sip_profiles
            if profile.egress_gwid?
              emit [doc.sip_domain_name,profile.egress_gwid]

Load attachments, return.

    couchapp.loadAttachments ddoc, path.join __dirname, 'attachments'
    module.exports = ddoc
