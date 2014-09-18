class WatchController < ApplicationController
  

  require 'pp'
  include Sys

  def curl(url)
		c = Curl::Easy.new(url) do |curl|
			curl.http_auth_types = :basic
			#curl.userpwd = "admin:#{Settings.solarwinds_admin_password}"
			#curl.username = 'admin'
			#curl.password = Settings.solarwinds_admin_password
			curl.ssl_verify_host = 0
			curl.ssl_verify_peer = false
			curl.verbose = false
			curl.use_ssl = 3
			curl.ssl_version = 3
			curl.headers['Accept'] = 'application/json'
		end
		c.perform
		response = JSON.parse(c.body_str)
		return response
	end

  def index
  	@stations = curl("http://192.168.1.165/lineup.json")
  end

  	def wait
  		stuff = ProcTable.ps
		stuff.each do |process|
			if process.cmdline.to_s.include? "ffmpeg"
				puts process.pid
				puts process.cmdline.to_s
				Process.kill("HUP", process.pid)
			end
		end
  		pid = fork do
  			exec "ffmpeg -i http://192.168.1.165:5004/auto/v#{params[:station]}?transcode=internet240 -async 1 -ss 00:00:05 -acodec aac -strict -2  -b:a 64k -ac 2 -vcodec copy -preset superfast  -tune zerolatency  -threads 2  -flags -global_header -fflags +genpts -map 0:0 -map 0:1 -hls_time 2 -hls_wrap 40 public/test.m3u8 > /dev/null"
		end
	end

	def watch
	end

	def programs
		@@programs = curl("http://api.rovicorp.com/TVlistings/v9/listings/linearschedule/20555/info?locale=en-US&duration=0&inprogress=true&apikey=zu2jfacvgek8wfeb4mgxzhne")
		pp @@programs
		@programs = @@programs['LinearScheduleResult']['Schedule']['Airings'].sort_by { |k| k["Channel"].to_f }
	end
end
