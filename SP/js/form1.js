$(document).ready(function() {
    console.log("Form script loaded!");

    // 1. ADDRESS SYNC LOGIC
    // Using 'same_as_permanent' to match your HTML checkbox ID
    $('#same_as_permanent').on('change', function() {
        if ($(this).is(':checked')) {
            // Using underscores to match your HTML input IDs
            $('#perm_street').val($('#pres_street').val());
            $('#perm_brgy').val($('#pres_brgy').val());
            $('#perm_city').val($('#pres_city').val());
            $('#perm_prov').val($('#pres_prov').val());
            
            // Lock fields
            $('#perm_street, #perm_brgy, #perm_city, #perm_prov').prop('readonly', true);
        } else {
            // Unlock and clear
            $('#perm_street, #perm_brgy, #perm_city, #perm_prov').prop('readonly', false).val('');
        }
    });

    // 2. REAL-TIME UPDATE
    // Updates permanent address as you type if the checkbox is checked
    $('#pres_street, #pres_brgy, #pres_city, #pres_prov').on('input', function() {
        if ($('#same_as_permanent').is(':checked')) {
            let targetId = $(this).attr('id').replace('pres', 'perm');
            $('#' + targetId).val($(this).val());
        }
    });
});
