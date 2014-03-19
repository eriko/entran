class User
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

  def User.users_canvas_csv(users)
    #puts users
    CSV.generate do |csv|
      csv << ["user_id", "login_id", "password", "first_name", "last_name", "email", "status"]
      users.each do |user_id, user|
        csv << user.to_array(:canvas)
      end
    end
  end

  def User.users_limited_canvas_csv(enrollments_canvas)
    #puts users
    CSV.generate do |csv|
      csv << ["user_id", "login_id", "password", "first_name", "last_name", "email", "status"]
      enrollments_canvas.each do |enrollment|
        csv << enrollment.user.to_array(:canvas)
      end
    end
  end

  def User.users_moodle_csv(users)
    #puts users
    CSV.generate do |csv|
      csv << ["user_id", "login_id", "password", "first_name", "last_name", "email", "status"]
      users.each do |user_id, user|
        csv << user.to_array(:moodle)
      end
    end
  end

  def User.import_xml(ims_xml)
    @users = Hash.new
    ims_xml.xpath("//enterprise/person").each do |person|
      user_id = person.xpath("./sourcedid/id").text
      @user = @users[user_id]
      if @user.nil?
        @user = User.new
        @user.user_id = user_id
        @user.last_name = person.xpath("./name/n/family").text
        @user.first_name = person.xpath("./name/n/given").text
        @user.login_id = person.xpath("./userid").text
        @user.email = person.xpath("./email").text
        @users[@user.user_id] = @user
        #puts "created user #{@user} with id of #{@user.user_id} of class #{@user.user_id.class}"
      end
    end
    @users
  end

end
