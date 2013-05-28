class Enrollment
  attr_accessor :user ,:role_id ,:course_id

  @@roles = {1 => "Student" , 2 => "Teacher"}

  def initialize(user,role_id,course_id)
    @user = user
    @role_id = role_id
    @course_id = course_id
  end

  def to_s
    "user #{user} role #{@role_id} course #{@course_id}"
  end

  def to_array(kind)
    case  kind
      when :canvas
        [@course_id,@user.user_id,@@roles[role_id],nil,'active',nil]
      when :moodle
        [@course_id,@user.user_id,@@roles[role_id],nil,'active',nil]
    end
  end

  def Enrollment.enrollments_canvas_csv(enrollements)
    CSV.generate do |csv|
      csv << ["course_id", "user_id", "role", "section_id", "status", "associated_user_id"]
      enrollements.each do |enrol|
        csv << enrol.to_array(:canvas)
      end
    end
  end
  def Enrollment.enrollments_moodle_csv(enrollements)
    CSV.generate do |csv|
      csv << ["course_id", "user_id", "role", "section_id", "status", "associated_user_id"]
      enrollements.each do |enrol|
        csv << enrol.to_array(:moodle)
      end
    end
  end

  def Enrollment.import_xml(course,ims_xml, enrollments ,users)

    ims_xml.xpath("//membership/sourcedid/id[text()='#{course.course_id}']/../../member").each do |member|
      #puts "the member xml is -------> #{member}"
      user_id = member.xpath("./sourcedid/id[text()]").text
      role_id = member.xpath("./role/@roletype").text.to_i
      @user = users[user_id]
      if @user.nil?
        puts "user was nil"
      end
      #TODO  catch error of user in course enrollment but not in the list of users
      enrol = Enrollment.new(@user, role_id, course.course_id)
      enrollments << enrol
    end
    enrollments
  end

end