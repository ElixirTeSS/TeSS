class ScientificTopic < ActiveRecord::Base; end

class ConvertEventFieldToScientificTopics < ActiveRecord::Migration[4.2]

  IANN_MAPPING = {
      'Systemsbiology' => 'http://edamontology.org/topic_2259',
      'Systems Biology' => 'http://edamontology.org/topic_2259',
      'Genomics' => 'http://edamontology.org/topic_0622',
      'Bioinformatics' => 'http://edamontology.org/topic_0091',
      'Computationalbiology' => 'http://edamontology.org/topic_3307',
      'Metagenomics' => 'http://edamontology.org/topic_3174',
      'Computerscience' => 'http://edamontology.org/topic_3316',
      'Proteomics' => 'http://edamontology.org/topic_0121',
      'Dataanalysis' => 'http://edamontology.org/topic_3365',
      'RNA-Seq' => 'http://edamontology.org/topic_3170',
      'Immunology' => 'http://edamontology.org/topic_0804',
      'Medicine' => 'http://edamontology.org/topic_3303',
      'Datavisualisation' => 'http://edamontology.org/topic_0092',
      'Medicalimaging' => 'http://edamontology.org/topic_3384',
      'Geneexpression' => 'http://edamontology.org/topic_0203',
      'Geneexpressionandmicroarray' => 'http://edamontology.org/topic_0203',
      'High-throughputsequencing' => 'http://edamontology.org/topic_3168',
      'Pharmacology' => 'http://edamontology.org/topic_0202',
      'Biology' => 'http://edamontology.org/topic_3070',
      'Pathology' => 'http://edamontology.org/topic_0634',
      'Medicalinformatics' => 'http://edamontology.org/topic_3063',
      'ChIP-seq' => 'http://edamontology.org/topic_3169',
      'Computationalchemistry' => 'http://edamontology.org/topic_3332',
      'Computerprogramming' => 'http://edamontology.org/topic_3372',
      'Biomedicalscience' => 'http://edamontology.org/topic_3344',
      'Datamanagement' => 'http://edamontology.org/topic_3071',
      'Datadeposition' => 'http://edamontology.org/topic_0219',
      'annotationandcuration' => 'http://edamontology.org/topic_0219',
      'Moleculardynamics' => 'http://edamontology.org/topic_0176',
      'Molecularmodelling' => 'http://edamontology.org/topic_2275',
      'Biochemistry' => 'http://edamontology.org/topic_3292',
      'DNAmethylation' => 'http://edamontology.org/topic_3295',
      'Epigenetics' => 'http://edamontology.org/topic_3295',
      'Datasearch' => 'http://edamontology.org/topic_3071',
      'queryandretrieval' => 'http://edamontology.org/topic_3071',
      'Tooltopic' => 'http://edamontology.org/topic_3071',
      'Metabolomics' => 'http://edamontology.org/topic_3172',
      'Datamining' => 'http://edamontology.org/topic_3473',
      'Microbiology' => 'http://edamontology.org/topic_3301',
      'Ecology' => 'http://edamontology.org/topic_0610',
      'Evolutionarybiology' => 'http://edamontology.org/topic_3299',
      'Theoreticalbiology' => 'http://edamontology.org/topic_3307',
      'Epigenomics' => 'http://edamontology.org/topic_3173',
      'Transcriptomics' => 'http://edamontology.org/topic_3308',
      'Physiology' => 'http://edamontology.org/topic_3300',
      'Anaesthesiology' => 'http://edamontology.org/topic_3402',
      'Humans' => 'http://edamontology.org/topic_2815',
      'Biotherapeutics' => 'http://edamontology.org/topic_3374',
      'Biostatistics' => 'http://edamontology.org/topic_2269',
      'Epidemiology' => 'http://edamontology.org/topic_3305',
      'ResearchPathology' => 'http://edamontology.org/topic_3379',
      'Clinical Studies' => 'http://edamontology.org/topic_3379',
      'Pharmacodynamics' => 'http://edamontology.org/topic_3375',
      'Behavioral' => 'http://edamontology.org/topic_3070'
  }

  def up
    # Find ScientificTopics from the URIs
    topic_mapping = IANN_MAPPING.dup
    topic_mapping.each do |key, value|
      topic = EDAM::Ontology.instance.lookup(value)
      puts "Couldn't find ScientificTopic for class ID: #{value}" if topic.nil?
      topic_mapping[key] = topic
    end

    # De-serialize data and copy into new columns
    puts 'Converting event "fields" to scientific topics'
    fields_without_topic = {}
    Event.transaction do
      Event.all.each do |e|
        # Fetch the matching topics
        topics = e.field.map do |field|
          topic = topic_mapping[field]

          if topic.nil?
            fields_without_topic[field] ||= []
            fields_without_topic[field] << e
          end

          topic
        end

        # Link them to the event (discarding any nils)
        e.scientific_topics = topics.uniq.compact
        print '.'
      end
    end

    if fields_without_topic.any?
      puts
      puts "WARNING - Please take note of this, you won't see this error again!"
      puts "Couldn't find scientific topics for the following fields:"
      fields_without_topic.each do |field, events|
        puts "  Field: #{field}"
        puts "  Event IDs: #{events.map(&:id).inspect}"
        puts
      end
    end

    # Delete old column
    remove_column :events, :field
  end

  def down
    add_column :events, :field, :string, array: true, default: []
  end

end
