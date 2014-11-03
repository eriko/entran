class Course
  require 'securerandom'
  require "base64"
  require 'json'

  attr_accessor :course_id, :curricular_year, :short_name, :long_name, :account_id,
                :status, :start_date, :end_date, :offering_type, :terms, :summary,
                :banner_offering_id, :offering_id, :offering_code, :account_id, :sections, :real_term,
                :enrollment_term, :offering_codes, :enrollments, :faculty, :created, :available,
                :setup, :setup_frontpage, :setup_nav, :setup_modules, :website_id,
                :modules, :module_links, :kind , :waitlist ,:override

  def initialize
    @module_links = Hash.new
    @offering_codes = []
    @enrollments = []
    @faculty = []
    @sections = Hash.new
    @modules = Hash.new
  end


  def to_array(kind)
    #puts "#{course_id} #{long_name} #{real_term}"
    case kind
      when :canvas
        #puts "the course id being processed is #{course_id}"
        [course_id, short_name, long_name, account_id, real_term.term_id, status, first_term.start_date.iso8601, end_date]
      when :moodle
        [long_name, short_name, 'topic', first_term.start_date.strftime('%d/%m/%G'), self.weeks, self.type_display, course_id, summary, 0, 'manual', 1, 'self', 0, 'Self enrollment (Student)', course_password, "Welcome to #{self.long_name}", 5]
    end
  end

  def course_password
    "#{self.short_name[0..25]}-#{SecureRandom.hex(2)}-TESC"
  end

  def type_display
    case self.offering_type
      when "Program"
        "Academic Offerings/#{Term.acad_year_display(first_term)}/#{first_term.season} #{first_term.calendar_year} Programs"
      when "Course"
        "Academic Offerings/#{Term.acad_year_display(first_term)}/#{first_term.season} #{first_term.calendar_year} Courses"
      when "Cohort"
        "Academic Offerings/Cohorts starting #{Term.acad_year_display(first_term)}/#{first_term.season} #{first_term.calendar_year} Offerings"
    end
  end


  def first_term
    self.terms.sort[0]
  end

  def weeks
    count = 0
    self.terms.each { |term| count += term.weeks.count }
    count

  end

  def Course.import_xml(lms_courses_xml, terms, catalogs, kind, all_sections, users)
    #The courses to be used are from presence where the course site has beeen marked requested.
    #Then data from other data sources like the ims.xml feed will be used to gather the full set of data
    #based on the list from presence
    @courses = Hash.new
    lms_courses_xml.xpath("//offering").each do |offering|
      #each offering may have any number of websites with will be processed separately
      offering.xpath("./websites/website").each do |website|
        if website.xpath("./type[text()]").text.eql? kind
          #puts "there was a course of #{kind}"
          #course_id will be used as the identifier and for querying the other data sources.
          course_id = website.xpath("./course_id/@id").text
          @course = Object::const_get(website.xpath("./type[text()]").text).new()
          #puts "@course is of type #{@course.class}"
          @course.course_id = course_id
          @course.kind = offering.xpath('./type').text
          @course.website_id = website.xpath("./websiteid/@id").text
          @course.banner_offering_id = offering.xpath("@banner_offering_id").text
          @course.offering_id = offering.xpath("@offering_id").text
          @course.enrollment_term = offering.xpath("./enrollment_term/@term_code").text
          @course.offering_codes = offering.xpath("./oars_offerings/oars_offering/@code").collect { |code| code }
          #puts"offering.oarsofferingcodes--->#{offering.xpath("./oars_offerings")} "
          #puts "the course id is #{course_xml.xpath("./sourcedid/id[text()]").text}"
          @course.short_name = website.xpath("./short_name").text
          @course.long_name = website.xpath("./long_name").text
          puts "cix-------------->#{@course.long_name}"
          @course.account_id = website.xpath("./account_id/@id").text
          @course.created = website.xpath("./created").text.to_bool
          @course.setup = website.xpath("./setup").text.to_bool
          @course.setup_nav = website.xpath("./setup_nav").text.to_bool
          @course.setup_frontpage = website.xpath("./setup_frontpage").text.to_bool
          @course.setup_modules = website.xpath("./setup_modules").text.to_bool
          @course.waitlist = website.xpath("./waitlist").text.to_bool
          @course.override = website.xpath("./override").text.to_bool
          @course.terms = website.xpath("./terms/term/@term_code").collect { |term_code| terms[term_code.to_s.to_i] }
          if all_sections #only do this if sections are pasted in
            website.xpath("./sections/section/@section_id").each { |section_id| @course.sections[section_id.to_s] = all_sections[section_id.to_s] }
          end
          if users #only do this if users is pasted in
            @course.faculty = website.xpath("./people/person/@username").collect { |username| users.values.find { |user| user.login_id.eql?(username.to_s) } }
            puts "cix-------------->the faculty count is: #{@course.faculty.count}"
          end
          website.xpath("./modules/module").collect { |mod| @course.modules[mod["position"].to_s.to_i] = mod }

          #puts "the course shortname  is #{@course.short_name}"
          @course.curricular_year = offering.xpath("./curricular_year[text()]").text.to_i

          real_term= website.xpath("./real_term/@term_code").to_s.to_i
          @course.real_term = terms[real_term]
          #puts "the real_term is #{ @course.real_term}"

          #this block was used to get catalog data for the description to be used by moodle
          #since we are not using this for moodle I have commented it out.
          #offering_id = offering.xpath("./offeringid").text
          #puts "the offering id is #{offering_id} is #{offering_id.class}"
          #Get the catalog description for the offering
          #@course.summary = catalogs[@course.curricular_year].xpath("/programs/program[@id=#{offering_id}]/description[text()]").text
          #if @course.summary.nil? || @course.summary.length < 1
          #  @course.summary = "Summary unavailable at moodle course creation time"
          #end
          #puts "the @course.summary is #{@course.summary}"
          @course.status = 'active'
          @course.offering_type = offering.xpath("./type[text()]").text
          #@course.start_date = @course.terms.sort[0].start_date.utc.iso8601
          #@course.end_date =@course.terms.sort.last.end_date.utc.iso8601
          @course.start_date = nil
          @course.end_date = nil
          #puts @course.start_date

          #puts @course.course_id
          @courses[@course.course_id] = @course
          #puts "The course in the hash is #{@courses[@course.class][@course.course_id].course_id} and of type #{@course.class}"
        end
      end
    end
    #puts @courses
    #puts "the total moodle course count is #{@courses[MoodleCourse.new.class].count}"
    @courses
  end


  def create_modules(client, c_course, settings)
    puts '#create module from the list'
    first_mod = nil
    begin
      self.modules.keys.sort.each do |key|
        mod_xml = self.modules[key]
        #create module from the list
        mod = client.create_module c_course["id"],
                          {'module__position__' => key,
                           'module__name__' => mod_xml["name"],
                           'module__published__' => true
                          }
        puts mod_xml
        if mod_xml["first_quarter"].eql?('true') #create the shell parts in the first module of the first quarter
          first_mod = mod
          c_mod = client.post("/api/v1/courses/#{c_course["id"]}/modules/#{first_mod["id"]}/items",
                              {
                                  'module_item__title__' => '[This is a sample header - click the settings button (gear icon at right) to edit text.]',
                                  'module_item__type__' => 'SubHeader',
                                  'module_item__position__' => 1,
                                  'module__published__' => false
                              })
          puts c_mod
          syllabus = client.post("/api/v1/courses/#{c_course["id"]}/pages",
                                 {'wiki_page__title__' => "#{self.kind} Description",
                                  'wiki_page__body__' => settings.client_module_description,
                                  'wiki_page__editing_roles__' => 'teachers',
                                  'wiki_page__published__' => false})
          c_mod = client.post("/api/v1/courses/#{c_course["id"]}/modules/#{first_mod__"id"]}/items",
                              {
                                  'module_item__title__' => '[ sample page: Description ]',
                                  'module_item__type__' => 'Page',
                                  'module_item__page_url__' => syllabus['url'],
                                  'module_item__position__' => 2,
                                  'module__published__' => false
                              })
          syllabus = client.post("/api/v1/courses/#{c_course["id"]}/pages",
                                 {'wiki_page__title__' => 'Syllabus and Covenant',
                                  'wiki_page__body__' => settings.client_module_syllabus,
                                  'wiki_page__editing_roles__' => 'teachers',
                                  'wiki_page__published__' => false})
          c_mod = client.post("/api/v1/courses/#{c_course["id"]}/modules/#{first_mod["id"]}/items",
                              {
                                  'module_item__title__' => '[ sample page: Syllabus ]',
                                  'module_item__type__' => 'Page',
                                  'module_item__page_url__' => syllabus['url'],
                                  'module_item__position__' => 2,
                                  'module__published__' => false
                              })
        end
        if mod_xml["first_week"] && mod_xml["first_week"].eql?('true') #create the shell in the first week of the first quarter
          puts "cm------------> create the shell in the first week of the first quarter"
          fw_mod = client.post("/api/v1/courses/#{c_course["id"]}/modules/#{mod["id"]}/items",
                               {
                                   'module_item__title__' => '[ This is a sample header - click the settings button (gear icon at right) to edit text. ]',
                                   'module_item__type__' => 'SubHeader',
                                   'module_item__position__' => 1,
                                   'module__published__' => false
                               })

          week1 = client.post("/api/v1/courses/#{c_course["id"]}/pages",
                              {'wiki_page__title__' => 'Week 1 Description',
                               'wiki_page__body__' => settings.client_module_week1,
                               'wiki_page__editing_roles__' => 'teachers',
                               'wiki_page__published__' => false})
          c_mod = client.post("/api/v1/courses/#{c_course["id"]}/modules/#{mod["id"]}/items",
                              {
                                  'module_item__title__' => '[ sample page: Week 1 Overview ]',
                                  'module_item__type__' => 'Page',
                                  'module_item__page_url__' => week1['url'],
                                  'module_item__position__' => 2,
                                  'module__published__' => false
                              })

        end
        #if mod_xml["link"] && !mod_xml["first_quarter"].eql?('true') #add links to the first module for later quarters
        #  puts "------------> external link to internal content of the next quarters modules"
        #  puts c_course
        #  puts first_mod
        #  puts hostname
        #  c_mod = client.post("/api/v1/courses/#{c_course["id"]}/modules/#{first_mod["id"]}/items",
        #                      {
        #                          'module_item[title]' => mod_xml['link'],
        #                          'module_item[type]' => 'ExternalUrl',
        #                          'module_item[external_url]' => "https://#{hostname}/courses/#{c_course["id"]}/modules#module_#{first_mod["id"]}",
        #                          'module_item[new_tab]' => true,
        #                          'module_item[position]' => first_mod["id"],
        #                          'module[published]' => false
        #                      }
        #  )
        #  puts c_mod
        #end


        #client.post "/api/v1/courses/#{c_course["id"]}/external_tools",
        #            {
        #                'course_navigation[url]' => mod["items_url"],
        #                'name' => mod_xml["link"],
        #                'course_navigation[text]' => mod_xml["link"],
        #                'privacy_level' => 'anonymous',
        #                'course_navigation[default]' => false,
        #                'course_navigation[enabled]' => true,
        #                'consumer_key' => 'asdfg',
        #                'shared_secret' => 'lkjh'
        #            }

        #xml = "<cartridge_basiclti_link xmlns='http://www.imsglobal.org/xsd/imslticc_v1p0' xmlns:blti='http://www.imsglobal.org/xsd/imsbasiclti_v1p0' xmlns:lticm='http://www.imsglobal.org/xsd/imslticm_v1p0' xmlns:lticp='http://www.imsglobal.org/xsd/imslticp_v1p0' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:schemaLocation='http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd'> "<<
        #    '<blti:title>Course Wanda Fish</blti:title>                                                                     '<<
        #    '<blti:description>                                                                                             '<<
        #    "This adds a link to the #{mod_xml["link"]}                                                                     "<<
        #    '</blti:description>                                                                                            '<<
        #    '<blti:extensions platform="client.instructure.com">                                                            '<<
        #    '<lticm:property name="tool_id">course_navigation</lticm:property>                                              '<<
        #    '<lticm:property name="privacy_level">anonymous</lticm:property>                                                '<<
        #    '<lticm:options name="course_navigation">                                                                       '<<
        #    '<lticm:property name="url">                                                                                    '<<
        #    "#{ mod["items_url"]}                                                                                           "<<
        #    '</lticm:property>                                                                                              '<<
        #    "<lticm:property name='text'>#{mod_xml["link"]}</lticm:property>                                                "<<
        #    '</lticm:options>                                                                                               '<<
        #    '</blti:extensions>                                                                                             '

        #    client.post "/api/v1/courses/#{c_course["id"]}/external_tools",
        #    {
        #        'config_type' => "by_xml",
        #        'config_xml' => xml}

      end
    rescue Canvas::ApiError => error
      puts error
    end
  end

  def create_frontpage(client, c_course, canvas_frontpage)
    puts '#create and set frontpage'
    begin
      canvas_frontpage = canvas_frontpage.gsub '<<course_id>>' , c_course.id.to_s
      syllabus = canvas.put("/api/v1/courses/#{c_course.id}/front_page",
                            {'wiki_page__title__' => 'New Front Page',
                             'wiki_page__body__' => canvas_frontpage,
                             'wiki_page__editing_roles__' => 'teachers',
                             'wiki_page__published__' => true,
                             'wiki_page__front_page__' => true,
                             'wiki_page__hide_from_students__' => false})

      client.put("/api/v1/courses/#{c_course.id}",
                 {
                     'course__default_view__' => 'wiki'
                 }
      )
    rescue Canvas::ApiError => error
      puts error
    end

  end

  def setup_tabs(client, c_course)
    puts "reorder nav tabs and hide some of them"
    begin
      client.put("/api/v1/courses/#{c_course["id"]}/tabs/collaborations", {hidden: true, position: 14})
      client.put("/api/v1/courses/#{c_course["id"]}/tabs/conferences", {hidden: true, position: 13})
      client.put("/api/v1/courses/#{c_course["id"]}/tabs/quizzes", {hidden: true, position: 12})
      client.put("/api/v1/courses/#{c_course["id"]}/tabs/outcomes", {hidden: true, position: 11})
      client.put("/api/v1/courses/#{c_course["id"]}/tabs/syllabus", {hidden: true, position: 10})
      client.put("/api/v1/courses/#{c_course["id"]}/tabs/files", {hidden: true, position: 9})
      client.put("/api/v1/courses/#{c_course["id"]}/tabs/pages", {hidden: true, position: 8})
      client.put("/api/v1/courses/#{c_course["id"]}/tabs/people", {hidden: true, position: 7})
      client.put("/api/v1/courses/#{c_course["id"]}/tabs/grades", {hidden: false, position: 6})
      client.put("/api/v1/courses/#{c_course["id"]}/tabs/assignments", {hidden: false, position: 5})
      client.put("/api/v1/courses/#{c_course["id"]}/tabs/discussions", {hidden: false, position: 4})
      client.put("/api/v1/courses/#{c_course["id"]}/tabs/announcements", {hidden: false, position: 3})
      client.put("/api/v1/courses/#{c_course["id"]}/tabs/modules", {hidden: false, position: 2})
    rescue Canvas::ApiError => error
      puts error
    end
  end

