#!/usr/bin/env ruby

# file: easyvideo_utils.rb

require 'c32'
require 'subunit'
require 'easyimg_utils' 

# requirements:
# `apt-get install mplayer ffmpeg vorbis-tools exiftool libav-tools`

# note:  Although this gem tries to be full-proof it's dependent upon the 
#        command-line tools to do the heavy lifting, as a result is prone 
#        to nuisance factors.
# tip: instead of using transcode, try specifing the target encoding based on 
#      the extension type when using multiple 
#       operations e.g. EasyVideoUtils.new('vid2.avi', 'vid3.mp4').resize

# installing youtube-dl:
# 
# `sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/bin/youtube-dl`
#
# `sudo chmod a+rx /usr/bin/youtube-dl`

module CommandHelper
  using ColouredText
  
  def list(a=@commands)

    format_command = ->(s) do
      command, desc = s.split(/\s+#\s+/,2)
      " %s %s %s" % ['*'.blue, command, desc.to_s.light_black]
    end

    puts a.map {|x| format_command.call(x) }.join("\n")

  end

  def search(s)
    list @commands.grep Regexp.new(s)
  end

end

class EasyVideoUtils
  extend CommandHelper

@commands = "
* add_audio # add an audio track
* add_subtitles # add subtitles from a .srt file
* concat # concatenate 2 or more videos
* convert # alias for transcode
* capture # capture the desktop at 1024x768
* create_poster # Video created from audio file + static image
* create_slideshow # Combines images to create a video. Defaults to 5 seconds per image
* extract_images # Extracts images at 1 FPS by default
* info
* grab_image # grabs a single image at 1 second in by default
* play # plays the video using mplayer
* preview # plays the video using ffplay
* record # alias for capture
* remove_audio # removes the audio track from a video
* remove_video # removes the video track from a video. Output file would be an mp3.
* resize # resize to 320x240 
* scale # alias for resize
* screencast # lightweight screenshot recorder -> animated gif -> mp4. see also capture
* slowdown # slows a viedo down. Defaults to x2 (half-speed)
* speedup # speed a video up. Defaults to x2 (twice as fast)
* transcode # converts 1 video format to another e.g. avi-> mp4 or gif -> mp4
* trim # trims the beginning and ending of a video in hms format e.g. 1m 3s
* youtube_dl # downloads in mp4 format
".strip.lines.map {|x| x[/(?<=\* ).*/]}.sort


  def initialize(vid_in=nil, vid_out='video.mp4', out: vid_out, 
                 working_dir: '/tmp', debug: false)

    @file_out, @working_dir, @debug = out, working_dir, debug
    
    if vid_in.is_a? String then
      @file_in = vid_in
    elsif vid_in.is_a? Array
      @files_in = vid_in
    end

  end

  # Add an audio track to a video which contains no audio
  #
  def add_audio(audio_file, show: false)

    command = "ffmpeg -i #{@file_in} -i #{audio_file} -codec copy " + 
              "-shortest #{@file_out} -y"
    run command, show

  end

  # To add subtitles, supply a .srt file
  #
  def add_subtitles(file, show: false)
       
    command = "ffmpeg -i #{@file_in} -i #{file} -c copy -c:s mov_" + 
              "text #{@file_out} -y"
    run command, show
    
  end

  def capture_desktop(show: false)

    command = "ffmpeg -video_size 1024x768 -framerate 25 -f x11grab -i " + 
    ":0.0+0,0 #{@file_out}"
    run command, show

  end
  
  # Concatenate 2 or more videos
  #
  # Notes:
  # * Video must be of same format and codec
  # * Only video with no audio is currently supported
  #
  def concat(files=@files_in, show: false)
    
    inputs = files.map {|file| "-i #{file}"}.join(' ')
    filter = files.map.with_index {|file,i| "[%s:v]" % i}.join(' ')
    
    command = "ffmpeg #{inputs} \ " + 
    " -filter_complex \"#{filter} concat=n=#{files.length}:v=1 [v]\" \ " + 
    " -map \"[v]\"  #{@file_out}"

    run command, show
    
  end
  
  # creates a video from an audio file along with a single image file
  #
  def create_poster(audiox=nil, imagex=nil, image: imagex, 
                    audio: audiox, show: false)
    command = "ffmpeg -loop 1 -i #{image} -i #{audio} -c:v libx264 -c:a " + 
        "aac -strict experimental -b:a 192k -shortest #{@file_out}"
    run command, show
  end

  def create_slideshow(ext: '.jpg', image_duration: 5, show: false)
    
    file_mask = @file_in || "image-%03d" + ext
    command = "ffmpeg -r 1/#{image_duration} -i #{file_mask} -c:v " + 
        "libx264 -r 30 -pix_fmt yuv420p #{@file_out}"  
    run command, show
    
  end
  
  # Duration returned in seconds
  #
  def duration()
    
    s = `exiftool #{@file_in}`
    puts 's: ' + s.inspect if @debug
    r = s[/Duration.*(\d{1,2}:\d{2}:\d{2})/,1]

    puts 'r: ' + r.inspect if @debug    
    
    if r then
      a = r.split(':').map(&:to_i)
      return Subunit.new(units={minutes:60, hours:60, seconds: 0}, a).to_i
    end
    
    puts 'r: ' + r.inspect if @debug
    s[/Duration.*: (\d+\.\d+) s/,1].to_f

  end

  # Extract images from the video
  #
  # switches used:
  #
  # -r – Set the frame rate. I.e the number of frames to be extracted into images per second.
  # -f – Indicates the output format i.e image format in our case.
  # 
  def extract_images(show: false, ext: '.png', rate: 1)
    command = "ffmpeg -i #{@file_in} -r #{rate} -f image2 image-%2d#{ext}"
    run command, show
  end
  
  def info(show: false)
    command = "avprobe #{@file_in}"
    run command, show
  end  
  
  def grab_image(start_time=1, show: false)
    command = "avconv -i #{@file_in} -ss #{start_time.to_s} -frames:v 1 #{@file_out} -y"
    run command, show
  end

  def play(show: false)
    command = "mplayer #{@file_out}"
    run command, show
  end
  
  def preview(show: false)
    command = "ffplay #{@file_out}"
    run command, show
  end

  def remove_audio(show: false)
    command = "ffmpeg -i #{@file_in} -an #{@file_out}"
    run command, show
  end
  
  # removes the video track which leaves the audio track
  # e.g. ffmpeg -i input.mp4 -vn output.mp3
  #
  def remove_video(show: false)
    command = "ffmpeg -i #{@file_in} -vn #{@file_out}"
    run command, show
  end

  # Resize e.g. to 320x240
  #
  def resize(scale='320x240', show: false)
    command = "avconv -i #{@file_in} -s #{scale} #{@file_out} -y"
    run command, show
  end
  

  alias scale resize

  # starts recoring after 2 seconds  for a duration of 6 seconds
  #
  def screencast(duration: 6, scale: 0.75, window: true)
    
    gif_file = @file_out.sub(/\w+$/,'gif')
    
    EasyImgUtils.new(out: gif_file)\
        .screencast(duration: duration, scale: scale, window: window)
    EasyVideoUtils.new(gif_file, @file_out).transcode
    
  end
  
  # slow down a video
  #
  # note:  presentation timestamp (PTS)
  # 'x2' = half speed; 'x4' = quarter speed
  
  def slowdown(speed=:x2, show: false)
    
    factor = {x1_5: 1.5, x2: 2.0, x4: 4.0}[speed.to_s.sub('.','_').to_sym]
    command = "ffmpeg -i #{@file_in} -vf \"setpts=#{factor}*PTS\" " + 
        "#{@file_out} -y"
    run command, show
    
  end    
  
  # speed up a video
  #
  # note:  presentation timestamp (PTS)
  # 'x2' = double speed; 'x4' = quadruple speed
  
  def speedup(speed=:x2, show: false)
    
    h = {x1_5: 0.75, x2: 0.5, x4: 0.25, x6: 0.166, x8: 0.125, x16: 0.0625, 
         x32: 0.03125, x64: 0.015625}
    factor = h[speed.to_s.sub('.','_').to_sym]
    command = "ffmpeg -i #{@file_in} -vf \"setpts=#{factor}*PTS\" " + 
        "#{@file_out} -y"
    run command, show
    
  end      

  # Transcodes avi -> mp4
  #
  def transcode(show: false)
    
    return gif_to_mp4() if File.extname(@file_in) == '.gif'
    
    command = "ffmpeg -i #{@file_in} #{@file_out} -y"
    run command, show    

  end
    
  alias convert transcode

  # Trim the start and end of the video
  # times can be expressed in human time format e.g. '1m 4s', '2m 30'
  #
  def trim(start_time, duration, show: false)
        
    t1 = "%02d:%02d:%02d" % (start_time.to_s.sub(/m/,'\00s').split(/\D/)\
                             .reverse + [0,0]).take(3).reverse
    
    command = "avconv -i #{@file_in} -ss #{t1} -t #{duration.to_s} " + 
        "-codec copy #{@file_out}"
    run command, show
    
  end
  
  # Download a video from YouTube
  #
  def youtube_dl(show: false)    
    
    command = "youtube-dl -f 'bestvideo[ext=mp4]+" + 
        "bestaudio[ext=m4a]/best[ext=mp4]/best' #{@file_in}"
    command += ' -o ' + @file_out if @file_out
    run command, show    

  end  

  private

  # see https://unix.stackexchange.com/questions/40638/how-to-do-i-convert-an-animated-gif-to-an-mp4-or-mv4-on-the-command-line
  #
  def gif_to_mp4(show: false)
    
    command = "ffmpeg -i %s -movflags faststart -pix_fmt yuv420p \
        -vf \"scale=trunc(iw/2)*2:trunc(ih/2)*2\" %s" % [@file_in, @file_out]
    run command, show
    
  end    

  def run(command, show=false)

    if show then 
      command
    else
      puts "Using ->" + command
      system command
    end

  end

end

if __FILE__ == $0 then

  # e.g. ruby easyvideo_utils.rb video.mp4 resize video2.mp4
  EasyVideoUtils.new(ARGV[0], ARGV[2]).method(ARGV[1].to_sym).call(*ARGV[3..-1])

end
