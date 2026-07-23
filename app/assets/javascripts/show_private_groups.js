// executed for space form
function show_private_groups() {
    let checkbox = document.getElementById("space_is_private")
    let container = document.getElementById("groups_container")

    const toggleGroups = () => {
        if (checkbox && checkbox.checked) {
            container.style.display = "block"
        } else {
            container.style.display = "none"
        }
    }

    if (checkbox) {
        checkbox.addEventListener("change", toggleGroups)
    }

    toggleGroups()
}

window.addEventListener('turbolinks:load', function() {
    show_private_groups();
});
