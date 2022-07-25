Despository for [UtagawaVTT.com](https://www.utagawavtt.com) MTB map style

Map tiles (vector and raster) will be served with [Tileserver GL](https://github.com/maptiler/tileserver-gl) 

Schema follows [Openmaptile specifications](https://openmaptiles.org/schema/)

Style is intended to have a great Map for Mountain Biking with OpenStreetMap data, contours and Hillshading.

Style file utagawavtt.json can be modified with [Maputnik Editor](https://maputnik.github.io).


## Automatic deployment

Commit and push utagawavtt.json file to the repository and it will be automaticaly available for visualisation here : https://map.omrs.fr/styles/monde-png/#2/0.00000/0.00000

⚠️ Warning ⚠️

sprite link must be : "sprite": "utagawavtt"

Replace these 2 lines in the utagawavtt.json file before commiting to replace the ones produced by Maputnik :

    "sprite": "https://map.omrs.fr/styles/utagawavtt/sprite",
    "glyphs": "https://map.omrs.fr/fonts/{fontstack}/{range}.pbf",
  
  with 
  
    "sprite": "{style}",
    "glyphs": "{fontstack}/{range}",
  