end


class CanvasCourse < Course
  def CanvasCourse.courses_csv(courses, global_options)
    CSV.generate do |csv|
      csv << ["course_id", "short_name", "long_name", "account_id", "term_id", "status", "start_date", "end_date"]
      courses.each do |course_id, course|
        #TODO filter out courses that have aready been created
        #unless course_created?(course_id, global_options)
        unless course.created
          csv << course.to_array(:canvas)
        end
        #end
      end
    end
  end

  def status_check(global_options,client)
    puts "sc-------->Processing course for #{self.long_name} to check it's status"
    puts "sc-------->https://#{global_options[:h]}/api/v1/courses/sis_course_id:#{self.course_id}"

    found = true
    begin
      c_course = client.get_single_course_courses("sis_course_id:#{self.course_id}")
    rescue Footrest::HttpError::NotFound => e

      found = false
      puts "c_account was not found"
      puts "---->#{e}"

    end
    puts found
    #binding.pry
    if found #how to detect that it exists

      if self.created
        puts "sc-------->course was already marked created"
      end
      if self.available && c_course.workflow_state.eql?("available")
        puts "sc-------->course was already marked available"
      end

      if !self.created
        open("http://#{global_options[:p]}/feeds/canvas_created/#{global_options[:k]}/#{self.website_id}/#{c_course.id}") { |f|
          f.each_line { |line| p line }
        }
        puts "sc-------->marking as created"
        self.created = true
      end

      if !self.available && c_course.workflow_state.eql?("available")
        open("http://#{global_options[:p]}/feeds/canvas_available/#{global_options[:k]}/#{self.website_id}") { |f|
          f.each_line { |line| p line }
        }
        puts "sc-------->marking as available"
        self.available = true
      end

      if self.available && !c_course.workflow_state.eql?("available")
        open("http://#{global_options[:p]}/feeds/canvas_unavailable/#{global_options[:k]}/#{self.website_id}") { |f|
          f.each_line { |line| p line }
        }
        puts "sc-------->remarking as unavailable"
        self.available = false
      end


    else #not created yet or has been deleted
      if self.created
        open("http://#{global_options[:p]}/feeds/canvas_deleted/#{global_options[:k]}/#{self.website_id}") { |f|
          f.each_line { |line| p "sc---->#{line}" }
        }
        puts "sc-------->this course was thought created but it was not so marking it as deleted"
        self.created = false
        self.available = false
      end
    end
  end
end


