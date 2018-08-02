class ScientificTopic < ActiveRecord::Base; end

class FixBlankArrayValuesInScientificTopics < ActiveRecord::Migration[4.2]
  def change
    array_fields = [:synonyms, :definitions, :parents, :consider, :has_alternative_id, :has_broad_synonym,
                    :has_narrow_synonym, :has_dbxref, :has_exact_synonym, :has_related_synonym, :has_subset, :in_subset,
                    :replaced_by, :subset_property, :in_cyclic]

    ScientificTopic.all.each do |st|
      array_fields.each do |field|
        values = st.send(field)
        if values.any?(&:blank?)
          puts "Fixing #{field} in scientific topic #{st.id}"
          st.update_column(field, values.reject(&:blank?))
        end
      end
    end
  end
end
