var heightTitle = 80;

function buildPie( category_amounts, totalAmount, pieLocation, selector, chartName)
{
	var container = d3.select(selector);
	var width = parseInt(container.style("width"));
	var height = parseInt(container.style("height"));

	var radius = Math.min(width, height - heightTitle) / 2;

	var color = d3.scale.category20();

	var arc = d3.svg.arc()
	    .outerRadius(radius - 10)
	    .innerRadius(80);

	var pie = d3.layout.pie()
	    .value(function(d) { return d.amount; });
	

	var canvas = container.append("svg")
	    .attr("width", width)
	    .attr("height", height)

	var pieChart = canvas.append("g")
		.attr("id", chartName)
	    .attr("transform", "translate(" + (width/2) + "," + ( (heightTitle+height)/2)  + ")");

	category_amounts.forEach(function(d) {
	  d.amount = +d.amount;
	});

	var g = pieChart.selectAll(".arc")
	    .data(pie(category_amounts))
	    .enter().append("g")
	    .attr("class", function(d,i){ return "arc-" + i });

	g.append("path")
	    .attr("d", arc)
	    .style("fill", function(d, i) { return color(i); })
	    .on("mousemove", function (d, i) {
            	catDetail( d, true, width, d3.event, totalAmount );
            })
	    .on("mouseout", function(d,i){ catDetail( d, false, width, d3.event, totalAmount )});

	g.filter(function(d){ return d.endAngle - d.startAngle > (Math.PI/10)})
	    .append("text")
	    .attr("transform", function(d) { return "translate(" + arc.centroid(d)[0] + "," + arc.centroid(d)[1] + ")"; })
	    .attr("dy", ".35em")
	    .style("text-anchor", "middle")
	    .text(function(d,i) { return d.data.category; });

	g.filter(function(d){ return d.endAngle - d.startAngle > (Math.PI/10)})
	    .append("text")
	    .attr("transform", function(d) { return "translate(" + arc.centroid(d)[0] + "," + (arc.centroid(d)[1] + 15) + ")"; })
	    .attr("dy", ".35em")
	    .style("text-anchor", "middle")
	    .text(function(d) { return Math.round((d.data.amount/totalAmount)*100) + " %"; });

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

function buildMid( amount, selector )
{
	var body = d3.select(selector);
	var width = parseInt(body.style("width"));
	var height = parseInt(body.style("height"));

	var canvas = body.append("svg")
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
	   .text("Total");

	canvas.append("svg:text")
	   .attr("x", 0)
	   .attr("y", 10)
	   .attr("text-anchor","middle")
	   .attr("dominant-baseline","central")
	   .attr("font-size", "28pt")
	   .attr("transform", "translate(" + (width/2) + "," + ( (heightTitle+height)/2)  + ")")
	   .text("$" + Math.round(amount));
}

function catDetail( d, show, width, myEvent, totalAmount )
{
	var elem = myEvent.toElement
  	var coord = d3.mouse(elem);

    // save selection of infobox so that we can later change it's position
    var infobox = d3.select(".infobox");
	
    if( show )
    {

  	  var offsetLeft = elem.viewportElement.offsetLeft;

      var text = "<strong>" + d.data.category + "</strong>";
      var boxWidth = text.length * 3;
      
      text += "<br/>$" + Math.round(d.data.amount)  + "<br/>(" + (Math.round((d.data.amount/totalAmount)*100)) + "%)" ;
     
      // position infobox at mouse
      infobox.style("left", coord[0] + offsetLeft + 140 + "px" );
	  infobox.style("top", coord[1] + 400 + "px");
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
