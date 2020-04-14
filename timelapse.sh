#!/bin/sh

################## FUNCTIONS ##################

alignment()
{
    echo "Create /tmp Folder"
    mkdir /tmp/timelapse

    echo " - Copy all images to /tmp folder." 
    cp -rf *.jpg /tmp/timelapse

    echo "Change directory to /tmp folder..."
    cd /tmp/timelapse
    echo " - Current directory is: $PWD"

    echo "Align Images..."
    /Applications/Hugin/tools_mac/align_image_stack -a aligned -m -C -v *.jpg
    echo " - Alignment completed."
}

video_hd()
{
    echo "Creating MP4 HD version..."
    crop_width=1280
    crop_height=($crop_width/1920)*1080 
    crop_x=380
    crop_y=50
    ffmpeg -loglevel error -r 40 -pattern_type glob -i '*.jpg' -filter:v "crop=$crop_width:$crop_height:$crop_x:$crop_y" -s hd720 -vcodec libx264 -crf 10 -preset veryslow -y timelapse-hd.mp4
    echo " - Created timelapse-hd.mp4"
}

video()
{
    echo "Creating MP4 small version..."
    crop_width=1280
    crop_height=($crop_width/1920)*1080 
    crop_x=380
    crop_y=50
    ffmpeg -loglevel error -r 40 -pattern_type glob -i '*.jpg' -filter:v "crop=$crop_width:$crop_height:$crop_x:$crop_y" -s hd480 -vcodec libx264 -crf 23 -y timelapse.mp4
    echo " - Created timelapse.mp4"
}

gif()
{
    echo "Creating GIF..."
    ffmpeg -loglevel error -i timelapse.mp4 -filter_complex "[0:v] fps=30,scale=640:-1,split [a][b];[a] palettegen [p];[b][p] paletteuse" -y timelapse.gif
    echo " - Created timelapse.gif"

    echo "Compressing GIF..."
    gifsicle -O3 timelapse.gif --lossy=100 --colors 128 -o timelapse.gif
    echo " - Compressed timelapse.gif"
}



################## RUN SCRIPT ##################

echo "Change directory to /Werfcam..."
cd /Users/tom/Dropbox/Apps/Werfcam/
echo " - Current directory is: $PWD"

echo "Creating backup of images..."
export GZIP=-9
name=$(date '+%Y%m%d_%H%M%S')
tar -cf - *.jpg | xz -9 -c - > "$name.tar.gz"
echo " - Backup $name.tar.gz complete." 

if [ $# -eq 0 ]; then
    video
fi

while [ "$1" != "" ]; do

    # ALIGN IMAGES
    if [ "$1" = "--alignment" ]; then
        alignment
    fi

    # VIDEO HD
    if [ "$1" = "--hd" ]; then
        video_hd
    fi

     # VIDEO
    if [ "$1" = "--video" ]; then
        video
    fi

    # GIF
    if [ "$1" = "--gif" ]; then
        gif
    fi

    shift
done

echo "Removing old backups..."
ls -tp ./*.tar.gz | grep -v '/$' | tail -n +5
ls -tp ./*.tar.gz | grep -v '/$' | tail -n +5 | xargs -I {} rm -- {}

echo "[COMPLETED]"