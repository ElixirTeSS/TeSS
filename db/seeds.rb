# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Role.roles.each do |role|
  Role.find_or_create_by({name: role})
end


models = %w(Material Workflow Package ContentProvider User)
models.each do |model|
  model.constantize.delete_all
end

Material.delete_all
Workflow.delete_all
#Probably don't need to delete existing users.
#User.delete_all 

User.create!(
        username: 'test',
        email: 'test@test.com',
        password: 'test1234',
        password_confirmation: 'test1234',
        confirmed_at: Time.now
)

ScientificTopic.delete_all

edam_topics = YAML.load(File.open('config/dictionaries/edam.yml'))
edam_topics.each do |edam_topic|
  st = ScientificTopic.new(
      :class_id => edam_topic['class_id'],
      :preferred_label => edam_topic['preferred_label'],
      :synonyms => (edam_topic['synonyms'].split('|') unless edam_topic['synonyms'].nil?),
      :definitions  => (edam_topic['definitions'].split('|') unless edam_topic['definitions'].nil?),
      :obsolete => edam_topic['obsolete'],
      :parents => (edam_topic['parents'].split('|') unless edam_topic['parents'].nil?),
      :created_in => edam_topic['created_in'],
      :documentation => edam_topic['documentation'],
      :prefix_iri => edam_topic['prefixIRI'],
      :consider => (edam_topic['consider'].split('|') unless edam_topic['consider'].nil?),
      :has_alternative_id => (edam_topic['hasAlternativeId'].split('|') unless edam_topic['hasAlternativeId'].nil?),
      :has_broad_synonym => (edam_topic['hasBroadSynonym'].split('|') unless edam_topic['hasBroadSynonym'].nil?),
      :has_narrow_synonym => (edam_topic['hasNarrowSynonym'].split('|') unless edam_topic['hasNarrowSynonym'].nil?),
      :has_dbxref => (edam_topic['hasDbXref'].split('|') unless edam_topic['hasDbXref'].nil?),
      :has_definition => edam_topic['hasDefinition'],
      :has_exact_synonym => (edam_topic['hasExactSynonym'].split('|') unless edam_topic['hasExactSynonym'].nil?),
      :has_related_synonym => (edam_topic['hasRelatedSynonym'].split('|') unless edam_topic['hasRelatedSynonym'].nil?),
      :has_subset => (edam_topic['hasSubset'].split('|') unless edam_topic['hasSubset'].nil?),
      :in_subset  => (edam_topic['inSubset'].split('|') unless edam_topic['inSubset'].nil?),
      :replaced_by => (edam_topic['replacedBy'].split('|') unless edam_topic['replacedBy'].nil?),
      :saved_by => edam_topic['savedBy'],
      :subset_property => (edam_topic['SubsetProperty'].split('|') unless edam_topic['SubsetProperty'].nil?),
      :obsolete_since => edam_topic['obsolete_since'],
      :in_cyclic => (edam_topic['inCyclic'].split('|') unless edam_topic['inCyclic'].nil?),
  )
  st.save!
end

Material.create!(
    title: 'Metabolomics: Understanding Metabolism in the 21st Century',
    short_description: 'Discover how metabolomics is revolutionising our understanding of metabolism with this free online course.',
    url: 'https://www.futurelearn.com/courses/metabolomics',
    long_description: "Discover how metabolomics is revolutionising our understanding of metabolism with this free online course.
Metabolomics is an emerging field that aims to measure the complement of metabolites (the intermediates and products of metabolism) in living organisms. The complement of metabolites in a biological system is known as the metabolome and represents the downstream effect of an organism’s genome and its interaction with the environment. Metabolomics has a wide application area across the medical and biological sciences and is attractive to both new and established scientists. In this course we will provide an introduction to metabolomics, explain why we want to study the metabolome and describe the current challenges in analysing the complement of metabolites in a biological system. We will describe the interdisciplinary approaches adopted in the metabolomics workflow and demonstrate how the combined efforts of scientist’s from different disciplines is advancing this exciting field. By the end of the course the learner will understand how metabolomics can revolutionise our understanding of metabolism.
The course will be targeted towards final year undergraduate students from biology / chemical disciplines and medical students, but will also provide a valuable introduction to the metabolomics field for MSc and PhD students, and scientists at any stage in their careers. Metabolomics is a new tool to the scientific community and has widespread applications across the medical and biological sciences in academia and industry.",
    doi: 'doi:14.1502/06780841559.ab1',
    scientific_topic: [ScientificTopic.find_by_preferred_label('Biophysics')],
    target_audience: ['Bioinformaticians'],
    keywords: ['Galaxy', 'unix', 'Taverna'],
    licence: "Apache-2.0",
    difficulty_level: "Beginner",
    authors: ['Tom', 'Jerry'],
    contributors: ['Peppa Pig', 'George Pig'],
    remote_created_date: Date.today - 256,
    remote_updated_date: Date.today - 48)

