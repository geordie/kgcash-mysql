$(function (){

	$('.delete_post').bind('ajax:success', function() {
    	$(this).closest('tr').fadeOut();
	});

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
});
