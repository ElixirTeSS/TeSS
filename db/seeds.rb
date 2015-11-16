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
    url: 'https://www.futurelearn.com/courses/metabolomics')
Material.create!(
    title: 'Browsing plant and pathogen genomes with Ensembl Genomes',
    short_description: 'Complete course materials from the 2014 GBS course ran by Bert Overduin at TGAC.',
    url: 'https://documentation.tgac.ac.uk/download/attachments/9076929/Plants%20and%20Pathogens%20ENSEMBL.rar?version=1&modificationDate=1439825372000&api=v2')
Material.create!(
    title: 'NGS current challenges and data analysis for plant researchers',
    short_description: 'Complete course materials from the 2014 NGS course ran by Bernardo Clavijo, Frederik Coppens, Keywan Hassani-Pak, Richard Leggett, Mirko Moser, Emily Pritchard, Richard Smith-Unna and Michela Troggio at TGAC.',
    url: 'https://documentation.tgac.ac.uk/download/attachments/9076925/SeqAhead%20NGS.rar?version=1&modificationDate=1439824066000&api=v2')
