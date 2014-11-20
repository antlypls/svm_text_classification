class WordsBag
  attr_reader :word_count

  def initialize(text)
    @hash = Hash.new(0)
    @word_count = 0
    add_text(text) unless text.nil?
  end

  def words
    @hash.keys
  end

  def [](key)
    @hash[key]
  end

  def each(&block)
    @hash.each(&block)
  end

  private

  def add_text(text)
    text.fragmentize.select(&:valid_word?).each { |word| add_word(word)}
  end

  def add_word(word)
    @word_count += 1
    word = word.stem
    @hash[word] += 1
  end
end
