#!/bin/sh

################## FUNCTIONS ##################

video()
{
    echo "Creating video..."
    crop_width=1420
    crop_height=($crop_width/1920)*1080 
    crop_x=280
    crop_y=30
    ffmpeg -loglevel error -r 50 -pattern_type glob -i '*.jpg' -filter:v "crop=$crop_width:$crop_height:$crop_x:$crop_y" -s hd480 -vcodec libx264 -crf 20 -y timelapse.mp4
    echo " - Created timelapse.mp4"
}

video_hd()
{
    echo "Creating HD video..."
    crop_width=1420
    crop_height=($crop_width/1920)*1080 
    crop_x=280
    crop_y=30
    ffmpeg -loglevel error -r 50 -pattern_type glob -i '*.jpg' -filter:v "crop=$crop_width:$crop_height:$crop_x:$crop_y" -s hd720 -vcodec libx264 -crf 10 -preset veryslow -y timelapse-hd.mp4
    echo " - Created timelapse-hd.mp4"
}

################## RUN SCRIPT ##################

echo "Change directory to /Werfcam..."
cd /Users/tom/Dropbox/Apps/Werfcam/
echo " - Current directory is: $PWD"

## Create Backup if file not exists
name=$(date '+%Y%m%d')
if [[ ! -f "$name.tar.gz" ]]; then
    echo "Creating backup ($name.tar.gz) of images..."
    export GZIP=-9
    tar -cf - *.jpg | xz -9 -c - > "$name.tar.gz"
    echo " - Backup $name.tar.gz complete."  
fi

## Create video if no arguments are added to the CLI
if [ $# -eq 0 ]; then
    video
fi

## Loop through arguments
while [ "$1" != "" ]; do
    if [ "$1" = "--hd" ]; then
        video_hd
    fi

    if [ "$1" = "--video" ]; then
        video
    fi

    shift
done

echo "Removing old backups..."
ls -tp ./*.tar.gz | grep -v '/$' | tail -n +5 | xargs -I {} rm -- {}

echo "[COMPLETED]"