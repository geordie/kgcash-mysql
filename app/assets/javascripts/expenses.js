$(function (){

	$('.expense_note').keydown( function(e) {
		if( e.key == " " && e.currentTarget.localName == 'span'){
			e.preventDefault();
			$(this).click();
		}
		else if (e.keyCode == 9 && e.currentTarget.localName == 'input'){
			var tabIndex = $(this).context.tabIndex;
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

// Parse text out of a provided HTML DOM table cell
function parseTableCell(cell){
	text = cell.textContent;
	select = cell.querySelector('select');
	dropdown = cell.querySelector('div.dropdown');
	if(select){
		if(select.value && select.value.toLowerCase() !== 'null') {
			text = select.options[select.selectedIndex].text;
		}
	} else if (dropdown){
		text = '';
	}
	return text;
}

// Convert a provided HTML DOM table to CSV
function toCsv(table) {

    // Get all rows
    rows = table.querySelectorAll('tr');

	// Get text from each cell and join with commas
    return [].slice
        .call(rows)
        .map(function (row) {
            // Query all cells
            cells = row.querySelectorAll('th,td');
            return [].slice
                .call(cells)
                .map(function (cell) {
					return parseTableCell(cell);
                })
                .join(',');
        })
        .join('\n');
};

// Create a link to download a file,
// click the link to trigger a download,
// then remove the link
download = function (text, fileName) {
    link = document.createElement('a');
    link.setAttribute('href', `data:text/csv;charset=utf-8,${encodeURIComponent(text)}`);
    link.setAttribute('download', fileName);

    link.style.display = 'none';
    document.body.appendChild(link);

    link.click();

    document.body.removeChild(link);
};

// Function to be triggered by UI element that download a CSV of transaction data
function exportCsv(){
	// Get the table by hardcoded ID
	table = document.getElementById('transactions');

	// Export to csv
	csv = toCsv(table);

	// Download it
	download(csv, 'download.csv');
}
