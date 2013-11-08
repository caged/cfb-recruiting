# Hard-linkable tabs using the new Javascript History API (replaceState).
# For the purposes of this plugin, a browser tab is an <a> element inside
# of a tab container of your choice that shows new content on click without
# a page load. The tab container must be annotated with a `js-hard-tabs` class name.
#
# Some attributes on the <a> being clicked will change the behavior of the
# tag:
#
#   data-container-id - If present, the container matching this id will be
#                       shown when this link is clicked.
#   class="selected"  - When this is set, the container for this link will
#                       be shown on page load.
#
# Examples
#
#     <div class="tabnav js-hard-tabs">
#       <ul class="tabnav-tabs">
#         <li><a href="#" class="tabnav-tab selected">Foo</a></li>
#         <li><a href="#" class="tabnav-tab">Bar</a></li>
#       </ul>
#     </div>
#

# Tab link event click handler.
#
# event - jQuery.Event
#
# Returns false if handled to prevent the default behavior.
handleClick = (event) ->
  container = $ containerForLink this

  # Let middle clicks open new windows / browser tabs
  return true if event.which is 2 or event.metaKey

  # If the container where we expected the tab's content to be
  # is blank, load the tab's target URL the ole fashion way.
  return true unless container.length

  # Find and hide current selected container
  tabContainer = $(this).closest '.js-hard-tabs'
  for tab in tabContainer.find 'a.selected'
    $(tab).removeClass 'selected'
    hideContainer tabContainer, $(containerForLink(tab))

  # Show this container
  showContainer tabContainer, container
  $(this).addClass 'selected'

  window.history.replaceState? null, document.title, $(this).attr('href')
  tabContainer.trigger 'tabChanged', link: $(this)
  false

$(document).on 'click', '.js-hard-tabs a', handleClick
$(document).on 'click', '.js-secondary-hard-link', handleClick

# Find associated container element for a tab link.
#
# link - Anchor Element
#
# Returns container Element.
containerForLink = (link) ->
  pathSegment = findLastPathSegment $(link).attr('href')
  id = if $(link).attr('data-container-id') then $(link).attr('data-container-id') else pathSegment
  document.getElementById id

hideContainer = (container, target) ->
  if container.hasClass 'js-large-data-tabs'
    return $() if target[0] is null

    target.css width: "#{target.width()}px" if target.is(':visible') and !target[0].style.width
    target.css position:'absolute', left: '-9999px'
  else
    target.hide()

showContainer = (container, target) ->
  if container.hasClass 'js-large-data-tabs'
    return $() if target[0] is null
    target.show() if !target.is(':visible')
    target.css position:'', left: ''
  else
    target.show()

# Finds the last path segment, not including querystrings or
# anchors.
#
# pathString - The path to operate on (default: the current path).
#
# Examples
#
#   findLastPathSegment('/products/shorts/25?size=small#images')
#   => '25'
#
#   Given you are on http:#www.google.com/search?sourceid=chrome&ie=UTF-8&q=hardTabs
#   findLastPathSegment()
#   => 'search'
#
# Returns a String of the last path component without any slashes.
findLastPathSegment = (pathString) ->
  pathString ?= document.location.pathname
  pathString = pathString.replace /\?.+|#.+/, ''
  matches = pathString.match /[^\/]+\/?$/
  alert('Invalid tab link!') if matches.length is 0
  matches[0].replace '/', ''
