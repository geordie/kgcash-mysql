$(function (){
	$('#transaction_tx_date').datepicker();

	$('.delete_post').bind('ajax:success', function() {  
    	$(this).closest('tr').fadeOut();
	});
});