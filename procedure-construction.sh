#!/usr/bin/bash

set -e

# Run inside docker osgeo/gdal, or install gdal-bin and following
# docker run --rm -ti -v `pwd`:/data osgeo/gdal bash
# cd /data

apt update && apt install -y p7zip git pip sqlite3
pip install git+https://github.com/frodrigo/rio-rgbify.git@round_digits




# Download from http://files.opendatarchives.fr/professionnels.ign.fr/bdalti/
curl http://files.opendatarchives.fr/professionnels.ign.fr/bdalti/ | \
    grep _25M_ASC_ | cut -d '"' -f 2 | sed -e "s_^_http://files.opendatarchives.fr/professionnels.ign.fr/bdalti/_" \
    > url
# +5.3 GB, 20 min
wget -i url


# Extract and drop the archive
# 10 min, +8.0 GB, -5.3 GB
rm -fr asc && mkdir -p asc && \
ls *.7z | xargs -n 1 7zr e -oasc -aos && \
rm *.7z


declare -A map
map["LAMB93"]="EPSG:2154"
map["RGM04UTM38S"]="EPSG:32738"
map["RGR92UTM40S"]="EPSG:2975"
map["RGSPM06U21"]="EPSG:7039"
map["UTM22RGFG95"]="EPSG:2972"
map["WGS84UTM20"]="EPSG:32620"


