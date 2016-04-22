@config = (config) ->

  config.coffee =
    couchapp:
      files:
        'dist/main-couchapp.js': 'src/main-couchapp.coffee.md'

  config.couchapp =
    main:
      db: (require './local/install').db ? 'http://localhost:5984/main'
      app: 'dist/main-couchapp.js'

  config.clean.couchapp = ['dist/main-couchapp.js']

@grunt = (grunt) ->

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-couchapp'

  grunt.registerTask 'build:couchapp', 'clean:couchapp coffee:couchapp couchapp'.split ' '
