require 'entran/version.rb'
require 'boolean'
require 'enrollment'
require 'person'
require 'course'
require 'section'
require 'account'
require 'settings'
require 'term'
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



# Add requires for other files you add to your project here, so
# you just need to require this one file in your bin file

class String
  def to_bool
    return true if self =~ (/^(true|t|yes|y|1)$/i)
    return false if self.empty? || self =~ (/^(false|f|no|n|0)$/i)

    raise ArgumentError.new "invalid value: #{self}"
  end
end

def load_files(files, kind, presence, ims_key, banner_host,year)



  url = "http://#{banner_host}/banner/public/offerings/export"
  puts url
  @offerings_xml = Nokogiri::XML(open(url))

  url = "http://#{presence}/feeds/#{kind}/lms_courses.xml"
  puts url
  @lms_courses_xml = Nokogiri::XML(open(url))

  start_year = @lms_courses_xml.xpath("//offering_feed/start_year/@year").text.to_i
  end_year = @lms_courses_xml.xpath("//offering_feed/end_year/@year").text.to_i
  url = "http://#{presence}/feeds/#{kind}/#{start_year}/#{end_year}/terms.xml"
  puts url
  @terms_xml = Nokogiri::XML(open(url))

  url = "http://#{presence}/feeds/#{kind}/#{start_year}/#{end_year}/terms.csv"
  puts url
  @terms_csv = open(url)


  files[:lms_courses] = @lms_courses_xml
  files[:terms_xml] = @terms_xml
  files[:offerings_xml] = @offerings_xml
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

def send_sis(files,client)
  files.each do |name,data|
    import = client.import_sis_data(1, {attachment: UploadIO.new(StringIO.new(data) , 'text/csv', "#{name}.csv"),
                                        import_type: 'instructure_csv',
                                        extension: 'csv'
                                     })
    puts import
  end


end

