const fs = require("fs");

const generateTable = (mapStyle) => {
  let table = "<table><tr><th>Icon/Color</th><th>ID</th><th>Type</th></tr>";
  mapStyle.layers.forEach(layer => {
    let paint = layer.paint || {};
    let row = "";
    let color = "";
    let opacity = "";
    let dasharray = "";
    let width = "";

    switch (layer.type) {
      case "symbol":
        if (layer.layout["icon-image"]) {
         row = `<tr><td style="text-align: center;"><img src='sprites/utagawavtt/_svg/${layer.layout["icon-image"]}.svg' alt="icon not found" /></td><td>${layer.id}</td><td>${layer.type}</td></tr>`;
        }
         break;
      case "background":
      case "fill":
        color = paint["background-color"] || paint["fill-color"];
        opacity = paint["fill-opacity"] || "1";
        row = `<tr><td><div style="margin: 0 auto; width: 40px; height: 25px; background-color: ${color}; opacity: ${opacity}"></div></td><td>${layer.id}</td><td>${layer.type}</td></tr>`;
        break;
      case "line":
        color = paint["line-color"];
        opacity = paint["line-opacity"] || "1";
        dasharray = paint["line-dasharray"] || "0";
        width = paint["line-width"];
        row = `<tr><td style="text-align: center;"><svg style="height: 40px; width: 40px;" viewBox="0 0 100 100"><line x1="0" y1="50" x2="100" y2="50" stroke="${color}" stroke-width="${width}" stroke-dasharray="${dasharray}" stroke-opacity="${opacity}" /></svg></td><td>${layer.id}</td><td>${layer.type}</td></tr>`;
        break;
      default:
        break;
    }
    table += row;
  });
  table += "</table>";
  return table;
};

fs.readFile("utagawavtt.json", (err, data) => {
  if (err) {
    console.error(`Error reading file: ${err.message}`);
    return;
  }

  try {
    const mapStyle = JSON.parse(data);
    console.log(mapStyle.layers);
    const table = generateTable(mapStyle);

    fs.writeFile("legend.html", table, err => {
      if (err) {
        console.error(`Error writing file: ${err.message}`);
      } else {
        console.log("HTML table written to legende.html");
      }
    });
  } catch (error) {
    console.error(`Error parsing JSON: ${error.message}`);
  }
});
