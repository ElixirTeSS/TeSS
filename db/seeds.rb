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

Material.delete_all

Material.create!(
    title: 'Metabolomics: Understanding Metabolism in the 21st Century',
    short_description: 'Discover how metabolomics is revolutionising our understanding of metabolism with this free online course.',
    url: 'https://www.futurelearn.com/courses/metabolomics',
    long_description: "Discover how metabolomics is revolutionising our understanding of metabolism with this free online course.
Metabolomics is an emerging field that aims to measure the complement of metabolites (the intermediates and products of metabolism) in living organisms. The complement of metabolites in a biological system is known as the metabolome and represents the downstream effect of an organism’s genome and its interaction with the environment. Metabolomics has a wide application area across the medical and biological sciences and is attractive to both new and established scientists. In this course we will provide an introduction to metabolomics, explain why we want to study the metabolome and describe the current challenges in analysing the complement of metabolites in a biological system. We will describe the interdisciplinary approaches adopted in the metabolomics workflow and demonstrate how the combined efforts of scientist’s from different disciplines is advancing this exciting field. By the end of the course the learner will understand how metabolomics can revolutionise our understanding of metabolism.
The course will be targeted towards final year undergraduate students from biology / chemical disciplines and medical students, but will also provide a valuable introduction to the metabolomics field for MSc and PhD students, and scientists at any stage in their careers. Metabolomics is a new tool to the scientific community and has widespread applications across the medical and biological sciences in academia and industry.",
    doi: 'doi:14.1502/06780841559.ab1',
    scientific_topic: ['Biophysics'],
    target_audience: ['Bioinformaticians'],
    keywords: ['Galaxy', 'unix', 'Taverna'],
    remote_created_date: Date.today - 256,
    remote_updated_date: Date.today - 48)

Material.create!(
    title: 'Browsing plant and pathogen genomes with Ensembl Genomes',
    short_description: 'Complete course materials from the 2014 GBS course ran by Bert Overduin at TGAC.',
    url: 'https://documentation.tgac.ac.uk/download/attachments/9076929/Plants%20and%20Pathogens%20ENSEMBL.rar?version=1&modificationDate=1439825372000&api=v2',
    long_description: "The Ensembl genome annotation system, developed jointly by the EBI and the Wellcome Trust Sanger Institute, has been used for the annotation, analysis, and display of vertebrate genomes since 2000.  Since 2009, the Ensembl site has been complemented by the creation of five new sites for bacteria, protists, fungi, plants and invertebrate metazoa, enabling users to access a single collection of interactive interfaces for accessing and comparing genome-scale data from species of scientific interest across taxonomy.
This one-day, hands-on course will explore the EBI's Ensembl Genomes Browser at www.ensemblgenomes.org in order to explore genes, sequence variation, and other data for plants and pathogens. New users and those who wish to deepen their understanding of the data and navigation behind the Ensembl Genomes Browser are welcome.",
    doi: 'doi:34.1502/06435841559.ab1',
    scientific_topic: ['Biomarkers', 'Pharmacology'],
    target_audience: ['Bioinformaticians'],
    keywords: ['Galaxy', 'linux'],
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
    scientific_topic: ['Computational biology', 'Function analysis'],
    target_audience: ['Bioinformaticians'],
    keywords: ['Galaxy', 'linux'],
    remote_created_date: Date.today - 25,
    remote_updated_date: Date.today - 1)

