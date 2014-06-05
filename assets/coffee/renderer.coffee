do (window) ->
    "use strict"
    window.render = (template, locals) ->
        window.JST["assets/jade/#{template}"] locals
