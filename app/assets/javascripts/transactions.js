$(function (){

	$('.transaction_update').change( function() {
  		$(this).parents('form:first').submit();
	});

});
