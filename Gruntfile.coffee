lessMap = [
  expand: true
  cwd: 'assets/less'
  src: [ '**/*.less' ]
  dest: 'assets/stylesheets/'
  ext: '.less.css'
]

jsMap =
  'static/javascripts/modernizr.js': 'bower_components/modernizr/modernizr.js'
  # shims
  'static/javascripts/shims/es5-shim.js': 'bower_components/es5-shim/es5-shim.js'
  # /shims


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
            'assets/js/babelfish-init.coffee.js'
          ]
    less:
      development:
        options:
          dumpLineNumbers: "mediaquery"
        files:
          lessMap
      production:
        options:
          dumpLineNumbers: false
        files:
          lessMap
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

  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-npm-install'
  grunt.loadNpmTasks 'grunt-browserify'

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
        if typeof value is 'string'
          @update marked( value, { renderer: renderer } )

      b.addPhrase locale, dict, translations

      res =  "// #{file} translation\n"
      res += "window.l10n.load("
      res += b.stringify locale
      res += ");\n"
      resPath = "assets/javascripts/l10n/#{folder}#{dict}.#{locale}.js"
      grunt.file.write resPath, res
      grunt.log.writeln "#{resPath} compiled."

  grunt.registerTask 'default', [
    'npm-install'
    'coffee:default'
    'browserify:babelfish'
    'babelfish'
    'less:production'
    'uglify:production'
  ]

