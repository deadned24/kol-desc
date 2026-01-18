var url_form="desc_mon.ash";

$(function () {
    $('form#descMenu').on('change', 'input[type=checkbox]', function (e) {
//        e.preventDefault();
        $.ajax({
            url: url_form,
            type: 'POST',
            data: {
                id: this.id,
                checked: this.checked
            }
        });
    });
    // Toggle menu visibility when the icon is clicked
    $('#icon').on('click', function (e) {
        e.stopPropagation();               // keep click from reaching document
        $('#menuBox').toggle();
    });
    // Hide menu when clicking anywhere else on the page
    $(document).on('click', function () {
        $('#menuBox').hide();
    });
    // Prevent clicks inside the menu from bubbling up and closing it
    $('#menuBox').on('click', function (e) {
        e.stopPropagation();
    });
});

