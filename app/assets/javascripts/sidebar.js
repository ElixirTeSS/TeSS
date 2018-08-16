var Sidebar = {
    close: function () {
        $('#sidebar').removeClass('open');
        $('#sidebar-toggle').button('reset');
    },
    open: function () {
        $('#sidebar').addClass('open');
    },
    toggle: function () {
        var toggleButton = $('#sidebar-toggle');
        toggleButton.button('toggle');

        if(toggleButton.hasClass('active')) {
            Sidebar.open();
        } else {
            Sidebar.close();
        }

        return false;
    }
};

document.addEventListener("turbolinks:load", function() {
    $('#sidebar-toggle').click(Sidebar.toggle);
    $('#sidebar-close').click(Sidebar.toggle);
});


function toggleFacets(facet) {
    $("." + facet + "-expanding").toggle(1000);
    $(".toggle-" + facet).toggle();
}
