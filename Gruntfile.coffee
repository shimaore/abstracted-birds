module.exports = (grunt) ->

  pkg = grunt.file.readJSON 'package.json'

  builds = pkg.builds

  config =
    pkg: pkg

    browserify: {}

    clean:
      dist: ['lib/', 'dist/']
      modules: ['node_modules/']
      test: ['test/*.js','test/*.html']

    uglify: {}

    watch:
      browser:
        files: 'src/*.coffee.md'
        tasks: ['build:browser','notify:watch']

    notify:
      watch:
        options:
          title: 'Task completed'
          message: 'Build is complete.'

  for build in builds
    (require "./Gruntfile-#{build}").config config

  grunt.initConfig config
  grunt.loadNpmTasks 'grunt-shell'
  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-notify'

  for build in builds
    (require "./Gruntfile-#{build}").grunt grunt

  grunt.registerTask 'default', ("build:#{build}" for build in builds)
