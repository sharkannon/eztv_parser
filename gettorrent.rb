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

shows.each do |key,value|
    puts "Processing show: #{value}(#{key})"
    
    folderName = "shows"
    fileName = "#{folderName}/#{value}.txt"
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
    
    File.open(fileName, 'a') {|f|
        magnets = getMagnetLinks(key,value)
        magnets.each do |val|
            if ! contents.include?(val)
                downloadShow(val)
		f.puts val
            end
        end        
    }
end
