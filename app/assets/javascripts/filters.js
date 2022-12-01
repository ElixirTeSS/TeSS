const N_FILTERS = 5;

document.addEventListener("turbolinks:load", function() {
    $('.filter-heading').click(function(e) {
        var $el = $(this)
        if ($el.hasClass('filter-heading-active')) {
            collapseFilterCategory($el.parent().parent(), 200);
        } else {
            expandFilterCategory($el.parent().parent(), 200);
        }
    });

    $('.sidebar-group .nav-item').each(function() {
        if ($(this).hasClass("active")) {
            expandFilterCategory($(this).parent());
        }
    });

});

function updateShowMore($el) {
    $el.find('.expand-filters > a').off('click');

    let n = $el.find('.nav-item:visible').length;
    let m = $el.find('.nav-item:hidden').length;

    $el.find('.expand-filters > a').text("Show " + (N_FILTERS < m ? N_FILTERS : m) + " more");

    $el.find('.expand-filters > a').click((e) => {
        e.preventDefault();
        expandFilterCategory($el, 200, N_FILTERS + n);
        return false;
    });
}


function expandFilterCategory($el, timing= 0, n) {
    if ($el.find('.nav-item').length > (n || N_FILTERS)) {
        $el.find('.nav-item').slice(0, (n || N_FILTERS)).show(timing);
        $el.find('.expand-filters').show();
    } else {
        $el.find('.nav-item').show(timing);
    }

    updateShowMore($el);

    if ($el.find('.nav-item').length === $el.find('.nav-item:visible').length) {
      $el.find('.expand-filters').hide();
    }

    $el.find('.expand-icon').addClass('collapse-icon').removeClass('expand-icon');
    // $el.find('.filter-icon').removeClass('icon-greyscale');
    $el.find('.filter-heading').addClass('filter-heading-active');
}

function collapseFilterCategory($el, timing = 0) {
    $el.find('.nav-item').hide(timing);
    $el.find('.expand-filters').hide();
    $el.find('.collapse-icon').addClass('expand-icon').removeClass('collapse-icon');
    // $el.find('.filter-icon').addClass('icon-greyscale');
    $el.find('.filter-heading').removeClass('filter-heading-active');
}