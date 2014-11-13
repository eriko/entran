class Person
  require 'securerandom'
  attr_accessor :user_id, :first_name, :last_name, :login_id, :email


  def to_s
    "anumber #{user_id} username #{login_id} lastname #{last_name} firstname #{first_name} email #{email}"
  end

  def to_array(kind)
    case kind
      when :canvas
        [user_id, login_id, SecureRandom.hex(25), first_name, last_name, "#{login_id}@evergreen.edu".downcase, 'active']
      when :moodle
        [user_id, login_id, SecureRandom.hex(25), first_name, last_name, email.downcase, 'active']
    end
  end

  def Person.users_canvas_csv(users)
    #puts users
    CSV.generate do |csv|
      csv << ["user_id", "login_id", "password", "first_name", "last_name", "email", "status"]
      users.each do |user_id, user|
        csv << user.to_array(:canvas)
      end
    end
  end

  def Person.users_limited_canvas_csv(enrollments_canvas)
    #puts users
    CSV.generate do |csv|
      csv << ["user_id", "login_id", "password", "first_name", "last_name", "email", "status"]
      enrollments_canvas.each do |enrollment|
        csv << enrollment.user.to_array(:canvas)
      end
    end
  end

  def Person.users_moodle_csv(users)
    #puts users
    CSV.generate do |csv|
      csv << ["user_id", "login_id", "password", "first_name", "last_name", "email", "status"]
      users.each do |user_id, user|
        csv << user.to_array(:moodle)
      end
    end
  end

  def Person.import_faculty_xml(person_xml, users)
    #puts "person_xml--------> #{person_xml}"
    begin
      #binding.pry
      @users = users
      user_id = person_xml.attribute("id").text
      @user = @users[user_id]
      if @user.nil?
        @user = Person.new
        @user.user_id = user_id
        @user.last_name = person_xml.attribute("display_name").text.split(',')[1].strip
        @user.first_name = person_xml.attribute("display_name").text.split(',')[0].strip
        @user.login_id = person_xml.attribute("user_name").text
        @user.email = "#{person_xml.attribute("user_name").text}@evergreen.edu"
        @users[@user.user_id] = @user
      end
    rescue NoMethodError
      puts "person_xml lacks some value--------> #{person_xml}"
    end
    @users
  end

  def Person.import_user_xml(person_xml, users)
    #puts "person_xml--------> #{person_xml}"
    #binding.pry
    @users = users
    user_id = person_xml.attribute("id").text
    @user = @users[user_id]
    if @user.nil? && person_xml.at("@username") #some faculty enter the system before they have accounts.  Do not try to process them
      @user = Person.new
      @user.user_id = user_id
      @user.last_name = person_xml.attribute("last").text
      @user.first_name = person_xml.attribute("first").text
      @user.login_id = person_xml.attribute("username").text
      @user.email = "#{person_xml.attribute("username").text}@evergreen.edu"
      @users[@user.user_id] = @user
    end
    [@user, @users]
  end

  def Person.import_students_xml(offering_xml, users, ims_key, banner_host)
    url = "http://#{banner_host}/banner/public/oars/offering/export/offering.xml?offering_code=#{offering_xml.attribute("code")}&term_code=#{offering_xml.attribute("enrollment_term")}&key=#{ims_key}"
    #puts url
    enrollment_xml = Nokogiri::XML(open(url, :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE))

    unless enrollment_xml.to_s.eql? "<?xml version=\"1.0\"?>\n<offering/>\n"
      #if there is not data in the file do not do anything
      #if there is data only do the students
      enrollment_xml.xpath("./offering/registered/person").each do |person|
        user, users = Person.import_user_xml(person, users)
      end
      enrollment_xml.xpath("./offering/waitlisted/person").each do |person|
        user, users = Person.import_user_xml(person, users)
      end

      enrollment_xml.xpath("./offering/overrides/person").each do |person|
        user, users = Person.import_user_xml(person, users)
      end
    end
    users
  end


end