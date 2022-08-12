Despository for [UtagawaVTT.com](https://www.utagawavtt.com) MTB map style

Map tiles (vector and raster) will be served with [Tileserver GL](https://github.com/maptiler/tileserver-gl) 

Schema follows [Openmaptile specifications](https://openmaptiles.org/schema/)

Style is intended to have a great Map for Mountain Biking with OpenStreetMap data, contours and Hillshading.

Style file utagawavtt.json can be modified with [Maputnik Editor](https://maputnik.github.io).


## Automatic deployment

Commit and push utagawavtt.json file to the repository and it will be automaticaly available for visualisation here : https://maps.utagawavtt.com/styles/utagawavtt/#2/0/0

⚠️ Warning ⚠️

sprite link must be : "sprite": "utagawavtt"

Replace these 2 lines in the utagawavtt.json file before commiting to replace the ones produced by Maputnik :

    "sprite": "https://map.omrs.fr/styles/utagawavtt/sprite",
    "glyphs": "https://map.omrs.fr/fonts/{fontstack}/{range}.pbf",
  
  with 
  
    "sprite": "{style}",
    "glyphs": "{fontstack}/{range}",
  
  ## Usage
  
  Map is free of usage with mandatory attribution with link to : "UtagawaVTT / www.UtagawaVTT.com"
  
  <a style="background: #e6462a url(https://donorbox.org/images/red_logo.png) no-repeat 37px;color: #fff;text-decoration: none;font-family: Verdana,sans-serif;display: inline-block;font-size: 16px;padding: 15px 38px;padding-left: 75px;-webkit-border-radius: 2px;-moz-border-radius: 2px;border-radius: 2px;box-shadow: 0 1px 0 0 #1f5a89;text-shadow: 0 1px rgba(0, 0, 0, 0.3);" href="https://donorbox.org/don-utagawavtt">Don</a>
