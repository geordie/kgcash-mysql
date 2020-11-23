$(function (){

	$('.transaction_update').change( function() {
  		$(this).parents('form:first').submit();
	});

	$('.transaction_filter').change( function() {
		var selectedValue = $(this)[0].value;
  		$(this).parents('form:first').submit();
	});
});
