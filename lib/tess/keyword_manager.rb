# From http://pastebin.com/4p6aN7n0
# in lib/tess/keyword_manager.rb
module TeSS
  module KeywordManager

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    def self.keywords_file(access)
      file_path = Rails.root.join('lib', 'assets', 'suggestions.txt').to_s
      if !File.exists?(file_path)
        a = File.open(file_path, 'w')
        a.close
      end
      File.open(file_path, access)
    end

    def self.keywords_array
      k = keywords_file('r')
      words = k.read.split("\n").uniq
      k.close
      return words
    end


    module ClassMethods
      def update_keywords()
        before_save :add_keywords
        before_destroy :delete_keywords
        include KeywordManager::InstanceMethods
      end
    end

    module InstanceMethods
      private
      def add_keywords
        keywords = keywords_array
        submitted_keywords = self["keywords"].dup
        submitted_keywords.each do |keyword|
          unless keywords.include?(keyword)
            file = keywords_file('a+')
            file << "#{keyword}\n"
            file.close
          end
        end
      end

      def delete_keywords
        # pass
      end

    end

  end

  ActiveRecord::Base.class_eval do
    include KeywordManager
  end
# end of lib/keyword_manager.rb

# in your model:
#   class SomeModel < ActiveRecord::Base
#     add_keywords(:keywords)
#     delete_keywords(:keywords)
#   end
end