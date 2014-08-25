require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'net/https' 
require 'yaml'

class EzTVClass
    attr_accessor :show, :id
    @page = nil
    
    def initialize(show, id)
        @show = show
        @id = id
        
        url = "https://eztv.it"
        urlMirror = "https://eztv-proxy.net"
        urlPath = "shows/#{@id}/#{@show}"
        
        begin
            @page = Nokogiri::HTML(open("#{url}/#{urlPath}/", {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
        
        rescue => e
            case e
                when OpenURI::HTTPError, SocketError
                    @page = Nokogiri::HTML(open("#{urlMirror}/#{urlPath}/", {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
                else
                    raise e 
            end
            
        rescue SystemCallError => e
            if e === Errno::ECONNRESET
                @page = Nokogiri::HTML(open("#{urlMirror}/#{urlPath}/", {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}))
            else
                raise e
            end
        end
    end
    
    def getMagnetLinks()
        magnetList = Array.new
        
        links = @page.css("a")

        links.each do |link|
            if link["href"] =~ /^magnet:.*/ 
                magnetList.push(link["href"])
            end
        end
        
        return magnetList
    end
    
    def getShowStatus()
       statuscell = @page.css("td.show_info_airs_status")
       status = statuscell.to_s
       return status.match(/Status:\s?(<b>)?([A-Za-z]+)(<\/b>)?/)[2]
    end
    
    def EzTVClass.downloadShow(magnet)
        system "transmission-remote -a \"#{magnet}\""
    end
    
    def EzTVClass.getEpisodeNumber(magnet)
        episodeMatch = magnet.match(/dn=.*\.[Ss]?(\d+)[XxEe](\d+)/)
        return episodeMatch[2].to_i
    end
    
    def EzTVClass.getSeasonNumber(magnet)
        seasonMatch = magnet.match(/dn=.*\.[Ss]?(\d+)[XxEe](\d+)/)
        return seasonMatch[1].to_i
    end
    
    def EzTVClass.getUniqueEpisodes(magnetArray, fileContentsArray)
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
end