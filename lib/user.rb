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

 def User.import_user_xml(person_xml,users)
   #puts "person_xml--------> #{person_xml}"
   #binding.pry
   @users = users
     user_id = person_xml.attribute("id").text
     @user = @users[user_id]
     if @user.nil?
       @user = User.new
       @user.user_id = user_id
       @user.last_name = person_xml.attribute("last").text
       @user.first_name = person_xml.attribute("first").text
       @user.login_id = person_xml.attribute("username").text
       @user.email = "#{person_xml.attribute("username").text}@evergreen.edu"
       @users[@user.user_id] = @user
       #puts "created user #{@user} with id of #{@user.user_id} of class #{@user.user_id.class}"
     end
   [@user,@users]
 end



end
