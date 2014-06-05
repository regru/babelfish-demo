do (window) ->
    "use strict"

    BabelFish = require 'babelfish'
    strftime  = require 'strftime'

    locale = window.lang

    window.l10n = l10n = BabelFish locale

    l10n.setFallback 'ru_RU', [ 'ru' ]
    l10n.setFallback 'en_US', [ 'en' ]

    window.b_t = t = (args...) ->
        l10n.t.apply l10n, [ locale ].concat(args)

    l10n.datetime = ( dt, format, options ) ->
        return null  unless dt && format

        dt = new Date(dt * 1000)  if 'number' == typeof dt

        m = /^([^\.%]+)\.([^\.%]+)$/.exec format
        format = t("formatting.#{m[1]}.formats.#{m[2]}", options)  if m

        format = format.replace /(%[aAbBpP])/g, (id) ->
            switch id
                when '%a'
                    t("formatting.date.abbr_day_names", { format: format })[dt.getDay()] # wday
                when '%A'
                    t("formatting.date.day_names", { format: format })[dt.getDay()] # wday
                when '%b'
                    t("formatting.date.abbr_month_names", { format: format })[dt.getMonth() + 1] # mon
                when '%B'
                    t("formatting.date.month_names", { format: format })[dt.getMonth() + 1] # mon
                when '%p'
                    t((if dt.getHours() < 12 then "formatting.time.am" else "formatting.time.pm"), { format: format }).toUpperCase()
                when '%P'
                    t((if dt.getHours() < 12 then "formatting.time.am" else "formatting.time.pm"), { format: format }).toLowerCase()

        strftime.strftime format, dt

    # export module
    module.exports =
        l10n: l10n
        t: b_t

    null
