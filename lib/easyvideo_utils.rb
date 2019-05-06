#!/usr/bin/env ruby

# file: easyvideo_utils.rb

require 'c32'
require 'subunit'


# requirements:
# `apt-get install mplayer ffmpeg vorbis-tools`exiftool


module CommandHelper
  using ColouredText
  
  def list(a=@commands)

    format_command = ->(s) do
      command, desc = s.split(/\s+#\s+/,2)
      " %s %s %s" % ['*'.blue, command, desc.to_s.light_black]
    end

    s = a.map {|x| format_command.call(x) }.join("\n")
    puts s
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
* play # plays the video using mplayer
* preview # plays the video using ffplay
* record # alias for capture
* resize # resize to 720p
* scale # alias for resize
* transcode # converts 1 video format to another e.g. avi-> mp4
* trim # trims the beginning and ending of a video in hms format e.g. 1m 3s
".strip.lines.map {|x| x[/(?<=\* ).*/]}.sort


  def initialize(vid_in=nil, vid_out='video.mp4', out: vid_out, 
                 working_dir: '/tmp', debug: false)

    @file_in, @file_out, @working_dir, @debug = vid_in, out, working_dir, debug

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
  def concat(files=[], show: false)
    
    inputs = files.map {|file| "-i #{file}"}.join(' ')
    filter = files.map.with_index {|file,i| "[%s:v]" % i}.join(' ')
    
    command = "ffmpeg #{inputs} \ " + 
    " -filter_complex \"#{filter} concat=n=#{files.length}:v=1 [v]\" \ " + 
    " -map \"[v]\"  #{@file_out}"

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

  def play(show: false)
    command = "mplayer #{@file_out}"
    run command, show
  end
  
  def preview(show: false)
    command = "ffplay #{@file_out}"
    run command, show
  end  

  # Resize avi to 720p
  #
  def resize(show: false)
    `ffmpeg -i #{@file_in} -vf scale="720:-1" #{@file_out} -y`
  end

  alias scale resize

  # Transcodes avi -> mp4
  #
  def transcode(show: false)
    
    command = "ffmpeg -i #{@file_in} #{@file_out} -y"
    run command, show    

  end
    
  alias convert transcode

  # Trim the start and end of the video
  # times are expressed in human time format e.g. '1m 4s', '2m 30'
  #
  def trim(start_time, end_time, show: false)
        
    t1, t2 = [start_time, end_time].map do |s|

      "%02d:%02d:%02d" % (s.sub(/m/,'\00s').split(/\D/).reverse + [0,0])\
                          .take(3).reverse

    end
    
    command = "ffmpeg -i #{@file_in} -ss #{t1} -t #{t2} -async 1 " + 
              "#{@file_out} -y"
    run command, show
    
  end

  private

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
