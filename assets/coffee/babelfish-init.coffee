do (window) ->
    "use strict"

    BabelFish = require 'babelfish'
    strftime  = require 'strftime'

    locale = 'en-US'

    window.l10n = l10n = BabelFish 'en'

    l10n.setFallback 'ru-RU', [ 'ru' ]
    l10n.setFallback 'en-US', [ 'en' ]

    window.t = t = (key, params, _locale) ->
        _locale = locale  unless _locale?
        l10n.t.apply l10n, [ _locale, key, params ]

    l10n.datetime = ( dt, format, options, _locale ) ->
        return null  unless dt && format

        dt = new Date(dt * 1000)  if 'number' == typeof dt

        m = /^([^\.%]+)\.([^\.%]+)$/.exec format
        format = t("formatting.#{m[1]}.formats.#{m[2]}", options, _locale)  if m

        format = format.replace /(%[aAbBpP])/g, (id) ->
            switch id
                when '%a'
                    t("formatting.date.abbr_day_names", { format: format }, _locale)[dt.getDay()] # wday
                when '%A'
                    t("formatting.date.day_names", { format: format }, _locale)[dt.getDay()] # wday
                when '%b'
                    t("formatting.date.abbr_month_names", { format: format }, _locale)[dt.getMonth() + 1] # mon
                when '%B'
                    t("formatting.date.month_names", { format: format }, _locale)[dt.getMonth() + 1] # mon
                when '%p'
                    t((if dt.getHours() < 12 then "formatting.time.am" else "formatting.time.pm"), { format: format }, _locale).toUpperCase()
                when '%P'
                    t((if dt.getHours() < 12 then "formatting.time.am" else "formatting.time.pm"), { format: format }, _locale).toLowerCase()

        strftime.strftime format, dt

    # export module
    module.exports =
        l10n: l10n
        t: t

    null
