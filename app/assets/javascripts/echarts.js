function getEchartsMultibarOptions( multiBarData ) {
  // Configure the multi-bar chart options
  var multiBarOptions = {
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'shadow'
      },
      formatter: function(params) {
        var tooltipText = params[0].axisValueLabel + '<br/>';
        params.forEach(function(param) {
          tooltipText += param.marker + ' ' + param.seriesName + ': $' + param.value + '<br/>';
        });
        return tooltipText;
      }
    },
    legend: {
      data: multiBarData.map(function (item) {
        return item.name;
      }),
      selected: {
        'Credits': false,
        'Debits': false
      }
        },
        xAxis: {
          type: 'category',
          data: [],
          name: '', // Add a title to the x Axis
          nameLocation: 'middle', // Center the title below the xAxis
          nameGap: 30 // Adjust the gap between the title and the xAxis
        },
        yAxis: {
      type: 'value',
      axisLabel: {
        formatter: function(value) {
          return '$' + value;
        }
      }
    },
    series: multiBarData.map(function (item) {
      return {
        name: item.name,
        type: 'bar',
        data: item.values
      };
    })
  };

  // Set the multi-bar chart options
  return multiBarOptions;
}