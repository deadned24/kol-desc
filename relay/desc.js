var url_form="desc_mon.ash"; 

$(function () {
    $('form#descMenu').on('change', 'input[type=checkbox]', function (e) {
        $.ajax({
            url: url_form,
            type: 'POST',
            data: {
                id: this.id,
                checked: this.checked
            }
        });
    });
    
    // show menu when menu is clicked
    $('#icon').on('click', function (e) {
        e.stopPropagation();               
        $('#menuBox').toggle();
    });

    // Hide menu when clicking outside
    $(document).on('click', function () {
        $('#menuBox').hide();
    });
    
    // Prevent clicks inside the menu from closing it
    $('#menuBox').on('click', function (e) {
        e.stopPropagation();
    });
});

