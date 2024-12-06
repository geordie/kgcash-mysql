function updateTransactionPill(pill) {
	// Get pill ID
	var pill_id = $(pill).attr('id');

	// Split pill ID into parts
	var parts = pill_id.split('-');
	var field = parts[0];
	var transaction_id = parts[1];
	var category_id = parts[2];

	// Get the associated dropdown box
	var selectBox = document.getElementById(field + '-' + transaction_id);

	// Set the dropdown box value to the category ID
	selectBox.value = category_id;

	// Update the form
	$(selectBox).parents('form:first').submit();

	removePill(pill);
}

function removePill(pill) {
	$(pill).remove();
}

$(function (){

	$('.transaction_update').change( function() {
  		$(this).parents('form:first').submit();
	});

	$('.transaction_pill').click(function() {
		updateTransactionPill(this);
	});

	$('.transaction_pill').keyup(function(e) {
		console.log(e.which);
		// Enter key pressed
		if (e.which == 13) {
			updateTransactionPill(this);
		}
	});
});
