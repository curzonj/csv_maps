xml.instruct! :xml, :version=>"1.0" 
xml.rss(:version=>"2.0", "xmlns:georss" => "http://www.georss.org/georss") do
  xml.channel do
    xml.title(@csv_map.name)
    xml.language('en-us')
    @csv_map.points.each do |record|
      xml.item do
        xml.title record['title']
        xml.description do
          output = @csv_map.headers.collect do |hdr|
            "#{hdr}: #{record[hdr].strip}" unless record[hdr].blank?
          end
          xml.cdata! output.compact.join("<br/>\n")
        end

        xml.georss :point do
          xml.text! "#{record['latitude']} #{record['longitude']}".strip
        end
      end
    end
  end
end
