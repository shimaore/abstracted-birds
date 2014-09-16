@config = (config) ->

  config.coffee =
    couchapp:
      files:
        'src/main-couchapp.js': 'src/main-couchapp.coffee.md'

  config.couchapp =
    main:
      db: (require './.config').db
      app: 'src/main-couchapp.js'

  config.clean.couchapp = ['src/main-couchapp.js']

@grunt = (grunt) ->

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-couchapp'

  grunt.registerTask 'build:couchapp', 'clean:couchapp coffee:couchapp couchapp'.split ' '
