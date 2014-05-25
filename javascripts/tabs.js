(function() {
  var containerForLink, findLastPathSegment, handleClick, hideContainer, showContainer;

  handleClick = function(event) {
    var container, tab, tabContainer, _base, _i, _len, _ref;
    container = $(containerForLink(this));
    if (event.which === 2 || event.metaKey) {
      return true;
    }
    if (!container.length) {
      return true;
    }
    tabContainer = $(this).closest('.js-hard-tabs');
    _ref = tabContainer.find('a.selected');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      tab = _ref[_i];
      $(tab).removeClass('selected');
      hideContainer(tabContainer, $(containerForLink(tab)));
    }
    showContainer(tabContainer, container);
    $(this).addClass('selected');
    if (typeof (_base = window.history).replaceState === "function") {
      _base.replaceState(null, document.title, $(this).attr('href'));
    }
    tabContainer.trigger('tabChanged', {
      link: $(this)
    });
    return false;
  };

  $(document).on('click', '.js-hard-tabs a', handleClick);

  $(document).on('click', '.js-secondary-hard-link', handleClick);

  containerForLink = function(link) {
    var id, pathSegment;
    pathSegment = findLastPathSegment($(link).attr('href'));
    id = $(link).attr('data-container-id') ? $(link).attr('data-container-id') : pathSegment;
    return document.getElementById(id);
  };

  hideContainer = function(container, target) {
    if (container.hasClass('js-large-data-tabs')) {
      if (target[0] === null) {
        return $();
      }
      if (target.is(':visible') && !target[0].style.width) {
        target.css({
          width: "" + (target.width()) + "px"
        });
      }
      return target.css({
        position: 'absolute',
        left: '-9999px'
      });
    } else {
      return target.hide();
    }
  };

  showContainer = function(container, target) {
    if (container.hasClass('js-large-data-tabs')) {
      if (target[0] === null) {
        return $();
      }
      if (!target.is(':visible')) {
        target.show();
      }
      return target.css({
        position: '',
        left: ''
      });
    } else {
      return target.show();
    }
  };

  findLastPathSegment = function(pathString) {
    var matches;
    if (pathString == null) {
      pathString = document.location.pathname;
    }
    pathString = pathString.replace(/\?.+|#.+/, '');
    matches = pathString.match(/[^\/]+\/?$/);
    if (matches.length === 0) {
      alert('Invalid tab link!');
    }
    return matches[0].replace('/', '');
  };

}).call(this);
