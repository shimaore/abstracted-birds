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

* doc.type `host` for a host (server) description. (In CCNQ4 these are mostly used for DNS, since the actual configurations are kept in git. However it's useful to have some information in the database since the tools will not have access to git.)
* doc.host.sip_domain_name SIP Domain Name
* doc.host.sip_profiles FreeSwitch SIP profiles
* doc.host.sip_profiles[].egress_gwid ID of the Egress gateway

* doc.sip_domain_name ignore
* doc.sip_profiles ignore

    ddoc.views.gateways =
      map: (doc) ->
        if doc.type is 'host' and doc.sip_domain_name? and doc.sip_profiles?
          for name, profile of doc.sip_profiles
            if profile.egress_gwid?
              emit [doc.sip_domain_name,profile.egress_gwid], null

* doc.type `carrier` for a carrier document.
* doc.carrier Carrier data, used for routing outbound calls.
* doc.carrier.sip_domain_name SIP Domain Name
* doc.carrier.carrierid ID of the Carrier

* doc.carrierid ignore

    ddoc.views.carriers =
      map: (doc) ->
        if doc.type is 'carrier' and doc.sip_domain_name?
          emit [doc.sip_domain_name,doc.carrierid], null
      reduce: '_count'

Load attachments, return.

    couchapp.loadAttachments ddoc, path.join __dirname, 'attachments'
    module.exports = ddoc
