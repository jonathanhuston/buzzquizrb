require 'csv'
require 'rainbow/refinement'

using Rainbow

def parse_questions(lines)
  records = []
  count = 0
  line_count = 0

  while line_count < lines.size
    records[count] = {}
    records[count][:question] = lines[line_count][0]
    line_count += 2
    records[count][:answers] = []
    records[count][:points] = []
    until (line_count >= lines.size) || (lines[line_count].compact.empty?)
      records[count][:answers] << lines[line_count][0]
      records[count][:points] << lines[line_count][1..-1]
      line_count += 1
    end
    line_count += 1
    count += 1
  end
  records
end

def parse_descriptions(lines)
  records = []
  count = 0

  lines.each do |line|
    records[count] = {}
    records[count][:name] = line[0]
    records[count][:color] = line[1]
    brightness = line[2]
    records[count][:color] += "." + brightness if brightness
    records[count][:description] = line[3]
    count += 1
  end
  records
end

def load_quiz(questions_file, descriptions_file)
  lines = CSV.read(questions_file)
  lines[0][0].delete!("\ufeff")
  questions = parse_questions(lines)
  descriptions = parse_descriptions(CSV.read(descriptions_file))
  return questions, descriptions
end

def run_quiz(questions, descriptions)
  point_totals = Array.new(descriptions.size, 0)

  questions.each do |question|
    puts question[:question]
    question[:answers].each_with_index { |answer, i| puts "#{i+1}) #{answer}" }
    puts
    print ">> "
    reply = gets.strip.to_i
    point_totals.map!.with_index { |point_total, i| point_total + question[:points][reply-1][i].to_i }
    puts
  end
  point_totals
end

def display_character(character)
  puts
  puts "You are #{character[:name]}."
  puts "#{character[:description]}"
end

def main_loop
    print 'Enter the name of a quiz: '
    quiz_name = gets.strip.downcase
    return if quiz_name.empty?
    questions_file = "#{Dir.home}/quiz_data/#{quiz_name.tr(' ', '-')}-questions.csv"
    descriptions_file = "#{Dir.home}/quiz_data/#{quiz_name.tr(' ', '-')}-descriptions.csv"
    questions, descriptions = load_quiz(questions_file, descriptions_file)

  loop do
    system 'clear'
    point_totals = run_quiz(questions, descriptions)
    character = descriptions[point_totals.each_with_index.max[1]]
    display_character(character)
    print "\n\n"
    print "Play again? "
    break if gets.strip.empty?
  end
end

system 'clear'
main_loop
puts "Goodbye!\n"