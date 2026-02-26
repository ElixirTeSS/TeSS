class PersonLinkWorker
  include Sidekiq::Worker

  def perform(orcids)
    Person.where(orcid: orcids).find_each do |person|
      person.save!
    end
  end
end
