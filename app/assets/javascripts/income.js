$(function (){

	$('.delete_post').bind('ajax:success', function() {
    	$(this).closest('tr').fadeOut();
	});

	$('.income_update').change( function() {
  		$(this).parents('form:first').submit();
	});
});
