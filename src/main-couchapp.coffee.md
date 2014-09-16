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

Load attachments, return.

    couchapp.loadAttachments ddoc, path.join __dirname, 'attachments'
    module.exports = ddoc
