$(function (){

	$('.delete_post').bind('ajax:success', function() {
    	$(this).closest('tr').fadeOut();
	});

	$('.expense_update').change( function() {
  		$(this).parents('form:first').submit();	
	});
});
