require 'fastercsv'
require 'yahoo'
require 'dm-core'
require 'do_sqlite3'
require 'json'
require 'digest/md5'

ENV['DATABASE_URL'] ||= "sqlite3://#{Dir.pwd}/db.sqlite3"
case ENV['DATABASE_URL']
when /postgres/
  require 'do_postgres'
when /mysql/
  require 'do_mysql'
when /sqlite/
  require 'do_sqlite3'
end

DataMapper.setup(:default, ENV['DATABASE_URL'])

class CsvMap
  include DataMapper::Resource

  class << self
    attr_accessor :title_field
  end

  property :slug, String, :key => true
  property :name, String
  property :headers_data, Text
  property :points_data, Text
  property :csv_data, Text

  def file=(uploadfile)
    @upload = uploadfile
  end

  def points
    JSON.parse(self.points_data)
  end

  def headers
    self.headers_data.split(',')
  end

  def import
    @points = []
    self.csv_data = @upload[:tempfile].read

    FasterCSV.parse(self.csv_data, :headers => true) do |line|
      self.headers_data ||= line.headers.join(',')

      @points << parse_line(line)
    end

    self.points_data = @points.to_json
    self.slug = Digest::MD5.hexdigest("#{self.headers_data} - #{rand(10000000)} - #{Time.now}")
    self.save
  rescue
    LOG.error("Exception: "+$!.message)
    raise $! if ENV['RACK_ENV'] == 'development'

    false
  end

  def parse_line(line)
    hash = line.to_hash

    coords = coordinates(line)
    LOG.info("GeoLocate resolved to #{coords.inspect}")
    hash['latitude'] = coords[:latitude]
    hash['longitude'] = coords[:longitude]

    unless self.class.title_field.nil?
      hash['title'] = hash[self.class.title_field]
    end

    hash
  end

  def coordinates(line)
    hdr = line.headers
    opts = {}

    { :street => /Street 1/, :zip => /[Zip|Postal] Code/ }.each do |k,v|
      field = hdr.select {|h| h.match(v) }.first
      opts[k] = line[field]
    end
    LOG.info("Looking up #{opts.inspect}")

    Yahoo.geocode(opts)
  end
end

#CsvMap.auto_migrate!
