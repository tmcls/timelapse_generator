#!/bin/sh

################## SETTINGS ##################

# Set the width of the crop region
crop_width=1420

# The Crop height is calculated based ont eh original video aspect ratio
crop_height=($crop_width/1920)*1080 

# Set crop X-position
crop_x=280

# Set crop X-position
crop_y=30

# Set Compression level
export GZIP=-9

################## FUNCTIONS ##################

video()
{
    echo "Creating video..."    
    ffmpeg -loglevel error -r 50 -pattern_type glob -i '*.jpg' -filter:v "crop=$crop_width:$crop_height:$crop_x:$crop_y" -s hd480 -vcodec libx264 -crf 20 -y timelapse.mp4
    echo " - Created timelapse.mp4"
}

video_hd()
{
    echo "Creating HD video..."
    ffmpeg -loglevel error -r 50 -pattern_type glob -i '*.jpg' -filter:v "crop=$crop_width:$crop_height:$crop_x:$crop_y" -s hd720 -vcodec libx264 -crf 10 -preset veryslow -y timelapse-hd.mp4
    echo " - Created timelapse-hd.mp4"
}

################## RUN SCRIPT ##################

# Change working directory to the Dropbox Werfcam folder
echo "Change directory to /Werfcam..."
cd /Users/tom/Dropbox/Apps/Werfcam/
echo " - Current directory is: $PWD"

# Create Backup of the day, if backupfile not exists
name=$(date '+%Y%m%d')
if [[ ! -f "$name.tar.gz" ]]; then
    echo "Creating backup ($name.tar.gz) of images..."
    tar -cf - *.jpg | xz -9 -c - > "$name.tar.gz"
    echo " - Backup $name.tar.gz complete."  
fi

# Check for arguments
if [ $# -eq 0 ]; then

    # Create the video if no arguments are given
    video

else

    # Go through all arguments
    while [ "$1" != "" ]; do

        # Check for --hd argument
        if [ "$1" = "--hd" ]; then
            video_hd
        fi

        # Check for --video argument
        if [ "$1" = "--video" ]; then
            video
        fi

        # move to next argument
        shift
    done
fi

# Cleanup backup files - Keep only the last 5 backups.
echo "Removing old backups..."
ls -tp ./*.tar.gz | grep -v '/$' | tail -n +5 | xargs -I {} rm -- {}

# The End
echo "[COMPLETED]"