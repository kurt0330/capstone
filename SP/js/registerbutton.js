$(document).ready(function() {
    
    // Listen for a click on the button using its ID
    $('#btnRegister').on('click', function() {
        
        // 1. Perform the action (e.g., showing a status message)
        $('#statusMessage').text("Processing your application...");
        
        // 2. Toggle a CSS class (e.g., changing the button color)
        $(this).toggleClass('active-btn');
        
        // 3. Log it to the console for your own testing
        console.log("The button was toggled!");
    });

});