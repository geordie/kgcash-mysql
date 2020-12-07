$(function (){

	$('.expense_note').keydown( function(e) {
		if( e.key == " " && e.originalEvent.path[0].localName == 'span'){
			e.preventDefault();
			$(this).click();
		}
		else if (e.keyCode == 9 && e.originalEvent.path[0].localName == 'input'){
			var tabIndex = $(this).context.tabIndex
			$('[tabindex=' + tabIndex + ']').focus();
		}
	});

	// Listens for change event on transaction splitting operations and
	// gives user feedback about whether the new amounts sum up to the
	// previous total
	$('.split_item_amount').change(function(e) {
		var sumTotal = 0.0;

		// Iterate over all split items to accumulate total
		$('.split_item_amount').each(
			function(i,v){
				sumTotal += parseFloat(v.value.substring(1));
			});

		// Print new total
		$('#totalSplitAmount')[0].innerText = "$" + sumTotal.toFixed(2) ;
	});
});
