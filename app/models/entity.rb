# == Schema Information
#
# Table name: entities
#
#  active                :boolean       default(TRUE), not null
#  born_on               :date          
#  category_id           :integer       
#  client                :boolean       not null
#  client_account_id     :integer       
#  code                  :string(16)    
#  comment               :text          
#  company_id            :integer       not null
#  country               :string(2)     
#  created_at            :datetime      not null
#  creator_id            :integer       
#  dead_on               :date          
#  deliveries_conditions :string(60)    
#  discount_rate         :decimal(8, 2) 
#  ean13                 :string(13)    
#  employee_id           :integer       
#  excise                :string(15)    
#  first_met_on          :date          
#  first_name            :string(255)   
#  full_name             :string(255)   not null
#  id                    :integer       not null, primary key
#  invoices_count        :integer       
#  language_id           :integer       not null
#  lock_version          :integer       default(0), not null
#  name                  :string(255)   not null
#  nature_id             :integer       not null
#  origin                :string(255)   
#  payment_delay_id      :integer       
#  payment_mode_id       :integer       
#  payments_number       :integer       
#  proposer_id           :integer       
#  reduction_rate        :decimal(8, 2) 
#  reflation_submissive  :boolean       not null
#  siren                 :string(9)     
#  soundex               :string(4)     
#  supplier              :boolean       not null
#  supplier_account_id   :integer       
#  updated_at            :datetime      not null
#  updater_id            :integer       
#  vat_number            :string(15)    
#  vat_submissive        :boolean       default(TRUE), not null
#  website               :string(255)   
#

class Entity < ActiveRecord::Base
  belongs_to :client_account, :class_name=>Account.to_s
  belongs_to :category, :class_name=>EntityCategory.to_s
  belongs_to :company
  belongs_to :employee
  belongs_to :language
  belongs_to :nature, :class_name=>EntityNature.to_s
  #belongs_to :origin, :class_name=>MeetingLocation.to_s
  belongs_to :payment_delay, :class_name=>Delay.to_s
  belongs_to :payment_mode
  belongs_to :proposer, :class_name=>Entity.to_s
  belongs_to :supplier_account, :class_name=>Account.to_s
  has_many :bank_accounts
  has_many :complement_data
  has_many :contacts, :conditions=>{:active=>true}
  has_many :direct_links, :class_name=>EntityLink.name, :foreign_key=>:entity1_id
  has_many :indirect_links, :class_name=>EntityLink.name, :foreign_key=>:entity2_id
  has_many :invoices, :foreign_key=>:client_id
  has_many :mandates
  has_many :meetings
  has_many :observations
  has_many :payments
  has_many :usable_payments, :conditions=>["parts_amount<amount"], :class_name=>Payment.name
  has_many :prices
  has_many :purchase_orders, :foreign_key=>:supplier_id
  has_many :sale_orders, :foreign_key=>:client_id
  
 # validates_presence_of :category_id, :if=>Proc.new{|u| u.client}
  attr_readonly :company_id
  
  before_destroy :destroy_bank_account
 
  #has_many :contact
  def before_validation
    self.soundex = self.name.soundex2 if !self.name.nil?
    self.first_name = self.first_name.to_s.strip
    self.name = self.name.to_s.strip
    unless self.nature.nil?
      self.first_name = '' unless self.nature.physical
    end
    self.full_name = (self.name.to_s+" "+self.first_name.to_s).strip
    
    #if self.client
    #  self.client_account_id
    
    self.code = self.full_name.codeize if self.code.blank?
    self.code = self.code[0..15]
    #raise Exception.new self.inspect
    #    while Entity.find(:first, :conditions=>["company_id=? AND code=? AND id!=?",self.company_id, self.code, self.id||0])
    #      self.code.succ!
    #    end

    #self.active = false  unless self.dead_on.blank?
    
   # raise Exception.new('acc:'+self.inspect)
  end


  def after_validation_on_create
    if not self.company.parameter("relations.entities.numeration").nil?
      specific_numeration = self.company.parameter("relations.entities.numeration").value
      if not specific_numeration.nil?
        self.code = specific_numeration.next_value
      end
    end
  end
  
  

  #
  def validate
    if self.nature
      #raise Exception.new self.nature.in_name.inspect
      if self.nature.in_name
        errors.add(:name, tc(:error_missing_title,:title=>self.nature.abbreviation)) unless self.name.match(/( |^)#{self.nature.abbreviation}( |$)/i)
      end
    end
  end
  


  #
  def destroy_bank_account
    self.bank_accounts.find(:all).each do |bank_account|
      BankAccount.destroy bank_account
    end
  end

  def label
    self.code+'. '+self.full_name
  end

  #
  def created_on
    self.created_at.to_date
  end

  #
  def last_invoice
    self.invoices.find(:first, :order=>"created_at DESC")
  end
  
  #
  def balance
    #payments = Payment.find_all_by_entity_id_and_company_id(self.id, self.company_id).sum(:amount_with_taxes)
    payments = Payment.sum(:amount, :conditions=>{:company_id=>self.company_id, :entity_id=>self.id})
    invoices = Invoice.sum(:amount_with_taxes, :conditions=>{:company_id=>self.company_id, :client_id=>self.id})
    #invoices = Invoice.find_all_by_client_id_and_company_id(self.id, self.company_id).sum(:amount_with_taxes)
    #raise Exception.new.to_i.inspect
    payments - invoices
  end

  def default_contact
    if self.contacts.size>0
      self.contacts.find_by_default(true)
    else
      nil
    end
  end

  
  # this method creates automatically an account for the entity
  def create_update_account(nature = :client, suffix = nil)
    prefix = nature == :client ? 411 : 401
    suffix ||= self.code
    suffix = suffix.upper_ascii[0..5].rjust(6,'0')
    account = 1
    
    while not account.nil? do
      number = prefix
      account = self.company.accounts.find(:first, :conditions => ["number LIKE ?", prefix.to_s+suffix.to_s])
      suffix.succ! unless account.nil?
    end
    
    self.company.accounts.create({:number => prefix.to_s+suffix.to_s, :name=>self.full_name})
  end

  def find_or_create_account(nature = :client)
    prefix = nature == :client ? 411 : 401
    #raise Exception.new self.inspect+prefix.inspect+self.nature.inspect
    if self.client and self.client_account_id.nil?
      
      #last = self.company.accounts.find(:first, :conditions=>["number like ?",'%411'],:order=>"number desc")
      #account = self.company.create!(:number=>last.number.succ, :name=>self.full_name).id
      #raise Exception.new self.inspect
      account = self.create_update_account(:client).id
      self.client_account_id = account
      self.save
    else
      account = self.client_account_id
    end
    account
  end

  def warning
    count = self.observations.find_all_by_importance("important").size
    #count += self.balance<0 ? 1 : 0
  end

end 
