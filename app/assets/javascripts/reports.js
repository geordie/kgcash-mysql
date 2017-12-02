var heightTitle = 80;

function buildPie( category_amounts, totalAmount, selector, chartName, width, height)
{
	var container = d3.select(selector);

	if( typeof width == 'undefined' ) width = parseInt(container.style("width"));
	if( typeof height == 'undefined' )  height = parseInt(container.style("height"));

	var radius = Math.min(width, height - heightTitle) / 2;

	var color = d3.scale.category20();

	var arc = d3.svg.arc()
		.outerRadius(radius - 10)
		.innerRadius(80);

	var pie = d3.layout.pie()
		.value(function(d) { return d.credit; });

	var canvas = container.append("svg")
		.attr("width", width)
		.attr("height", height)

	var pieChart = canvas.append("g")
		.attr("id", chartName)
		.attr("transform", "translate(" + (width/2) + "," + ( (heightTitle+height)/2)  + ")");

	var g = pieChart.selectAll(".arc")
		.data(pie(category_amounts))
		.enter().append("g")
		.attr("class", function(d,i){ return "arc-" + i })
		.append("a").attr("xlink:href",function(d,i){var cat_id = category_amounts[i].acct_id_dr; return "./transactions?category=" + cat_id});

	g.append("path")
		.attr("d", arc)
		.style("fill", function(d, i) { return color(i); })
		.on("mousemove", function (d, i) {
				catDetail( d, true, width, d3.event, totalAmount );
			})
		.on("mouseout", function(d,i){ catDetail( d, false, width, d3.event, totalAmount )});

	g.filter(function(d){ return d.endAngle - d.startAngle > (Math.PI/5)})
		.append("text")
		.attr("transform", function(d) { return "translate(" + arc.centroid(d)[0] + "," + arc.centroid(d)[1] + ")"; })
		.attr("dy", ".35em")
		.style("text-anchor", "middle")
		.text(function(d,i) { return d.data.name; });

	g.filter(function(d){ return d.endAngle - d.startAngle > (Math.PI/10)})
		.append("text")
		.attr("transform", function(d) { return "translate(" + arc.centroid(d)[0] + "," + (arc.centroid(d)[1] + 15) + ")"; })
		.attr("dy", ".35em")
		.style("text-anchor", "middle")
		.text(function(d) { return Math.round((d.data.credit/totalAmount)*100) + " %"; });

	pieChart.append("svg:text")
		.attr("x", 0)
		.attr("y", -30)
		.attr("text-anchor","middle")
		.attr("dominant-baseline","central")
		.attr("font-size", "32px")
		.attr("stroke", "#999999")
		.attr("fill", "#999999")
		.text("Total");

	pieChart.append("svg:text")
		.attr("x", 0)
		.attr("y", 10)
		.attr("text-anchor","middle")
		.attr("dominant-baseline","central")
		.attr("font-size", "28pt")
		.text("$" + Math.round(totalAmount));
}

function buildMid( amount, selector, title, width, height, formatter )
{
	formatter = formatter || "$";
	var container = d3.select(selector);

	if( typeof width == 'undefined' ) width = parseInt(container.style("width"));
	if( typeof height == 'undefined' )  height = parseInt(container.style("height"));

	var canvas = container.append("svg")
		.attr("width", width)
		.attr("height", height);

	canvas.append("svg:text")
		.attr("x", 0)
		.attr("y", -30)
		.attr("text-anchor","middle")
		.attr("dominant-baseline","central")
		.attr("font-size", "32px")
		.attr("stroke", "#999999")
		.attr("fill", "#999999")
		.attr("transform", "translate(" + (width/2) + "," + ( (heightTitle+height)/2)  + ")")
		.text( title );

	canvas.append("svg:text")
		.attr("x", 0)
		.attr("y", 10)
		.attr("text-anchor","middle")
		.attr("dominant-baseline","central")
		.attr("font-size", "28pt")
		.attr("transform", "translate(" + (width/2) + "," + ( (heightTitle+height)/2)  + ")")
		.text(formatter + Math.round(amount));
}

function getDimensions( container )
{
	var width = parseInt(container.style("width"));
	var height = parseInt(container.style("height"));
}

function catDetail( d, show, width, myEvent, totalAmount )
{
	// save selection of infobox so that we can later change it's position
	var infobox = d3.select(".infobox");

	if( show )
	{
		var text = "<strong>" + d.data.name + "</strong>" + " (" + (Math.round((d.data.credit/totalAmount)*100)) + "%)";
		var boxWidth = text.length * 4;

		text += "<br/>$" + Math.round(d.data.credit);

		// position infobox at mouse
		infobox.style("left", myEvent.pageX + 10 + "px" );
		infobox.style("top", myEvent.pageY + 10 + "px");
		infobox.style("display", "inline");

		infobox.style("width", boxWidth + "px");
		infobox.style("padding", "10px");
		infobox.html( text );
	}
	else
	{
		infobox.style("width", "0px");
		infobox.style("padding", "0px");
		infobox.html("");
	}

}
