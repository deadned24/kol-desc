var url_form="desc_mon.ash"; 

$(function () {
    $('form#descMenu').on('change', 'input[type=checkbox]', function (e) {
        $.ajax({
            url: url_form,
            type: 'POST',
            data: {
                id: this.id,
                checked: this.checked
            }
        });
    });
    
    // show menu when menu is clicked
    $('#icon').on('click', function (e) {
        e.stopPropagation();               
        $('#menuBox').toggle();
    });

    // Hide menu when clicking outside
    $(document).on('click', function () {
        $('#menuBox').hide();
    });
    
    // Prevent clicks inside the menu from closing it
    $('#menuBox').on('click', function (e) {
        e.stopPropagation();
    });
});

function loadGraph(data) {
    const dataObj = data;

    /* ------------------- Extract series ------------------- */
    const history = dataObj.history;

    const dates   = history.map(d => d.date);               // ISO strings
    const prices  = history.map(d => Number(d.price));      // numeric price
    const volumes = history.map(d => d.volume);            // numeric volume

    /* --------------- Compute padded axis ranges ----------- */
    const paddedRange = arr => {
      const min = Math.min(...arr);
      const max = Math.max(...arr);
      const pad = (max - min) * 0.1;
      return [Math.floor(min - pad), Math.ceil(max + pad)];
    };

    const priceRange  = paddedRange(prices);
    const volumeRange = paddedRange(volumes);

    /* ------------------- Traces -------------------------- */
    const priceTrace = {
      x: dates,
      y: prices,
      name: 'Price',
      type: 'scatter',
      mode: 'lines+markers',
      line: {color: '#0066ff'},
      yaxis: 'y1'               // left axis
    };

    const volumeTrace = {
      x: dates,
      y: volumes,
      name: 'Volume',
      type: 'bar',
      opacity: 0.6,
      marker: {color: '#ff6600'},
      yaxis: 'y2'               // right axis
    };

    /* ------------------- Layout -------------------------- */
    const layout = {
      title: dataObj.name,
      margin: {t: 30},
      xaxis: {title: 'Date'},
      yaxis: {
        title: 'Price',
        side: 'left',
        range: [0, 2*priceRange[1]],
        showgrid: false
      },
      yaxis2: {
        title: 'Volume',
        side: 'right',
        overlaying: 'y',
        range: [0, volumeRange[1]],
        showgrid: false
      },
      legend: {orientation: 'h', x: 0.5, xanchor: 'center', y: -0.2},
      staticPlot: true          // disables animation & interaction
    };

    Plotly.newPlot('description', [priceTrace, volumeTrace], layout);
}
