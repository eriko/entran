require 'entran/version.rb'
require 'enrollment'
require 'user'
require 'course'
require 'term'
require 'zipruby'
require 'faraday'
require 'yaml'
require 'csv'
require 'open-uri'
require 'nokogiri'
require 'csv'
#require 'openssl'
require 'net/http/post/multipart'
#require 'canvas'
#require 'zip/zip'

# Add requires for other files you add to your project here, so
# you just need to require this one file in your bin file

def load_files(files, kind,presence,ims_key ,banner_host)
  @ims_xml = Nokogiri::XML(open("https://#{banner_host}/banner/public/program/feed?feed_type=moodle&key=#{ims_key}&min_term=201210") )
  #@canvases = Nokogiri::XML(open('http://presence.evergreen.edu/feeds/canvases.xml') )
  @lms_courses_xml = Nokogiri::XML(open("http://#{presence}/feeds/lms_courses.xml") )
  #@terms_xml = Nokogiri::XML(open("http://adminweb.evergreen.edu/banner/public/catalog/terms"))
  @terms_xml = Nokogiri::XML(open("http://#{presence}/feeds/#{kind}/terms.xml"))
  #@catalog-2013_xml = Nokogiri::XML(open("http://adminweb.evergreen.edu/banner/public/program/catalog/2013"))
  #@catalogs = Hash[2013 =>  Nokogiri::XML(open('http://adminweb.evergreen.edu/banner/public/program/catalog/2013')) , 2014 =>  Nokogiri::XML(open('http://adminweb.evergreen.edu/banner/public/program/catalog/2014'))]
  @terms_csv = open("http://#{presence}/feeds/#{kind}/terms.csv")

  #@ims_xml = Nokogiri::XML(open('../tmp/ims.xml'))
  #@lms_courses_xml = Nokogiri::XML(open('../tmp/lms_courses.xml'))
  #@terms_xml = Nokogiri::XML(open('../tmp/terms.xml'))
  #@catalog_html = Nokogiri::HTML(open('../tmp/1213catalog.html'))
  #@catalogs = Hash[2013 =>  Nokogiri::XML(open('../tmp/catalog-2013.xml')) , 2014 =>  Nokogiri::XML(open('../tmp/catalog-2014.xml'))]

  puts @catalogs.class

  files[:ims] = @ims_xml
  files[:lms_courses] = @lms_courses_xml
  files[:terms_xml] = @terms_xml
  #files[:catalogs] = @catalogs
  files[:terms_csv] = @terms_csv
  files
end

