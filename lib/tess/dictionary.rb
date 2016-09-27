class Dictionary

  include Singleton

  def lookup(key)
    @dictionary[key]
  end

end
