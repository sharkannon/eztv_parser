#!/usr/bin/env ruby
require 'rubygems'
require 'yaml'
require 'optparse'
require_relative 'lib/EzTVClass.rb'

#options parsing, valid options atm are -t and -f.
# -t is used to skip the download feature and just create the text files with the magnets in it so that you don't have to download everything
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

# loads "shows.yaml" in the current running folder.
# TODO: Update to make this dynamic so you can pass the file in as an argument
shows = YAML::load(File.open("shows.yaml"))

#Main Block
shows.each do |id,name|
    eztv = EzTVClass.new(name,id)

#Test if the status is "Airing", no point downloading/parsing stuff if there isn't active uploads.  This can be overriden by the -f option.

    if eztv.getShowStatus == "Airing" || options[:force]
        puts "Processing show: #{eztv.show}(#{eztv.id}), Status: #{eztv.getShowStatus}"
        folderName = "shows"
        fileName = "#{folderName}/#{eztv.show}.txt"
        contents = Array.new
    
        unless File.exists?(folderName)
            Dir.mkdir(folderName)
        end
    
#Open the text file containing the magnets if it does exist
        if File.exists?(fileName)
            file = File.open(fileName, 'r')
    
            file.each_line do |line|
                contents.push line.gsub("\n",'')
            end
        end
    
        newMagnets = Array.new
   
#Append new magnets to the file if they exist 
        File.open(fileName, 'a') do |f|
            magnets = eztv.getMagnetLinks()
    
            magnets.each do |magnet|
                if ! contents.include?(magnet)
                    newMagnets.push magnet
                    f.puts magnet
                end
            end
        end
    
#Parse the magnets to get unique episodes (That way we don't download 6 copies of the same show.)
#NOTE: Because of this, you can't be selective of what version of the show is downloaded.  It just downloads which ever it finds first.
        uniqueEpisodes = EzTVClass.getUniqueEpisodes(newMagnets,contents)
    
        uniqueEpisodes.each do |magnet|
            if options[:skipDownload] then
                puts match
            else
                EzTVClass.downloadShow(magnet)
            end
        end
    end
end
