do (window) ->
    $ = window.jQuery
    document = window.document

    document.title = t 'main.title'

    $('#surface').html render('main')