# Convert ASC to GeoTiff
# 6 min, +2.8 GB
for proj in LAMB93 RGM04UTM38S RGR92UTM40S RGSPM06U21 UTM22RGFG95 WGS84UTM20; do
    gdalbuildvrt -a_srs ${map[$proj]} -hidenodata BDALTIV2_2-0_25M_ASC_${proj}.virt asc/*${proj}*.asc
    gdal_translate -co compress=lzw -of GTiff BDALTIV2_2-0_25M_ASC_${proj}.virt BDALTIV2_2-0_25M_ASC_${proj}.tif
    rm BDALTIV2_2-0_25M_ASC_${proj}_FRANCE.virt
done

# -8.0 GB
rm -fr asc

# 2 min, +2.8 GB
for proj in LAMB93 RGM04UTM38S RGR92UTM40S RGSPM06U21 UTM22RGFG95 WGS84UTM20; do
    # Set sea level to 0
    gdal_calc.py --co="COMPRESS=LZW" --type=Float32 \
        -A BDALTIV2_2-0_25M_ASC_${proj}.tif \
        --overwrite --outfile=BDALTIV2_2-0_25M_ASC_${proj}_0.tif \
        --calc="((A+10)*(A+10>0))-10" --NoDataValue=-10
done


#
# RGB
#

# Generate MBTiles
# 26 min, +2.4 GB
for format in png webp; do
    for proj in LAMB93 RGM04UTM38S RGR92UTM40S RGSPM06U21 UTM22RGFG95 WGS84UTM20; do
        for n in 4 5 6 7 8 9 10 11; do
            z=$((12-n+4))
            rio rgbify \
                --format ${format} -j16 -b -10000 -i 0.1 \
                --max-z ${z} --min-z ${z} \
                --round-digits ${n} \
                BDALTIV2_2-0_25M_ASC_${proj}_0.tif \
                BDALTIV2_2-0_25M_ASC_${proj}_${z}_rgb_${format}.mbtiles
        done

        cp BDALTIV2_2-0_25M_ASC_${proj}_12_rgb_${format}.mbtiles BDALTIV2_2-0_25M_${proj}_rgb_${format}.mbtiles
        sqlite3 BDALTIV2_2-0_25M_${proj}_rgb_${format}.mbtiles "
--PRAGMA journal_mode=PERSIST;
--PRAGMA page_size=80000;
--PRAGMA synchronous=OFF;
ATTACH DATABASE 'BDALTIV2_2-0_25M_ASC_${proj}_5_rgb_${format}.mbtiles' AS m5;
ATTACH DATABASE 'BDALTIV2_2-0_25M_ASC_${proj}_6_rgb_${format}.mbtiles' AS m6;
ATTACH DATABASE 'BDALTIV2_2-0_25M_ASC_${proj}_7_rgb_${format}.mbtiles' AS m7;
ATTACH DATABASE 'BDALTIV2_2-0_25M_ASC_${proj}_8_rgb_${format}.mbtiles' AS m8;
ATTACH DATABASE 'BDALTIV2_2-0_25M_ASC_${proj}_9_rgb_${format}.mbtiles' AS m9;
ATTACH DATABASE 'BDALTIV2_2-0_25M_ASC_${proj}_10_rgb_${format}.mbtiles' AS m10;
ATTACH DATABASE 'BDALTIV2_2-0_25M_ASC_${proj}_11_rgb_${format}.mbtiles' AS m11;
REPLACE INTO tiles SELECT * FROM m5.tiles;
REPLACE INTO tiles SELECT * FROM m6.tiles;
REPLACE INTO tiles SELECT * FROM m7.tiles;
REPLACE INTO tiles SELECT * FROM m8.tiles;
REPLACE INTO tiles SELECT * FROM m9.tiles;
REPLACE INTO tiles SELECT * FROM m10.tiles;
REPLACE INTO tiles SELECT * FROM m11.tiles;
"

        for n in 4 5 6 7 8 9 10 11; do
            z=$((12-n+4))
            rm BDALTIV2_2-0_25M_ASC_${proj}_${z}_rgb_${format}.mbtiles
        done
    done
done


# 3s, +2.4 GB
for format in png webp; do
    cp BDALTIV2_2-0_25M_LAMB93_rgb_${format}.mbtiles BDALTIV2_2-0_25M_rgb_${format}.mbtiles
    sqlite3 BDALTIV2_2-0_25M_rgb_${format}.mbtiles "
INSERT INTO metadata
VALUES
    ('minzoom', '4'),
    ('maxzoom', '12'),
    ('center', '55.469971,-21.094750,14'),
    ('bounds', '-180.000000,-21.389748,180.000000,85.051129'),
    ('attribution', 'BD Alti IGN 2021');

UPDATE metadata SET value='Ombrage RGB 25m ${format^^}' WHERE name='name';
UPDATE metadata SET value='Ombrage RGB 25m ${format^^}' WHERE name='description';

CREATE UNIQUE INDEX name on metadata (name);
CREATE UNIQUE INDEX tile_index on tiles (zoom_level, tile_column, tile_row);
"

    sqlite3 BDALTIV2_2-0_25M_rgb_${format}.mbtiles "
--PRAGMA journal_mode=PERSIST;
--PRAGMA page_size=80000;
--PRAGMA synchronous=OFF;
ATTACH DATABASE 'BDALTIV2_2-0_25M_RGM04UTM38S_rgb_${format}.mbtiles' AS RGM04UTM38S;
ATTACH DATABASE 'BDALTIV2_2-0_25M_RGR92UTM40S_rgb_${format}.mbtiles' AS RGR92UTM40S;
ATTACH DATABASE 'BDALTIV2_2-0_25M_RGSPM06U21_rgb_${format}.mbtiles' AS RGSPM06U21;
ATTACH DATABASE 'BDALTIV2_2-0_25M_UTM22RGFG95_rgb_${format}.mbtiles' AS UTM22RGFG95;
ATTACH DATABASE 'BDALTIV2_2-0_25M_WGS84UTM20_rgb_${format}.mbtiles' AS WGS84UTM20;
REPLACE INTO tiles SELECT * FROM RGM04UTM38S.tiles;
REPLACE INTO tiles SELECT * FROM RGR92UTM40S.tiles;
REPLACE INTO tiles SELECT * FROM RGSPM06U21.tiles;
REPLACE INTO tiles SELECT * FROM UTM22RGFG95.tiles;
REPLACE INTO tiles SELECT * FROM WGS84UTM20.tiles;
"
done


#
# Contours
#

# 25 min, +7.7 GB
for proj in LAMB93 RGM04UTM38S RGR92UTM40S RGSPM06U21 UTM22RGFG95 WGS84UTM20; do
    gdal_contour -i 10 -a ele BDALTIV2_2-0_25M_ASC_${proj}_0.tif BDALTIV2_2-0_25M_ASC_${proj}-contours-10m.gpkg
    ogr2ogr -t_srs EPSG:4326 BDALTIV2_2-0_25M_4326-${proj}-contours-10m.gpkg BDALTIV2_2-0_25M_ASC_${proj}-contours-10m.gpkg
    rm BDALTIV2_2-0_25M_ASC_${proj}-contours-10m.gpkg
done


# 42 s, +7.7 GB
cp BDALTIV2_2-0_25M_4326-LAMB93-contours-10m.gpkg BDALTIV2_2-0_25M_4326-contours-10m.gpkg
for proj in RGM04UTM38S RGR92UTM40S RGSPM06U21 UTM22RGFG95 WGS84UTM20; do
    ogr2ogr -f 'gpkg' -append BDALTIV2_2-0_25M_4326-contours-10m.gpkg BDALTIV2_2-0_25M_4326-${proj}-contours-10m.gpkg
done
# -7.7 GB
for proj in LAMB93 RGM04UTM38S RGR92UTM40S RGSPM06U21 UTM22RGFG95 WGS84UTM20; do
    rm BDALTIV2_2-0_25M_4326-${proj}-contours-10m.gpkg
done


# 77 min, +7 GB, -7.7 GB
ogr2ogr -dialect sqlite -sql "
SELECT
  ele,
  CASE
    WHEN ele % 1000 = 0 THEN 1000
    WHEN ele % 500 = 0 THEN 500
    WHEN ele % 200 = 0 THEN 200
    WHEN ele % 100 = 0 THEN 100
    WHEN ele % 50 = 0 THEN 50
    WHEN ele % 20 = 0 THEN 20
    ELSE 10
  END AS div,
  geom
FROM
  contour
" /vsigzip/BDALTIV2_2-0_25M_4326-contours-10m.geojson BDALTIV2_2-0_25M_4326-contours-10m.gpkg
rm BDALTIV2_2-0_25M_4326-contours-10m.gpkg
mv BDALTIV2_2-0_25M_4326-contours-10m.geojson BDALTIV2_2-0_25M_4326-contours-10m.geojson.gz


# Run inside docker morlov/tippecanoe, or install tippecanoe
# docker run --rm -ti -v `pwd`:/data morlov/tippecanoe bash
# cd /data

# 1h10 with 32 CPU, +1.4 GB
tippecanoe -Z4 -z14 -j '{"*": [
"any",
[
  "all",
  ["<=", "$zoom", 6],
  [">=", "div", 1000]
],
[
  "all",
  [">=", "$zoom", 7],
  ["<=", "$zoom", 7],
  [">=", "div", 500]
],
[
  "all",
  [">=", "$zoom", 8],
  ["<=", "$zoom", 9],
  ["!=", "div", 500],
  [">=", "div", 200]
],
[
  "all",
  [">=", "$zoom", 10],
  ["<=", "$zoom", 11],
  [">=", "div", 100]
],
[
  "all",
  ["==", "$zoom", 12],
  [">=", "div", 50]
],
[
  "all",
  ["==", "$zoom", 13],
  ["!=", "div", 50],
  [">=", "div", 20]
],
[
  "all",
  [">=", "$zoom", 14]
]
]}' \
--name="Contours 10m" --layer=contours --attribution="BD Alti IGN 2021" \
--force -o BDALTIV2_2-0_25M_4326-contours-10m.mbtiles BDALTIV2_2-0_25M_4326-contours-10m.geojson.gz
