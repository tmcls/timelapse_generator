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
#   Create the SD and HD version at once.
#     > python timelapse.sh --video --hd
#
#   Create a image aligned HD video 
#   (This will take a couple of days to run this process)
#     > python timelapse.sh --aligned

################## FUNCTIONS ##################


video_aligned()
{
    echo "*** Generate a pto file..."  
    /Applications/Hugin/tools_mac/pto_gen *.jpg -o timelapse.pto

    echo "*** Finding control points..."  
    /Applications/Hugin/tools_mac/cpfind --linearmatch -o timelapse.pto timelapse.pto

    echo "*** Cleanup control points..."  
    /Applications/Hugin/tools_mac/cpclean -o timelapse.pto timelapse.pto

    echo "*** Optimizing position and distortion of the image set..."  
    /Applications/Hugin/tools_mac/pto_var --opt="y, p, r, TrX, TrY, TrZ" -o timelapse.pto timelapse.pto

    echo "*** The following process will take hours... and hours... and hours..." 
    echo "*** Grab a coffee and some sleep. ;-)" 
    /Applications/Hugin/tools_mac/autooptimiser -n -o timelapse.pto timelapse.pto
    
    echo "*** Changing project configuration..."  
    /Applications/Hugin/tools_mac/pano_modify -o timelapse.pto --projection=0 --fov=AUTO --center --canvas=AUTO --crop=AUTOHDR --output-type=REMAPORIG timelapse.pto

    echo "*** Remaping and output TIF images..."  
    /Applications/Hugin/tools_mac/nona -m TIFF_m -o remapped timelapse.pto

    echo "*** Creating the timelapse video at 40fps..."  
    ffmpeg -loglevel error -r 40 -pattern_type glob -i '*.tiff' -s hd1080 -vcodec libx264 -crf 10 -preset veryslow -y timelapse-40.mp4

    echo "*** Creating the timelapse video at 30fps..."  
    ffmpeg -loglevel error -r 30 -pattern_type glob -i '*.tiff' -s hd1080 -vcodec libx264 -crf 10 -preset veryslow -y timelapse-30.mp4

    echo "Aligned video's created"
}

video()
{
    echo "*** Creating video..."    
    ffmpeg -loglevel error -r 40 -pattern_type glob -i '*.jpg' -s hd480 -vcodec libx264 -crf 20 -y timelapse.mp4
    
    echo " - Created timelapse.mp4"
}

video_hd()
{
    echo "*** Creating HD video..."
    ffmpeg -loglevel error -r 40 -pattern_type glob -i '*.jpg' -s hd1080 -vcodec libx264 -crf 10 -preset veryslow -y timelapse-hd.mp4
    
    echo " - Created timelapse-hd.mp4"
}

################## RUN SCRIPT ##################

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
        if [ "$1" = "--aligned" ]; then
            video_v3
        fi

        # move to next argument
        shift
    done
fi