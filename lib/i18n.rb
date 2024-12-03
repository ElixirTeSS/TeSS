module I18n
  module Locale
    module Tag
      class << self
        def has_subtags?(locale)
          I18n::Locale::Tag::Rfc4646
            .parser.match(locale)
            .compact
            .length > 1
        end
      end
    end
  end
end
