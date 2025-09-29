const width = 960;
const height = 500;

const svg = d3.select("#map").append("svg")
    .attr("width", width)
    .attr("height", height);

// Projection and Path Generator
const projection = d3.geoMercator().scale(120).translate([width / 2, height / 1.5]);
const path = d3.geoPath().projection(projection);

// Set up the color scale with white for no incidents, transitioning into darker vibrant colors
const colorScale = d3.scaleSequential(d3.interpolateYlOrRd)  // Vibrant color scale from light yellow to red
    .domain([0, 100]);  // Adjust the range based on your data, higher value means darker red for more incidents

// Tooltip setup
const tooltip = d3.select("#tooltip");

// Load the GeoJSON data for the countries and the terrorism data CSV
Promise.all([
    d3.json("world-countries.geo.json"),
    d3.csv("region_01 (1).csv")  // Ensure the path is correct
]).then(([worldData, terrorismData]) => {

    // Aggregate terrorism data by country and year
    const aggregatedData = {};

    terrorismData.forEach(d => {
        const year = +d.iyear;
        const country = d.country_txt;

        if (!aggregatedData[country]) {
            aggregatedData[country] = {};
        }
        if (!aggregatedData[country][year]) {
            aggregatedData[country][year] = 0;
        }
        aggregatedData[country][year]++;
    });

    // Draw countries on the map
    svg.selectAll(".country")
        .data(worldData.features)
        .enter().append("path")
        .attr("class", "country")
        .attr("d", path)
        .attr("fill", d => {
            const countryName = d.properties.name;
            const year = +document.getElementById("yearSlider").value;
            const incidents = aggregatedData[countryName] && aggregatedData[countryName][year] ? aggregatedData[countryName][year] : 0;
            // If no incidents, set to white; otherwise, use color scale
            return incidents === 0 ? "#ffffff" : colorScale(incidents);
        })
        .on("mouseover", function(event, d) {
            const countryName = d.properties.name;
            const year = +document.getElementById("yearSlider").value;
            const incidents = aggregatedData[countryName] && aggregatedData[countryName][year] ? aggregatedData[countryName][year] : 0;
            tooltip.style("opacity", 1)
                .html(`${countryName}<br>Incidents: ${incidents}`)
                .style("left", `${event.pageX + 5}px`)
                .style("top", `${event.pageY - 28}px`);
        })
        .on("mouseout", function() {
            tooltip.style("opacity", 0);
        });

    // Year Slider functionality
    const yearSlider = d3.select("#yearSlider");
    yearSlider.on("input", function() {
        const year = this.value;
        d3.select("#yearLabel").text("Year: " + year);

        svg.selectAll(".country").attr("fill", d => {
            const countryName = d.properties.name;
            const incidents = aggregatedData[countryName] && aggregatedData[countryName][year] ? aggregatedData[countryName][year] : 0;
            return incidents === 0 ? "#ffffff" : colorScale(incidents);
        });
    });

    // Create a color legend
    const legend = d3.select("#legend")
        .append("svg")
        .attr("width", 300)
        .attr("height", 50);

    const legendScale = d3.scaleLinear()
        .domain([0, 100])  // Adjust according to your data range
        .range([0, 300]);

    const legendAxis = d3.axisBottom(legendScale)
        .ticks(5)
        .tickFormat(d3.format(".0f"));

    // Define the gradient for the color legend
    const gradient = legend.append("defs")
        .append("linearGradient")
        .attr("id", "gradient")
        .attr("x1", "0%")
        .attr("y1", "0%")
        .attr("x2", "100%")
        .attr("y2", "0%");

    gradient.append("stop")
        .attr("offset", "0%")
        .attr("stop-color", "#ffffff");

    gradient.append("stop")
        .attr("offset", "100%")
        .attr("stop-color", "#d7301f");

    // Add the gradient to the legend
    legend.append("rect")
        .attr("width", 300)
        .attr("height", 10)
        .style("fill", "url(#gradient)");

    // Add the axis for the legend
    legend.append("g")
        .attr("transform", "translate(0,20)")
        .call(legendAxis);
});

