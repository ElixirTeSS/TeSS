var Sidebar = {
    close: function () {
        $('.sidebar-backdrop').remove();
        $('#sidebar').removeClass('open');
        $('#sidebar-toggle').button('reset');
    },
    open: function () {
        $('body').append($('<div class="sidebar-backdrop modal-backdrop fade in"></div>'));
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
    $(document).on('click', '.sidebar-backdrop', Sidebar.toggle);
});
