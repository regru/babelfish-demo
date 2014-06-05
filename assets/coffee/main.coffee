do (window) ->
    $ = window.jQuery

    window.title = t 'main.title'

    $('#surface').html render('main')
