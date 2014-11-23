require 'rubygems'
require 'bundler'
Bundler.require(:default)

require_relative 'string_extensions'
require_relative 'words_bag'

DATA = ENV['DATA'] || 'data/movie_reviews'

class Pattern < Struct.new(:features, :label)
end

class PatternsBuilder
  def initialize
    @all_words = Hash.new(0)
  end

  def build_from_file(file)
    bag = WordsBag.new(File.read(file))
    bag.each { |word, count| @all_words[word] += count }
    bag.words
  end

  def build_label(label)
    files = Dir[File.join(DATA, label.to_s, '*.txt')]

    files.map { |file| Pattern.new(build_from_file(file), label) }
  end

  def normalize_pattern(pattern)
    features = {}

    pattern.features.each do |w|
      index = @mapping[w]
      features[index] = 1 if index
    end

    Pattern.new(features, pattern.label)
  end

  def build_mapping
    @mapping = {}
    @all_words.keys
      .sort_by { |w| @all_words[w] }
      .take(2000)
      .each_with_index { |w, i| @mapping[w] = i }
  end

  def normalize_patterns(patterns)
    patterns.map { |p| normalize_pattern(p) }
  end

  def build
    pos = build_label(:pos)
    neg = build_label(:neg)

    build_mapping

    pos = normalize_patterns(pos)
    neg = normalize_patterns(neg)

    [pos, neg]
  end
end

# p Pattern.build_from_directory(:pos)

puts '>>>>>>>>>>>>> read data'

pos, neg = PatternsBuilder.new.build

puts '>>>>>>>>>>>>> prepare data'

data = pos.zip(neg).flatten

training_set = data.take(data.count * 3 / 4)
testing_set  = data.drop(data.count * 3 / 4)

puts '>>>>>>>>>>>>> prepare data 1'

examples = training_set.map { |p| Libsvm::Node.features(p.features) }
labels = training_set.map { |p| p.label == :neg ? 0 : 1 }

puts '>>>>>>>>>>>>> prepare data 2'

problem = Libsvm::Problem.new
parameter = Libsvm::SvmParameter.new

parameter.cache_size = 100 # in megabytes

parameter.nu = 0.99
parameter.eps = 0.00001
parameter.gamma = 1.0
parameter.svm_type = Libsvm::SvmType::NU_SVC
parameter.kernel_type = Libsvm::KernelType::RBF

problem.set_examples(labels, examples)

puts '>>>>>>>>>>>>> training'

model = Libsvm::Model.train(problem, parameter)

correct = 0
error = 0

testing_set.each do |p|
  example = Libsvm::Node.features(p.features)
  label = p.label == :neg ? 0 : 1

  predict = model.predict(example).to_i

  puts "#{p.label} : #{label} : #{predict}"

  if predict == label
    correct += 1
  else
    error += 1
  end
end

puts correct
puts error
