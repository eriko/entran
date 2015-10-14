class Enrollment
  attr_accessor :user, :role_id, :section, :status

  @@roles = {canvas: {student: "Student", faculty: "Teacher"} , wordpress:{student: "Student", faculty: "Faculty"}}

  def initialize(user, role_id, section, status)
    @user = user
    @role_id = role_id
    @section = section
    @status = status
  end

  def to_s
    "user #{user} role #{@role_id} course #{@section}"
  end

  def ==(o)
    o.class == self.class && o.state == state
  end

  alias_method :eql?, :==

  def hash
    state.hash
  end

  def match(user, section)
    @user == user && @section == section
  end

  def to_array(kind)
    case kind
      when :canvas
        [@section.course_id, @user.user_id, @@roles[:canvas][role_id], @section.section_id, status]
      when :wordpress
        [@course_id, @user.user_id, @@roles[:wordpress][role_id], nil, 'active', nil]
    end
  end

  def Enrollment.enrollments_canvas_csv(enrollments)
    CSV.generate do |csv|
      csv << ["course_id", "user_id", "role", "section_id", "status"]
      enrollments.each do |enrol|
        csv << enrol.to_array(:canvas)
      end
    end
  end

  def Enrollment.enrollments_wordpress_csv(enrollments)
    CSV.generate do |csv|
      csv << ["course_id", "user_id", "role", "section_id", "status", "associated_user_id"]
      enrollments.each do |enrol|
        csv << enrol.to_array(:wordpress)
      end
    end
  end

  def Enrollment.import_xml(course, enrollments, users, ims_key, banner_host)
    course.enrollment_count = 0
    #offering_id = course.banner_offering_id
    enrollment_term = course.enrollment_term
    #course.sections.values.each { |section|#puts section.section_id }
    #puts "course offeringcodes are------->#{course.offering_codes.collect { |code| code }.join(', ')}"
    #puts "finding faculty section"
    #puts "#{course.kind} #{course.long_name} "
    #puts course.sections
    faculty_section = course.sections.detect { |k, v| k.end_with? '-faculty' }[1]
    #puts "faculty_section #{faculty_section}"
    #only proccess the student sections that are fully under our control
    student_sections = course.sections.values.find_all { |v| (v.control.eql?('full') && v.current) && !(['joint', 'crosslist'].include? v.kind) }
    student_sections.compact!
    #puts "student_sections #{student_sections}"
    #puts course.kind
    if ["Joint", "Crosslist"].include?(course.kind)
      joint_sections = course.sections.values.find_all { |v| (['joint', 'crosslist'].include?(v.kind) && v.current) }
      joint_sections.compact!
    end
    #puts "joint_sections ---> #{joint_sections}"
    #joint_sections.each do |section|
    #  puts section.offering_codes
    #  puts "section offeringcodes are------->#{section.offering_codes.collect { |code| code }.join(', ')}" if section.offering_codes
    #end if joint_sections
    if course.offering_codes.empty?
      #puts "ene--------------->No offering codes so using presence data"
      course.faculty.each do |faculty|
        enrol = Enrollment.new(faculty, :faculty, faculty_section, 'active')
        enrollments << enrol
        course.enrollments << enrol
      end if course.faculty
    end
    course.offering_codes.each do |code|
      student_sections.each do |section|
        url = "https://#{banner_host}/banner/public/oars/offering/export/offering.xml?offering_code=#{code}&term_code=#{section.term_code}&key=#{ims_key}"
        #puts url
        enrollment_xml = Nokogiri::XML(open(url, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))
        if enrollment_xml.to_s.eql? "<?xml version=\"1.0\"?>\n<offering/>\n"
          #puts "ene--------------->no data from banner so using presence"
          course.faculty.each do |faculty|
            enrol = Enrollment.new(faculty, :faculty, faculty_section, 'active')
            enrollments << enrol
            course.enrollment_count = course.enrollment_count += 1
            #puts "possible faculty enrollment adding: #{enrol}"
          end
        else
          enrollment_xml.xpath("./offering/faculty/person").each do |person|
            user, users = Person.import_user_xml(person, users)
            if user
              enrol = Enrollment.new(user, :faculty, faculty_section, 'active')
              enrollments << enrol
              course.enrollment_count = course.enrollment_count += 1
            end
          end
          enrollment_xml.xpath("./offering/registered/person").each do |person|
            user, users = Person.import_user_xml(person, users)
            enrol = Enrollment.new(user, :student, section, 'active')
            enrollments << enrol
            course.enrollment_count = course.enrollment_count += 1
          end
          #only do this when waitlist is active
          if course.waitlist
            enrollment_xml.xpath("./offering/waitlisted/person").each do |person|
              user, users = Person.import_user_xml(person, users)
              enrol = Enrollment.new(user, :student, section, 'active')
              enrollments << enrol
              course.enrollment_count = course.enrollment_count += 1
            end
          end
          #only do this when waitlist is active
          if course.override
            enrollment_xml.xpath("./offering/overrides/person").each do |person|
              user, users = Person.import_user_xml(person, users)
              enrol = Enrollment.new(user, :student, section, 'active')
              enrollments << enrol
              course.enrollment_count = course.enrollment_count += 1
            end
          end
        end
      end
    end


    if joint_sections
      #puts "ene----------> Joint sections count #{joint_sections.count}"
      joint_sections.each do |section|
        #puts "ene------section #{section.section_id}"
        #puts "ene------section.offering_codes #{section.offering_codes}"
        section.offering_codes.each do |code|
          #puts "ene------offering_code #{code}"
          term =/(\d*)(.*)/.match(code)[1]
          url = "https://#{banner_host}/banner/public/oars/offering/export/offering.xml?offering_code=#{code}&term_code=#{term}&key=#{ims_key}"
          #puts "Joint #{url}"
          enrollment_xml = Nokogiri::XML(open(url, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))
          unless enrollment_xml.to_s.eql? "<?xml version=\"1.0\"?>\n<offering/>\n"
            enrollment_xml.xpath("./offering/registered/person").each do |person|
              #puts "ene------>person to enroll #{person}"
              user, users = Person.import_user_xml(person, users)
              enrol = Enrollment.new(user, :student, section, 'active')
              enrollments << enrol
              course.enrollment_count = course.enrollment_count += 1
              #puts "joint student enrollment adding: #{enrol}"
            end
            #only do this when waitlist is active
            if course.waitlist
              enrollment_xml.xpath("./offering/waitlisted/person").each do |person|
                user, users = Person.import_user_xml(person, users)
                enrol = Enrollment.new(user, :student, section, 'active')
                enrollments << enrol
                course.enrollment_count = course.enrollment_count += 1
              end
            end
            #only do this when waitlist is active
            if course.override
              enrollment_xml.xpath("./offering/overrides/person").each do |person|
                user, users = Person.import_user_xml(person, users)
                enrol = Enrollment.new(user, :student, section, 'active')
                enrollments << enrol
                course.enrollment_count = course.enrollment_count += 1
              end
            end
          end
        end if section.offering_codes
      end
    end
    enrollments
  end


  protected

  def state
    [@user, @role_id, @section, @status]
  end

end