require 'entran/version.rb'
require 'enrollment'
require 'user'
require 'course'
require 'section'
require 'account'
require 'term'
require 'zipruby'
require 'faraday'
require 'yaml'
require 'csv'
require 'open-uri'
require 'nokogiri'
require 'csv'
require 'powerpack'
#require 'openssl'
require 'net/http/post/multipart'
#require 'canvas'
#require 'zip/zip'

# Add requires for other files you add to your project here, so
# you just need to require this one file in your bin file

def load_files(files, kind, presence, ims_key, banner_host,year)

  #url = "https://#{banner_host}/banner/public/program/feed?feed_type=moodle&key=#{ims_key}&min_term=201210"
  #puts url
  #@ims_xml = Nokogiri::XML(open(url, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))

  url = "http://#{presence}/feeds/#{year}10/#{kind}/lms_courses.xml"
  puts url
  @lms_courses_xml = Nokogiri::XML(open(url))

  url = "http://#{presence}/feeds/#{kind}/#{year}/terms.xml"
  puts url
  @terms_xml = Nokogiri::XML(open(url))

  url = "http://#{presence}/feeds/#{kind}/#{year}/terms.csv"
  puts url
  @terms_csv = open(url)

  #puts @catalogs.class
  #puts @lms_courses_xml

  #files[:ims] = @ims_xml
  files[:lms_courses] = @lms_courses_xml
  files[:terms_xml] = @terms_xml
  #files[:catalogs] = @catalogs
  files[:terms_csv] = @terms_csv
  files
end

def course_created?(sis_id, global_options)
  require 'json'
  token = global_options[:t]
  hostname = global_options[:h]
  uri = URI.parse("https://#{hostname}/api/v1/courses/sis_course_id:#{sis_id}")
  puts uri
  req = Net::HTTP::Get.new(uri.request_uri)
  req.add_field("Authorization", "Bearer #{token}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  if global_options[:d]
    puts "----------------->debug mode so not talking to canvas host"
    return true
  else
    puts "----------------->trying to find out if course is on canvas host"
    response = http.request(req)

    return response.code.to_i == 200 #if 200 then then course has been created so we can skip it.

  end
  return false
end

