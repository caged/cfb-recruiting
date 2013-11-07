render = ->
  $(document).on 'click', '.tab', (e) ->
    tabs = $ '.tabs li'
    el = $ this
    target = el.find('a').attr('href')
    console.log target

    tabs.removeClass 'active'
    el.addClass 'active'


$(render)
