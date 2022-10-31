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


function expandFilterCategory($el, timing= 0) {
    $el.find('.nav-item').show(timing);
    $el.find('.expand-icon').addClass('collapse-icon').removeClass('expand-icon');
    $el.find('.filter-icon').removeClass('icon-greyscale');
    $el.find('.filter-heading').addClass('filter-heading-active');
}

function collapseFilterCategory($el, timing = 0) {
    $el.find('.nav-item').hide(timing);
    $el.find('.collapse-icon').addClass('expand-icon').removeClass('collapse-icon');
    $el.find('.filter-icon').addClass('icon-greyscale');
    $el.find('.filter-heading').removeClass('filter-heading-active');
}