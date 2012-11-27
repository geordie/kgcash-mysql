$(function (){
	$('#transaction_tx_date').datepicker();

	$('.delete_post').bind('ajax:success', function() {  
    	$(this).closest('tr').fadeOut();
	});

	$('.transaction_update').change( function() {
  		$(this).parents('form:first').submit();
	});
});