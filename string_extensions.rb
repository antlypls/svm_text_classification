require_relative 'stop_words'

class String
  def numeric?
    true if Float(self) rescue false
  end

  def stop_word?
    length <= 2 || STOP_WORDS.include?(self)
  end

  def valid_word?
    !(stop_word? || numeric?)
  end

  def to_utf8
    encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
      .force_encoding('UTF-8')
    rescue ''
  end

  # split by dashes and spaces
  def fragmentize
    downcase.to_utf8.tr('-', ' ').gsub(/[^\w\s]/, ' ').split
  end
end
