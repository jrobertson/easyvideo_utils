# Introducing the easyvideo_utils gem

A wrapper for ffmpeg to make basic video editing easier.

## Usage

    require 'easyvideo_utils'

    # resize a video to 720p
    EasyVideoUtils.new('output.mp4', 'out2.mp4').resize

    # search for a method related to audio
    EasyVideoUtils.search 'audio'
    #=> * add_audio add an audio track
  
    # list all available public methods
    EasyVideoUtils.list

Output:
<pre>
 * add_audio add an audio track
 * add_subtitles add subtitles from a .srt file
 * capture capture the desktop at 1024x768
 * convert alias for transcode
 * play plays the video using mplayer
 * record alias for capture
 * resize resize to 720p
 * scale alias for resize
 * transcode converts 1 video format to another e.g. avi-> mp4
 * trim trims the beginning and ending of a video in hms format e.g. 1m 3s
</pre>

## Resources

ffmpeg mplayer video editing utils gem easyvideoutils
