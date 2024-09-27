class LearningPath < ApplicationRecord
  include PublicActivity::Common
  include LogParameterChanges
  include HasAssociatedNodes
  include HasContentProvider
  include HasLicence
  include Searchable
  include HasFriendlyId
  include HasDifficultyLevel
  include HasSuggestions
  include Collaboratable

  if TeSS::Config.solr_enabled
    # :nocov:
    searchable do
      # full text search fields
      text :title
      text :description
      text :authors
      text :contributors
      text :target_audience
      text :keywords
      text :learning_path_type
      text :content_provider do
        self.content_provider.try(:title)
      end
      # sort title
      string :sort_title do
        title.downcase.gsub(/^(an?|the) /, '')
      end
      # other fields
      string :title
      string :authors, :multiple => true
      string :scientific_topics, :multiple => true do
        self.scientific_topic_names
      end
      string :target_audience, :multiple => true
      string :keywords, :multiple => true
      string :contributors, :multiple => true
      string :content_provider do
        self.content_provider.try(:title)
      end
      string :node, multiple: true do
        self.associated_nodes.pluck(:name)
      end
      boolean :public
      time :updated_at
      time :created_at
      boolean :failing do
        failing?
      end
      string :user do
        user.username if user
      end
      integer :user_id # Used for shadowbans
      integer :collaborator_ids, multiple: true
      string :status do
        MaterialStatusDictionary.instance.lookup_value(self.status, 'title')
      end
    end
    # :nocov:
  end

  belongs_to :user

  has_ontology_terms(:scientific_topics, branch: EDAM.topics)
  # has_ontology_terms(:operations, branch: EDAM.operations)

  has_many :stars,  as: :resource, dependent: :destroy
  has_many :topic_links, -> { order(:order) }, class_name: 'LearningPathTopicLink', dependent: :destroy
  has_many :topics, through: :topic_links, class_name: 'LearningPathTopic'
  has_many :topics_materials, through: :topics, source: :materials, class_name: 'Material'
  auto_strip_attributes :title, :description, squish: false

  after_validation :normalize_order

  validates :title, :description, presence: true

  clean_array_fields(:keywords, :contributors, :authors, :target_audience)
  update_suggestions(:keywords, :contributors, :authors, :target_audience)

  accepts_nested_attributes_for :topic_links, allow_destroy: true

  def description= desc
    super(Rails::Html::FullSanitizer.new.sanitize(desc))
  end

  def archived?
    status == 'archived'
  end

  def self.facet_fields
    field_list = %w(scientific_topics content_provider keywords
                    difficulty_level licence target_audience authors contributors user node status)

    field_list.delete('scientific_topics') if TeSS::Config.feature['disabled'].include? 'topics'
    field_list.delete('node') unless TeSS::Config.feature['nodes']
    field_list.delete('status') if TeSS::Config.feature['disabled'].include? 'status'

    field_list
  end

  def self.visible_by(user)
    if user&.is_admin?
      all
    elsif user
      references(:collaborations).includes(:collaborations).
        where("#{self.table_name}.public = :public OR #{self.table_name}.user_id = :user OR collaborations.user_id = :user",
              public: true, user: user)
    else
      where(public: true)
    end
  end

  private

  # Make sure order for each type goes from 1 to n with no gaps.
  def normalize_order
    i = 0
    topic_links.sort_by(&:order).each do |topic|
      next if topic.marked_for_destruction?
      topic.order = (i += 1)
    end
  end
end
