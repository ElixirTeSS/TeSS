module TrigramSimilarity
  def trigram(word)
    return [] if word.strip.blank?

    parts = []
    padded = "  #{word} ".downcase
    padded.chars.each_cons(3) { |w| parts << w.join }
    parts
  end

  def similarity(word1, word2)
    tri1 = trigram(word1)
    tri2 = trigram(word2)

    return 0.0 if tri1.empty?
    return 0.0 if tri2.empty?

    same = (tri1 & tri2).size
    all = (tri1 | tri2).size

    same.to_f / all
  end

  def similar?(word1, word2)
    similarity(word1, word2) >= 0.3
  end
end
