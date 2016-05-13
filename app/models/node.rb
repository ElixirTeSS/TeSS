class Node < ActiveRecord::Base

  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :user
  has_many :staff, class_name: 'StaffMember'

  # name:string
  # member_status:string
  # country_code:string
  # home_page:string
  # institutions:array
  # twitter:string
  # carousel_images:array

  validates :name, presence: true
  validates :home_page, format: { with: URI.regexp }, if: Proc.new { |a| a.home_page.present? }
  validate :has_training_coordinator

  def self.load_from_hash(hash, verbose: false)
    hash["nodes"].map do |node_data|
      node = Node.find_or_initialize_by(name: node_data["name"])
      puts "#{node.new_record? ? 'Creating' : 'Updating'}: #{node_data["name"]}" if verbose
      staff_data = node_data.delete("staff")
      node.attributes = node_data
      node.user ||= User.get_default_user

      node.staff = []
      staff_data.each do |staff_member_data|
        node.staff.build(staff_member_data)
      end

      if node.save
        puts "Success" if verbose
      elsif verbose
        puts "Failure:"
        node.errors.full_messages.each { |msg|  puts " * #{msg}" }
      end
      puts if verbose

      node
    end
  end

  private

  def has_training_coordinator
    unless staff.training_coordinators.any?
      errors.add(:base, 'Requires at least one training coordinator to be defined')
    end
  end

end
