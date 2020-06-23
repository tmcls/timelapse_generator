#!/bin/sh

# This script creates a timelapse and backup of images in one folder.
# You can run the script with the following commands.
#
#   Create the SD version:
#     > python timelapse.sh
#     > python timelapse.sh --sd
#
#   Create the HD version
#     > python timelapse.sh --hd
#
#   Create the SD and HD version at once.
#     > python timelapse.sh --sd --hd
#
#   Create a image aligned HD video 
#   (This will take a couple of days to run this process)
#     > python timelapse.sh --aligned

################## FUNCTIONS ##################

video_sd()
{
    echo "*** Creating SD video..."    
    ffmpeg -loglevel error -r 40 -pattern_type glob -i '*.jpg' -s hd480 -vcodec libx264 -crf 20 -y timelapse.mp4
    
    echo "Created timelapse.mp4"
}

video_hd()
{
    echo "*** Creating HD video..."
    ffmpeg -loglevel error -r 40 -pattern_type glob -i '*.jpg' -s hd1080 -vcodec libx264 -crf 10 -preset veryslow -y timelapse-hd.mp4
    
    echo "Created timelapse-hd.mp4"
}

video_hd_aligned()
{
    echo "*** [01/10] Creating HD aligned video..."

    echo "*** [02/10] Generate a pto file..."  
    /Applications/Hugin/tools_mac/pto_gen *.jpg -o timelapse.pto

    echo "*** [03/10] Finding control points..."  
    /Applications/Hugin/tools_mac/cpfind --linearmatch -o timelapse.pto timelapse.pto

    echo "*** [04/10] Cleanup control points..."  
    /Applications/Hugin/tools_mac/cpclean -o timelapse.pto timelapse.pto

    echo "*** [05/10] Optimizing position and distortion of the image set..."  
    /Applications/Hugin/tools_mac/pto_var --opt="y, p, r, TrX, TrY, TrZ" -o timelapse.pto timelapse.pto

    echo "*** [06/10] Optimising the images to find a match between them..." 
    echo "*** The following process will take hours... and hours... and hours... Grab a coffee and some sleep. ;-)" 
    /Applications/Hugin/tools_mac/autooptimiser -n -o timelapse.pto timelapse.pto
    
    echo "*** [07/10] Changing project configuration..."  
    /Applications/Hugin/tools_mac/pano_modify -o timelapse.pto --projection=0 --fov=AUTO --center --canvas=AUTO --crop=AUTOHDR --output-type=REMAPORIG timelapse.pto

    echo "*** [08/10] Remaping and output TIF images..."  
    /Applications/Hugin/tools_mac/nona -m TIFF_m -o remapped timelapse.pto

    echo "*** [09/10] Creating the timelapse video at 40fps..."  
    ffmpeg -loglevel error -r 40 -pattern_type glob -i '*.tiff' -s hd1080 -vcodec libx264 -crf 10 -preset veryslow -y timelapse-40.mp4

    echo "*** [10/10] Creating the timelapse video at 30fps..."  
    ffmpeg -loglevel error -r 30 -pattern_type glob -i '*.tiff' -s hd1080 -vcodec libx264 -crf 10 -preset veryslow -y timelapse-30.mp4
    echo "Aligned video's created"
}

################## RUN SCRIPT ##################

# Check for arguments
if [ $# -eq 0 ]; then
    # Create the video if no arguments are given
    video
else
    # Go through all arguments
    while [ "$1" != "" ]; do

        # Check for --video argument
        if [ "$1" = "--sd" ]; then
            video_sd
        fi

        # Check for --hd argument
        if [ "$1" = "--hd" ]; then
            video_hd
        fi

        # Check for --v3 argument
        if [ "$1" = "--aligned" ]; then
            video_hd_aligned
        fi

        # move to next argument
        shift
    done
fi