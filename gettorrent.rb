require 'rubygems'
require 'yaml'
require 'optparse'
require_relative 'lib/EzTVClass.rb'

options = {}
optparse = OptionParser.new do |opts|
    options[:skipDownload] = false
    opts.on('-t') do
        options[:skipDownload] = true
    end

    options[:force] = false
    opts.on('-f') do
        options[:force] = true
    end
end

optparse.parse!

shows = YAML::load(File.open("shows.yaml"))

#Main Block
shows.each do |id,name|
    eztv = EzTVClass.new(name,id)

    if eztv.getShowStatus == "Airing" || options[:force]
        puts "Processing show: #{eztv.show}(#{eztv.id}), Status: #{eztv.getShowStatus}"
        folderName = "shows"
        fileName = "#{folderName}/#{eztv.show}.txt"
        contents = Array.new
    
        unless File.exists?(folderName)
            Dir.mkdir(folderName)
        end
    
        if File.exists?(fileName)
            file = File.open(fileName, 'r')
    
            file.each_line do |line|
                contents.push line.gsub("\n",'')
            end
        end
    
        newMagnets = Array.new
    
        File.open(fileName, 'a') do |f|
            magnets = eztv.getMagnetLinks()
    
            magnets.each do |magnet|
                if ! contents.include?(magnet)
                    newMagnets.push magnet
                    f.puts magnet
                end
            end
        end
    
        uniqueEpisodes = EzTVClass.getUniqueEpisodes(newMagnets,contents)
    
        uniqueEpisodes.each do |magnet|
            if skipDownload then
                puts match
            else
                EzTVClass.downloadShow(magnet)
            end
        end
    end
end
