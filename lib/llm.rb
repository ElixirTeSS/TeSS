# frozen_string_literal: true

# Module for LLM based scraping and post processing
module Llm
  def self.service_hash
    {
      chatgpt: Llm::ChatgptService,
      willma: Llm::WillmaService
    }
  end

  def self.post_processing_task
    llm_service_class = Llm.service_hash.fetch(TeSS::Config.llm_scraper['model']&.to_sym, nil)
    return unless llm_service_class

    prompt = File.read(File.join(Rails.root, 'lib', 'llm', 'llm_prompts', 'llm_process_prompt.txt'))
    filtered_event_list(prompt).each do |event|
      llm_service = llm_service_class.new
      event = llm_service.post_process_func(event)
      event.save!
    end
  end

  def self.filtered_event_list(prompt)
    Event.not_finished.needs_processing(prompt)
  end

  def self.reset_llm_status_task
    Event.not_finished.each do |event|
      event&.llm_interaction&.needs_processing = true
      event.save!
    end
  end
end
