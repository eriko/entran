class Account
  attr_accessor :account_id, :name, :id
  parent_account_id = nil
  status = 'active'

  def initialize(account_id, name)
    @account_id = account_id
    @name = name
  end

  def Account.import_xml(lms_courses_xml, canvas,client)
    #The courses to be used are from presence where the course site has beeen marked requested.
    #Then data from other data sources like the ims.xml feed will be used to gather the full set of data
    #based on the list from presence
    @accounts = Hash.new
    lms_courses_xml.xpath("//account").each do |section_xml|
      account = Account.new section_xml.xpath("./@account_id").text, section_xml.xpath("./@name").text
      @accounts[account.account_id] = account
      begin
        c_account = client.list_accounts(id: "sis_account_id:#{account.account_id}")
        #c_account = canvas.get("/api/v1/accounts/sis_account_id:#{account.account_id}")
        binding.pry
        account.id = c_account[0].id
        #account.id = c_account['id']
        puts "that account id for #{account.account_id} is #{account.id}"
      rescue => error

      end
    end
    binding.pry
    @accounts
  end

  def Account.accounts_canvas_csv(accounts)
    CSV.generate do |csv|
      csv << ['account_id', 'parent_account_id', 'name', 'status']
      accounts.each do |key, account|
        csv << account.to_array(:canvas)
      end
    end
  end

  def to_array(kind)
    case kind
      when :canvas
        [account_id, '', name, "active"]
      when :moodle
        [section_id, course_id, name, "active", start_date, end_date]
    end
  end


end