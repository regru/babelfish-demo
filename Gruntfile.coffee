jadeMap = [
  expand: true
  cwd: 'assets/jade'
  src: [ '**/*.jade' ]
  dest: 'assets/javascripts/templates'
  ext: '.jade.js'
]

jsMap =
  'static/javascripts/modernizr.js': 'bower_components/modernizr/modernizr.js'
  # shims
  'static/javascripts/shims/es5-shim.js': 'bower_components/es5-shim/es5-shim.js'
  # /shims
  'static/javascripts/main.js': [
    'bower_components/jquery/jquery.js'
    'node_modules/grunt-contrib-jade/node_modules/jade/runtime.js'
    'assets/javascripts/renderer.coffee.js'
    'assets/javascripts/babelfish.js'
    'assets/javascripts/l10n/formatting.en-US.js'
    'assets/javascripts/l10n/formatting.ru-RU.js'
    'assets/javascripts/l10n/main.en-US.js'
    'assets/javascripts/l10n/main.ru-RU.js'
    'assets/javascripts/templates/main.jade.js'
    'assets/javascripts/main.coffee.js'
  ]

path = require 'path'

module.exports = (grunt) ->
  # Project configuration
  grunt.initConfig
    browserify:
      babelfish:
        files:
          'assets/javascripts/babelfish.js': [
            'node_modules/babelfish/lib/babelfish/parser.js'
            'node_modules/babelfish/lib/babelfish/pluralizer.js'
            'node_modules/babelfish/lib/babelfish.js'
            'node_modules/strftime/strftime.js'
            'assets/javascripts/babelfish-init.coffee.js'
          ]
    coffee:
      default:
        files: [
          expand: true
          cwd: 'assets/coffee'
          src: [ '**/*.coffee' ]
          dest: 'assets/javascripts/'
          ext: '.coffee.js'
        ]
    uglify:
      development:
        options:
          sourceMap: (fileName) ->
            fileName.replace /\.js$/, '.map'
          sourceMapRoot: '/assets/'
          sourceMappingURL: (path) ->
            path.replace( /^.*[\/]/, '' ).replace( /\.js$/, '.map' )
          sourceMapPrefix: 1
          beautify: true
          mangle: false
          compress: false
        files:
          jsMap
      production:
        options:
          beautify:
            max_line_len: 150
          mangle:
            except: [
              "window"
              "jQuery"
            ]
        files:
          jsMap
    jade:
      options:
        self: true
        globals: [ 'JST', 't' ]
        basedir: path.resolve '.'
      development:
        options:
          client: true
          compileDebug: true
        files:
          jadeMap
      production:
        options:
          client: true
          compileDebug: false
        files:
          jadeMap
      index:
        files:
          'static/index.html': 'assets/jade/index.jade'
    copy:
      bootstrap:
        files:
          'static/stylesheets/bootstrap.css': 'bower_components/bootstrap/dist/css/bootstrap.min.css'
    'gh-pages':
      build:
        options:
          base: 'static'
        src: ['**']

  require('jit-grunt')(grunt)

  grunt.registerTask 'babelfish', 'Compile config/locales/*.<locale>.yaml to Babelfish assets', ->
    fs = require 'fs'
    Babelfish = require 'babelfish'
    glob = require 'glob'
    marked = require 'marked'
    traverse = require 'traverse'
    files = glob.sync '**/*.yaml', { cwd: 'config/locales' }
    reFile = /(^|.+\/)(.+)\.([^\.]+)\.yaml$/

    # do not wrap each line with <p>
    renderer = new marked.Renderer()
    renderer.paragraph = (text) ->
      text

    for file in files
      m = reFile.exec(file)
      continue  unless m
      [folder, dict, locale] = [m[1], m[2], m[3]]
      b = Babelfish locale
      translations = grunt.file.readYAML "config/locales/#{folder}#{file}"

      # md
      traverse(translations).forEach (value) ->
        return  unless @key and /_md$/.test(@key)
        return  unless typeof value is 'string'
        @update marked( value, { renderer: renderer } )

      b.addPhrase locale, dict, translations

      res =  "// #{file} translation\n"
      res += "window.l10n.load("
      res += b.stringify locale
      res += ");\n"
      resPath = "assets/javascripts/l10n/#{folder}#{dict}.#{locale}.js"
      grunt.file.write resPath, res
      grunt.log.writeln "#{resPath} compiled."


  runner = (task, app, params = []) ->
    spawn = require('child_process').spawn
    done = task.async()
    the_process = spawn(app, params)
    the_process.stdout.on('data', grunt.log.write)
    the_process.stderr.on('data', grunt.log.error)
    the_process.on('close', done)

  grunt.registerTask 'index:open', 'Opens compiled index page', ->
    runner(@, 'open', ['static/index.html'])


  grunt.registerTask 'build', [
    'npm-install'
    'copy'
    'coffee:default'
    'jade:production'
    'browserify:babelfish'
    'babelfish'
    'uglify:production'
    'jade:index'
  ]

  grunt.registerTask 'default', [
    'build'
    'index:open'
  ]

  grunt.registerTask 'publish', [
    'build'
    'gh-pages'
  ]
