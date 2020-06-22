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


video_v3()
{
    # Based on article https://photo.stackexchange.com/questions/84447/how-can-i-align-hundreds-of-images

    echo "*** Generate a pto file..."  
    /Applications/Hugin/tools_mac/pto_gen *.jpg -o timelapse.pto

    #echo "Cropping to still area in Hugin Application..."  
    #echo "---------------------------------------------------------------------------"
    #echo "Open the Hugin project you generated and change the interface to advanced."
    #echo " "
    #echo "In the window that opened go to the masks tab and there chose the crop tab"
    #echo "and select your first image. Now make sure 'all images of selected lens'"
    #echo "is checked and then drag from the edges of the image and crop to the area"
    #echo "with the least or no amount of movement. This will constrict the match"
    #echo "finder to that area and reduce error in the remapping stage. Now you can"
    #echo "save and exit the program."
    #echo "---------------------------------------------------------------------------"
    #open /Applications/Hugin/Hugin.app timelapse.pto
    #read -n 1 -s -r -p "Press any key to continue"

    echo "*** Finding control points..."  
    /Applications/Hugin/tools_mac/cpfind --linearmatch -o timelapse.pto timelapse.pto

    echo "*** Cleanup control points..."  
    /Applications/Hugin/tools_mac/cpclean -o timelapse.pto timelapse.pto

    #echo "Reset crop in Hugin Application..."
    #echo "---------------------------------------------------------------------------"
    #echo "Now that we are done with control points open the new generated project"
    #echo "called timelapse and head back to the masks tab like before, here select the"
    #echo "crop tab again and click the reset button, this will disable the crop from"
    #echo "all the images."
    #echo "---------------------------------------------------------------------------"
    #open /Applications/Hugin/Hugin.app timelapse.pto
    #read -n 1 -s -r -p "Press any key to continue"

    echo "*** Optimizing position and distortion of the image set..."  
    /Applications/Hugin/tools_mac/pto_var --opt="y, p, r, TrX, TrY, TrZ" -o timelapse.pto timelapse.pto

    echo "*** The following process will take hours... and hours... and hours..." 
    echo "*** This process ends when you're control points distance is lower then 0.8" 
    echo "*** Grab a coffee and some sleep. ;-)" 
    /Applications/Hugin/tools_mac/autooptimiser -n -o timelapse.pto timelapse.pto
    
    echo "*** Changing project configuration..."  
    /Applications/Hugin/tools_mac/pano_modify -o timelapse.pto --projection=0 --fov=AUTO --center --canvas=AUTO --crop=AUTOHDR --output-type=REMAPORIG timelapse.pto

    echo "*** Remaping and output TIF images..."  
    /Applications/Hugin/tools_mac/nona -m TIFF_m -o remapped timelapse.pto

    echo "*** Creating the timelapse video..."  
    ffmpeg -loglevel error -r 40 -pattern_type glob -i '*.tiff' -s hd1080 -vcodec libx264 -crf 10 -preset veryslow -y timelapse-v3.mp4
    
    echo " - Created timelapse-v3.mp4"
}

video()
{
    echo "*** Creating video..."    
    ffmpeg -loglevel error -r 40 -pattern_type glob -i '*.jpg' -filter:v "crop=$crop_width:$crop_height:$crop_x:$crop_y" -s hd480 -vcodec libx264 -crf 20 -y timelapse.mp4
    
    echo " - Created timelapse.mp4"
}

video_hd()
{
    echo "*** Creating HD video..."
    ffmpeg -loglevel error -r 40 -pattern_type glob -i '*.jpg' -filter:v "crop=$crop_width:$crop_height:$crop_x:$crop_y" -s hd720 -vcodec libx264 -crf 10 -preset veryslow -y timelapse-hd.mp4
    
    echo " - Created timelapse-hd.mp4"
}

################## RUN SCRIPT ##################

# Change working directory to the correct folder
echo "*** Change directory to correct image folder..."
cd /Users/tom/Dropbox/Apps/Werfcam/
echo " - Current directory is: $PWD"

# Create Backup of the day, if backup file not exists
name=$(date '+%Y%m%d')
if [[ ! -f "$name.tar.gz" ]]; then
    echo "*** Creating backup ($name.tar.gz)..."
    tar -cf - *.jpg | xz -9 -c - > "$name.tar.gz"
    echo " - Backup $name.tar.gz created"  
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

        # Check for --v3 argument
        if [ "$1" = "--v3" ]; then
            video_v3
        fi

        # move to next argument
        shift
    done
fi

# Cleanup backup files - Keep only the last 5 backups.
echo "*** Removing old backup files..."
ls -tp ./*.tar.gz | grep -v '/$' | tail -n +5 | xargs -I {} rm -- {}

# The End
echo "*** COMPLETED"