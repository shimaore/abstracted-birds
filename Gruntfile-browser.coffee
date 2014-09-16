@config = (config) ->

  config.browserify.browser =
    options:
      transform: 'coffeeify rfileify rfolderify debowerify decomponentify deglobalify'.split ' '
    files:
      'dist/<%= pkg.name %>.browser.js': 'src/main-browser.coffee.md'

  config.clean.browser = ['dist/<%= pkg.name %>.browser.js']

  config.uglify.browser =
    files:
      'src/attachments/<%= pkg.name %>.min.js': 'dist/<%= pkg.name %>.browser.js'

@grunt = (grunt) ->

  grunt.loadNpmTasks 'grunt-contrib-copy'

  fs = require 'fs'
  grunt.registerTask 'build:html', 'Build HTML for test.', ->
    html = require 'src/index.coffee'
    fs.writeFileSync 'src/attachments/index.html', html

  grunt.registerTask 'build:browser', 'clean:browser shell:component browserify:browser uglify:browser build:html'.split ' '
