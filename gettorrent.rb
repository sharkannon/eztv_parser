require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'net/https' 
require 'yaml'

shows = YAML::load(File.open("shows.yaml"))

def getMagnetLinks(id, name)
    url = "https://eztv.it"
    url_mirror = "https://eztv-proxy.net"
    magnetList = Array.new
    begin
        page = Nokogiri::HTML(open("#{url}/shows/#{id}/#{name}/", {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
    
    rescue => e
        case e
            when OpenURI::HTTPError
                page = Nokogiri::HTML(open("#{url_mirror}/shows/#{id}/#{name}/", {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
            when SocketError
                page = Nokogiri::HTML(open("#{url_mirror}/shows/#{id}/#{name}/", {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
            else
                raise e 
        end
        
    rescue SystemCallError => e
            if e === Errno::ECONNRESET
                page = Nokogiri::HTML(open("#{url_mirror}/shows/#{id}/#{name}/", {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
            end
    end
        
    links = page.css("a")
    
    links.each do |link|
        if link["href"] =~ /^magnet:.*/ 
            magnetList.push(link["href"])
        end
    end
    
    return magnetList
end

def downloadShow(magnet)
    system "transmission-remote -a \"#{magnet}\""
end

def getEpisodeNumber(magnet)
    episodeMatch = magnet.match(/dn=.*\.[Ss]?(\d+)[XxEe](\d+)/)
    return episodeMatch[2].to_i
end

def getSeasonNumber(magnet)
    seasonMatch = magnet.match(/dn=.*\.[Ss]?(\d+)[XxEe](\d+)/)
    return seasonMatch[1].to_i
end

def getUniqueEpisodes(magnetArray, fileContentsArray)
    downloadableMagnets = Array.new
    
    magnetArray.each do |magnet|
        season = getSeasonNumber(magnet)
        episode = getEpisodeNumber(magnet)
        re = /dn=.*\.[Ss]?0?#{season}[XxEe]0?#{episode}\./
        episodeMagnetCount = downloadableMagnets.grep(re).count
        episodeFileCount = fileContentsArray.grep(re).count
        if episodeMagnetCount == 0 && episodeFileCount == 0
            downloadableMagnets.push(magnet)
        end
    end
    
    return downloadableMagnets
end

shows.each do |id,name|
    puts "Processing show: #{name}(#{id})"
    
    folderName = "shows"
    fileName = "#{folderName}/#{name}.txt"
    contents = Array.new
    
    unless File.exists?(folderName)
        Dir.mkdir(folderName)
    end
    
    if File.exists?(fileName)
        file = File.open(fileName, 'r')
            
        file.each_line {|line|
            contents.push line.gsub("\n",'')
        }
    end
    
    newMagnets = Array.new

    File.open(fileName, 'a') do |f|
        magnets = getMagnetLinks(id,name)
        magnets.each do |magnet|
            if ! contents.include?(magnet)
                newMagnets.push magnet
                f.puts magnet
            end
        end
    end

    uniqueEpisodes = getUniqueEpisodes(newMagnets,contents)
    uniqueEpisodes.each do |magnet|
        #downloadShow(magnet)
        puts magnet
    end
end

