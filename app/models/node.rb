class Node < ActiveRecord::Base

  include PublicActivity::Common
  has_paper_trail

  FACET_FIELDS = %w(name)

  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :user

  has_many :staff, class_name: 'StaffMember', dependent: :destroy

  accepts_nested_attributes_for :staff, allow_destroy: true

  unless SOLR_ENABLED==false
    searchable do
      string :name
      text :name
      string :country_code
      text :staff do
        staff.map(&:name)
      end

      time :updated_at
    end
  end

  validates :name, presence: true, uniqueness: true
  validates :home_page, format: { with: URI.regexp }, if: Proc.new { |a| a.home_page.present? }
  # validate :has_training_coordinator

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
    unless staff.select { |s| s.role == StaffMember::TRAINING_COORDINATOR_ROLE }.any?
      errors.add(:base, 'Requires at least one training coordinator to be defined')
    end
  end

end
