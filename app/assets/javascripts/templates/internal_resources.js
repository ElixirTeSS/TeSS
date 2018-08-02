var InternalResources = {

};

function delete_internal_resource(id) {
    $('#' + id).remove();
}

$(document).ready(function () {
    $(document).on('click', '.delete-internal-resource', function () {
        return false;
    });
});
