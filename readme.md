Repository for [UtagawaVTT.com](https://www.utagawavtt.com) MTB map style

Map tiles (vector and raster) are aimed to be served with [Tileserver GL](https://github.com/maptiler/tileserver-gl) 

Schema follows [Openmaptile specifications](https://openmaptiles.org/schema/)

Map Style is intended for Mountain Biking with data from :
* [Natural earth](https://www.naturalearthdata.com/downloads/10m-natural-earth-2/10m-natural-earth-ii-with-shaded-relief-and-water/) data at lower zoom level
* OpenStreetMap data (based on Opentopomapspecifications built with Planetiler)
* Contours and Hillshading for the whole planet (with (TBD) more details for France, Europe and USA based on high definition DEMs)

It shows :
* Tracks and path where MTB is impossible
* Peaks, saddles and cliffs
* Biking oriented POIs
* Contours and shaded reliefs to better prepare biking trips

Style file utagawavtt.json can be modified and improved with WYSYWYG editor [Maputnik](https://maputnik.github.io).


## Automatic deployment

Commit and push utagawavtt.json file to the repository and it will be automaticaly available for visualisation here : https://maps.utagawavtt.com/styles/utagawavtt/#2/0/0
  
## Usage
  
Map is free of usage with mandatory attribution with link to : "UtagawaVTT / www.UtagawaVTT.com"
  
<a target="_blank" href="https://donorbox.org/don-utagawavtt"><img src="https://donorbox.org/images/png-donate/button-medium-blue.png" /></a>
