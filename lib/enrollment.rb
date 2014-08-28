class Enrollment
  attr_accessor :user, :role_id, :section, :status

  @@roles = {student: "Student", faculty: "Teacher"}

  def initialize(user, role_id, section, status)
    @user = user
    @role_id = role_id
    @section = section
    @status = status
  end

  def to_s
    "user #{user} role #{@role_id} course #{@course.course_id}"
  end

  def match(user, section)
    @user == user &&  @section == section
  end

  def to_array(kind)
    case kind
      when :canvas
        [@section.course_id, @user.user_id, @@roles[role_id], @section.section_id, status, nil]
      when :moodle
        [@course_id, @user.user_id, @@roles[role_id], nil, 'active', nil]
    end
  end

  def Enrollment.enrollments_canvas_csv(enrollments)
    CSV.generate do |csv|
      csv << ["course_id", "user_id", "role", "section_id", "status", "associated_user_id"]
      enrollments.each do |enrol|
        csv << enrol.to_array(:canvas)
      end
    end
  end

  def Enrollment.enrollments_moodle_csv(enrollments)
    CSV.generate do |csv|
      csv << ["course_id", "user_id", "role", "section_id", "status", "associated_user_id"]
      enrollments.each do |enrol|
        csv << enrol.to_array(:moodle)
      end
    end
  end

  def Enrollment.import_xml(course, enrollments, users, ims_key, banner_host)
    offering_id = course.banner_offering_id
    enrollment_term = course.enrollment_term
    #puts course.sections
    #puts "course offeringcodes are------->#{course.offering_codes}"
    #puts "finding faculty section"
    faculty_section = course.sections["#{offering_id}-faculty"]
    #puts "faculty section ---> #{faculty_section}"
    #puts "finding student section for #{enrollment_term} term "
    student_section = course.sections["#{offering_id}-#{enrollment_term}"]
    #puts "student_section ---> #{student_section}"
    #puts "finding student crosslist section for #{enrollment_term} term "
    crosslist_section = course.sections["#{offering_id}-#{enrollment_term}-cl"]
    student_sections = [ student_section , crosslist_section]
    student_sections << course.sections["#{offering_id}-#{enrollment_term}-media-cl"]
    student_sections <<  course.sections["#{offering_id}-#{enrollment_term}-science-cl"]
    student_sections.compact!
    #puts "crosslist_section ---> #{crosslist_section}"
    if course.offering_codes.empty?
      puts "ene--------------->No offering codes so using presence data"
      course.faculty.each do |faculty|
        enrol = Enrollment.new(faculty, :faculty, faculty_section, 'active')
        enrollments << enrol
        course.enrollments << enrol
      end
    end
    course.offering_codes.each do |code|
      url = "http://#{banner_host}/banner/public/oars/offering/export/offering.xml?offering_code=#{code}&term_code=#{enrollment_term}&key=#{ims_key}"
      #puts url
      enrollment_xml = Nokogiri::XML(open(url, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))
      #puts "enrollment_xml for #{course.long_name} is -------->#{enrollment_xml}"
      # start a REPL session
      #see if the course is built in banned by looking for an empty document
      #if the doc is empty except for the XML declaration use the data from
      #presence and the presence feed to enroll the facutly
      if enrollment_xml.to_s.eql? "<?xml version=\"1.0\"?>\n<offering/>\n"
        puts "ene--------------->no data from banner so using presence"
        course.faculty.each do |faculty|
          enrol = Enrollment.new(faculty, :faculty, faculty_section, 'active')
          enrollments << enrol
          course.enrollments << enrol
        end
      else
        enrollment_xml.xpath("./offering/faculty/person").each do |person|
          user, users = User.import_user_xml(person, users)
          if user
            enrol = Enrollment.new(user, :faculty, faculty_section, 'active')
            enrollments << enrol
            course.enrollments << enrol
          end
        end
        enrollment_xml.xpath("./offering/registered/person").each do |person|
          user, users = User.import_user_xml(person, users)
          student_sections.each do |section|
            enrol = Enrollment.new(user, :student, section, 'active')
            enrollments << enrol
            course.enrollments << enrol
          end
        end
        #only do this when waitlist is active
        if course.waitlist
          enrollment_xml.xpath("./offering/waitlisted/person").each do |person|
            user, users = User.import_user_xml(person, users)
            student_sections.each do |section|
              enrol = Enrollment.new(user, :student, section, 'active')
              enrollments << enrol
              course.enrollments << enrol
            end
          end
        end
        #only do this when waitlist is active
        if course.override
          enrollment_xml.xpath("./offering/overrides/person").each do |person|
            user, users = User.import_user_xml(person, users)
            student_sections.each do |section|
              enrol = Enrollment.new(user, :student, section, 'active')
              enrollments << enrol
              course.enrollments << enrol
            end
          end
        end
      end
    end
    enrollments
  end

end