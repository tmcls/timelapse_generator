#!/bin/sh

# This script creates a timelapse and backup of images in one folder.
# You can run the script with the following commands.
#
#   Create the SD version:
#     > python timelapse.sh
#     > python timelapse.sh --video
#
#   Create the HD version
#     > python timelapse.sh --hd
#
#   Create thr SD and HD version at once.
#     > python timelapse.sh --video --hd


################## SETTINGS ##################

# Video - Set the width of the crop region
crop_width=1420

# Video - The crop height is calculated based ont eh original video aspect ratio
crop_height=($crop_width/1920)*1080 

# Video - Set crop X-position
crop_x=280

# Video - Set crop X-position
crop_y=30

# Backup - Set compression level
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

# Change working directory to the correct folder
echo "Change directory to image folder..."
cd /Users/tom/Dropbox/Apps/Werfcam/
echo " - Current directory is: $PWD"

# Create Backup of the day, if backup file not exists
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