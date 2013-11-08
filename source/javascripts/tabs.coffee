render = ->
  $(document).on 'click', '.tab', (e) ->
    tabs = $ '.tabs li'
    el = $ this
    target = el.find('a').attr('href')

    tabs.removeClass 'active'
    el.addClass 'active'

    $('.tab-container').removeClass('active').hide()
    $(target).addClass('active').show()

$(render)
