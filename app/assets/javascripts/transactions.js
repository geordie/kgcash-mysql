$(function (){
	$('#transaction_tx_date').datepicker();

	$('.delete_post').bind('ajax:success', function() {  
    	$(this).closest('tr').fadeOut();
	});

	$('.transaction_update').change( function() {
  		$(this).parents('form:first').submit();
	});

	$('.transaction_filter').change( function() {
		var selectedValue = $(this)[0].value;
		console.log( selectedValue );
  		$(this).parents('form:first').submit();
	});
});

jQuery(function() {
  return $.datepicker.setDefaults({
    dateFormat: "yy-mm-dd"
  });
});