Material.create!(
    title: 'Browsing plant and pathogen genomes with Ensembl Genomes',
    short_description: 'Complete course materials from the 2014 GBS course ran by Bert Overduin at TGAC.',
    url: 'https://documentation.tgac.ac.uk/download/attachments/9076929/Plants%20and%20Pathogens%20ENSEMBL.rar?version=1&modificationDate=1439825372000&api=v2',
    long_description: "The Ensembl genome annotation system, developed jointly by the EBI and the Wellcome Trust Sanger Institute, has been used for the annotation, analysis, and display of vertebrate genomes since 2000.  Since 2009, the Ensembl site has been complemented by the creation of five new sites for bacteria, protists, fungi, plants and invertebrate metazoa, enabling users to access a single collection of interactive interfaces for accessing and comparing genome-scale data from species of scientific interest across taxonomy.
This one-day, hands-on course will explore the EBI's Ensembl Genomes Browser at www.ensemblgenomes.org in order to explore genes, sequence variation, and other data for plants and pathogens. New users and those who wish to deepen their understanding of the data and navigation behind the Ensembl Genomes Browser are welcome.",
    doi: 'doi:34.1502/06435841559.ab1',
    scientific_topic: [ScientificTopic.find_by_preferred_label('Biomarkers'), ScientificTopic.find_by_preferred_label('Pharmacology')],
    target_audience: ['Bioinformaticians'],
    keywords: ['Galaxy', 'linux'],
    licence: "BSD-3-Clause",
    difficulty_level: "Intermediate",
    authors: ['Jane Doe', 'Tom', 'John Doe'],
    contributors: [],
    remote_created_date: Date.today - 356,
    remote_updated_date: Date.today - 10)

Material.create!(
    title: 'NGS current challenges and data analysis for plant researchers',
    short_description: 'Complete course materials from the 2014 NGS course ran by Bernardo Clavijo, Frederik Coppens, Keywan Hassani-Pak, Richard Leggett, Mirko Moser, Emily Pritchard, Richard Smith-Unna and Michela Troggio at TGAC.',
    url: 'https://documentation.tgac.ac.uk/download/attachments/9076925/SeqAhead%20NGS.rar?version=1&modificationDate=1439824066000&api=v2',
    long_description: "The course will combine lectures and led discussions to identify key challenges, opportunities and bottlenecks, with practical session on:\n
Automated and standardized data analysis for plant species data
Data quality checks\n
Estimation of reproducibility\n
Batch effects\n
Statistical concepts\n
Importance of standards\n
Data formats\n
Data integration",
    doi: 'doi:10.1002/0470841559.ch1',
    scientific_topic: [ScientificTopic.find_by_preferred_label('Computational biology'), ScientificTopic.find_by_preferred_label('Function analysis')],
    target_audience: ['Bioinformaticians'],
    keywords: ['Galaxy', 'linux'],
    licence: "GPL-3.0",
    difficulty_level: "Advanced",
    authors: ['John Doe'],
    contributors: ['J.I. Joe'],
    remote_created_date: Date.today - 25,
    remote_updated_date: Date.today - 1)

