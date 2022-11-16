# Terrain RGB tileset generation from Digital Elevation Models

*(This documentation is still a work in progress)*

Author: Xavier Fischer / [elevationapi.com](https://elevationapi.com)

Terrain RGB tiles are in MapBox format : see here for specs : https://docs.mapbox.com/data/tilesets/guides/access-elevation-data/

## Digital Elevation Models

For 512px tiles, here is the pixel resolution at a given zoom level, in France (latitude 45)

| Zoom level | Resolution (meters/px) | Best dataset | Dataset native resolution (m/px) | Coverage            | Dataset SRID | Alternate datasets (*) |
|------------|------------------------|--------------|----------------------------------|---------------------|--------------|------------------------|
| 1          |  55,346                | ETOPO1       | 1800                             | Global + Bathymetry | 4326         | N/A |
| 2          |  27,673                | ETOPO1       | 1800                             | Global + Bathymetry | 4326         | N/A | 
| 0          |  13,837                | ETOPO1       | 1800                             | Global + Bathymetry | 4326         | N/A | 
| 3          |  6,918                 | ETOPO1       | 1800                             | Global + Bathymetry | 4326         | N/A | 
| 4          |  3,459                 | ETOPO1       | 1800                             | Global + Bathymetry | 4326         | N/A | 
| 5          |  1,730                 | GEBCO_2019   | 464                              | Global + Bathymetry | 4326         | N/A | 
| 6          |  865                   | GEBCO_2019   | 464                              | Global + Bathymetry | 4326         | N/A | 
| 7          |  432                   | GEBCO_2019   | 464                              | Global + Bathymetry | 4326         | N/A | 
| 8          |  216                   | NASADEM      | 30                               | Global              | 4326         | N/A | 
| 9          |  108                   | NASADEM      | 30                               | Global              | 4326         | N/A | 
| 10         |  54                    | NASADEM      | 30                               | Global              | 4326         | N/A | 
| 11         |  27                    | IGN_5m       | 5                                | France              | 2154         | SwissAlti2m, TINItaly, IGN_spain |
| 12         |  14                    | IGN_5m       | 5                                | France              | 2154         | SwissAlti2m, TINItaly, IGN_spain |
| 13         |  7                     | IGN_5m       | 5                                | France              | 2154         | SwissAlti2m, TINItaly, IGN_spain |
| 16         |  3.4                   | IGN_1m       | 1                                | France              | 2154         | SwissAlti2m, TINItaly, IGN_spain |
| 14         |  1.7                   | IGN_1m       | 1                                | France              | 2154         | SwissAlti50cm, TINItaly, IGN_spain |
| 15         |  0.8                   | IGN_1m       | 1                                | France              | 2154         | SwissAlti50cm, TINItaly, IGN_spain |

(*) Alternate datasets are used when area is not full covered (NO_DATA values encountered or missing DEM files). Those datasets are candidates for tile generation, all of them will be tested to get missing data, and fallback to NASADEM if NO_DATA remaining.
This is used on borders, where a tile is over France, Switzerland and Italy.

Problem : As some areas are uncovered, we need to seamlessly stitch the datasets together.

## Pseudo code

```cs
void GenerateTileSet()
    foreach Z = zoom level from 0 to 15
        let D = getdataset(Z) // see table, may contain alternate datasets for each Zoom, depending on coverage (think national/regional data)
        foreach T = tile in zoom Z
            let I = File(T)
            if not File(T) exists
                let I = generateTile(T, D)
                
                while I has nodata values // uncovered areas
                    let J = GetAlternateTile(T, dataset) //find image on alternate dataset at lower zoom level already generated recursively
                    if J is not found break
                    
                    Let K = crop and resize J to match I bounds, using a smooth resampling algorithm (bicubic spline or better)
                    update I : set no data pixels colors at (x,y) to K(x,y) pixel color
                    /* TODO find a way to avoid sharp boundary. ideas : 
                    * -> look for image manipulation tips and tricks
                    * -> find nearest I(x,y) with data within radius R and set I(x,y)=smooth(I(x,y) , K(x,y))
                    */
                end

                Save I
            endif
        endforeach // zoom level done
    endforeach // all done
return


function generateTile(tile T, dataset D) returns Image
    if T is not covered in D
        return no_data_image(I)

    if dataset SRID = 4326 // ie: "needs no warping". not confident about my knowledge here, others may or may not need warping (ETOPO1 is equirectangular and does not works well)
        H = get height map for (T,D)
        H = reproject(H, 3857)  // web mercator
    else
        let M = WarpMargin (diff between footprint size of tile reprojected to 3857 and T)
        H = get height map for (T + M,D)
        H = warpheightmap(H,3857) // convert to 3857 pixels and for every 3857 destination pixel interpolate elevation from H
        H = crop(H, bounds: T)
    end if
    
    let I = encode terrain RGB image (H) // generates output PNG image, path is /Z/Tx/Ty.png 
    return I


function GetAlternateTile(Tile T, dataset D /* dataset used to generate T */) returns image

```
