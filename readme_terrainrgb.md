# Terrain RGB tileset generation from Digital Elevation Models

*(This documentation is still a work in progress)*

Author: Xavier Fischer / [elevationapi.com](https://elevationapi.com)

Terrain RGB tiles are in MapBox format : see here for specs : https://docs.mapbox.com/data/tilesets/guides/access-elevation-data/

## Digital Elevation Models

For 512px tiles, here is the pixel resolution at a given zoom level, in France (latitude 45)

| Zoom level | Resolution (meters/px) | Best dataset | Dataset native resolution (m/px) | Coverage            | Dataset SRID |
|------------|------------------------|--------------|----------------------------------|---------------------|--------------|
| 1          |  55,346                | ETOPO1       | 1800                             | Global + Bathymetry | 4326 |
| 2          |  27,673                | ETOPO1       | 1800                             | Global + Bathymetry | 4326 |
| 0          |  13,837                | ETOPO1       | 1800                             | Global + Bathymetry | 4326 |
| 3          |  6,918                 | ETOPO1       | 1800                             | Global + Bathymetry | 4326 |
| 4          |  3,459                 | ETOPO1       | 1800                             | Global + Bathymetry | 4326 |
| 5          |  1,730                 | ETOPO1       | 1800                             | Global + Bathymetry | 4326 |
| 6          |  865                   | GEBCO_2019   | 464                              | Global + Bathymetry | 4326 |
| 7          |  432                   | GEBCO_2019   | 464                              | Global + Bathymetry | 4326 |
| 8          |  216                   | NASADEM      | 30                               | Global              | 4326 |
| 9          |  108                   | NASADEM      | 30                               | Global              | 4326 |
| 10         |  54                    | NASADEM      | 30                               | Global              | 4326 |
| 11         |  27                    | IGN_5m       | 5                                | France              | 2154 + others for DOM/TOM |
| 12         |  14                    | IGN_5m       | 5                                | France              | 2154 + others for DOM/TOM |
| 13         |  7                     | IGN_5m       | 5                                | France              | 2154 + others for DOM/TOM |
| 16         |  3.4                   | IGN_1m       | 1                                | France              | 2154 + others for DOM/TOM |
| 14         |  1.7                   | IGN_1m       | 1                                | France              | 2154 + others for DOM/TOM |
| 15         |  0.8                   | IGN_1m       | 1                                | France              | 2154 + others for DOM/TOM |

Problem : As some areas are uncovered, we need to seamlessly stitch the datasets together.

## Pseudo code

```csharp
foreach Z = zoom level from 0 to 15
    let D = getdataset(Z) // see table
    foreach T = tile in zoom Z
        if not File(T) exists
            if dataset SRID = 4326
                H = get height map for (T,D)
                H = reproject(H, 3857)  // web mercator
            else
                let M = WarpMargin (diff between footprint size of tile reprojected to 3857 and T)
                H = get height map for (T + M,D)
                H = warpheightmap(H,3857) // convert to 3857 pixels and for every 3857 destination pixel interpolate elevation from H
                H = crop(H, bounds: T)
            end if

            let I = encode terrain RGB image (H) // generates output PNG image, path is /Z/Tx/Ty.png 
            while I has nodata values // uncovered areas
                let J = find image at lower zoom level already generated recursively
                if J is not found break
                
                Let K = crop and resize J to match I bounds, using a smooth resampling algorithm (bicubic spline or better)
                update I : set no data pixels colors at (x,y) to K(x,y) pixel color
                /* TODO find a way to avoid sharp boundary. ideas : 
                * -> look for image manipulation tips and tricks
                * -> find nearest I(x,y) with data within radius R and set I(x,y)=smooth(I(x,y) , K(x,y))
                */

            // end while

            Save I

```