ContentProvider.delete_all
ContentProvider.create!(
    title: "GOBLET",
    url: "http://www.mygoblet.org",
    logo_url: "http://www.mygoblet.org/sites/default/files/logo_goblet_trans.png",
    description: "GOBLET, the Global Organisation for Bioinformatics Learning, Education and Training, is a legally registered foundation providing a global, sustainable support and networking structure for bioinformatics educators/trainers and students/trainees."
).create_activity :create
ContentProvider.create!(
    title: "TGAC",
    url: "http://www.tgac.ac.uk",
    logo_url: "http://www.tgac.ac.uk/v2images/tgac_logo_single.png",
    description: "The Genome Analysis Centre (TGAC) is a research institute focused on the application of state of the art genomics and bioinformatics to advance plant, animal and microbial research to promote a sustainable bioeconomy. TGAC is a hub for innovative bioinformatics founded on research, analysis and interpretation of multiple, complex data sets. We host one of the largest computing hardware facilities dedicated to life science research in Europe.."
).create_activity :create
ContentProvider.create!(
    title: "Birmingham Metabolomics Training Centre",
    url: "http://www.birmingham.ac.uk/facilities/metabolomics-training-centre/index.aspx",
    logo_url: "https://tess.elixir-uk.org/uploads/group/2015-11-06-133537.647231BMTC.jpg",
    description: "Providing training to empower the next generation of metabolomics researchers. The Birmingham Metabolomics Training Centre will provide training to the metabolomics community in both analytical and computational methods. The training centre will partner with both the Phenome Centre Birmingham and the NERC Biomolecular Analysis Facility to provide vocational training courses in clinical and environmental metabolomics. A combination of both face-to-face and online courses will be provided. The training centre is directed by Professor Mark Viant, Dr Warwick Dunn, Dr Ralf Weber and Dr Catherine Winder."
).create_activity :create
ContentProvider.create!(
    title: "European Bioinformatics Institute (EBI)",
    url: "http://www.ebi.ac.uk",
    logo_url: "http://www.ebi.ac.uk/miriam/static/main/img/EBI_logo.png",
    description: "EMBL-EBI provides freely available data from life science experiments, performs basic research in computational biology and offers an extensive user training programme, supporting researchers in academia and industry."
).create_activity :create
ContentProvider.create!(
    title: "Swiss Institute of Bioinformatics",
    url: "http://edu.isb-sib.ch/",
    logo_url: "http://www.isb-sib.ch/templates/sib/images/sib_logo.png",
    description: "The SIB Swiss Institute of Bioinformatics is an academic, non-profit foundation recognised of public utility and established in 1998. SIB coordinates research and education in bioinformatics throughout Switzerland and provides high quality bioinformatics services to the national and international research community."
).create_activity :create
ContentProvider.create!(
    title: "Genome 3D",
    url: "http://genome3d.eu/",
    logo_url: "https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcQwd3d_tBGpERIc1QYAWERLLdesDHr-k41oASnaoNHzLVXVBPtYaQ",
    description: "Genome3D provides consensus structural annotations and 3D models for sequences from model organisms, including human. These data are generated by several UK based resources in the Genome3D consortium: SCOP, CATH, SUPERFAMILY, Gene3D, FUGUE, THREADER, PHYRE."
).create_activity :create
ContentProvider.create!(
    title: "Software Carpentry",
    url: "http://software-carpentry.org/",
    logo_url: "http://software-carpentry.org/img/software-carpentry-banner.png",
    description: "The Software Carpentry Foundation is a non-profit organization whose members teach researchers basic software skills."
).create_activity :create
ContentProvider.create!(
    title: "NGS Registry",
    url: "https://microasp.upsc.se/ngs_trainers/Materials/wikis/home",
    logo_url: "https://tess.elixir-uk.org/base/images/placeholder-organization.png",
    description: "GitLab registry containing NGS Training Materials"
).create_activity :create
ContentProvider.create!(
    title: "Bioinformatics Training and Services",
    url: "https://www.bits.vib.be/",
    logo_url: "https://www.bits.vib.be/images/images/bits_logo_color_2012_04_transp.png",
    description: "Provider of Bioinformatics and software training, plus informatics services and resource management support."
).create_activity :create
ContentProvider.create!(
    title: "ELIXIR",
    url: "http://www.elixir-europe.org/",
    logo_url: "http://www.elixir-europe.org/global/images/ELIXIR_logo.png",
    description: "ELIXIR intends to create an infrastructure that integrates research data from all corners of Europe, ensuring a service provision which provides Open Access to rapidly expanding and critical datasets."
).create_activity :create
ContentProvider.create!(
    title: "CSC",
    url: "https://www.csc.fi",
    logo_url: "https://www.csc.fi/csc-subpage-theme/images/csc-logo-teksti-en.png",
    description: "CSC maintains and develops the Finnish state-owned centralised IT infrastructure and uses it to provide nationwide IT services for research, libraries, archives, museums and culture as well as information, education and research management.."
).create_activity :create



Package.delete_all

Package.create!(
    name: 'TGAC NGS',
    description: 'Some of the Training provided at TGAC, Norwich UK',
    image_url: 'http://www.tgac.ac.uk/v2images/tgac_logo_single.png',
    public: true,
    events: [Event.find_by_title('Signalling Networks: From Data to Modelling'), Event.find_by_title('TGAC Summer School on Bioinformatics')].compact,
    materials: [Material.find_by_title('NGS current challenges and data analysis for plant researchers')]
)


