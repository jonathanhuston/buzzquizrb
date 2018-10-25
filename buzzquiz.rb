require 'csv'
require 'tk'
require 'tkextlib/tile'
require 'tkextlib/tkimg'

DX = 300
DY = 150

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

def parse_descriptions(lines, images_folder)
  records = []
  count = 0

  lines.each do |line|
    records[count] = {}
    records[count][:name] = line[0]
    records[count][:color] = line[1].intern
    records[count][:description] = line[2]
    records[count][:image] = images_folder+line[0].tr(' ', '-')+".jpg"
    count += 1
  end
  records
end

def load_quiz(questions_file, descriptions_file, images_folder)
  lines = CSV.read(questions_file)
  lines[0][0].delete!("\ufeff")
  title = lines.shift[0]
  lines.shift
  questions = parse_questions(lines)
  lines = CSV.read(descriptions_file)
  lines[0][0].delete!("\ufeff")
  descriptions = parse_descriptions(lines, images_folder)
  [title, questions, descriptions]
end

#FIX: dual displays
def display_character(character)
  $character_window = TkToplevel.new {title "#{character[:name]}"}
  $character_window[:geometry]=$root[:geometry][$root[:geometry].index("+")..-1]
  content = Tk::Tile::Frame.new($character_window) {padding "20"}.grid(:column => 0, :row => 0, :sticky => 'nsew')
  Tk::Tile::Label.new(content) {text "You are #{character[:name]}."; foreground character[:color]}.grid(:column => 0, :row => 0, :sticky => 'w')
  Tk::Tile::Label.new(content) {text character[:description]; foreground character[:color]}.grid(:column => 0, :row => 1, :columnspan => 3, :sticky => 'w')
  image = TkPhotoImage.new(:file => character[:image])
  Tk::Tile::Label.new(content) {image image}.grid(:column => 0, :row => 2, :sticky => 'w')
  Tk::Tile::Frame.new(content) {height 60}.grid(:column => 0, :row => 3)
  Tk::Tile::Button.new(content) {text "Play again?"; command "run_quiz"}.grid(:column => 0, :row => 3, :sticky => 'w')
  Tk::Tile::Button.new(content) {text "Quit"; command 'exit'}.grid(:column => 0, :row => 3, :sticky => 'e')
end

def helper(index)
  display_questions(index) if $answer == ""
  $point_totals.map!.with_index { |point_total, i| point_total + $questions[index][:points][$answer.to_i-1][i].to_i }
  index += 1
  if index == $questions.size
    character = $descriptions[$point_totals.each_with_index.max[1]]
    display_character(character)
  else
    display_questions(index)
  end
end

def display_questions(index)
  $root = TkRoot.new {title $title}
  content = Tk::Tile::Frame.new($root) {padding "20 20 0 20"}.grid(:column => 0, :row => 0, :sticky => 'nsew')
  Tk::Tile::Frame.new(content) {width 400; height 40}.grid(:column => 0, :row => 0, :sticky => 'w')
  Tk::Tile::Label.new(content) {text $questions[index][:question]}.grid(:column => 0, :row => 0, :sticky => 'w')
  $answer = TkVariable.new
  row = 1
  $questions[index][:answers].each do |answer|
    Tk::Tile::RadioButton.new(content) {text answer; variable $answer; value row}.grid(:column => 0, :row => row, :sticky => 'w')
    row += 1
  end
  Tk::Tile::Frame.new(content) {width 400; height 60}.grid(:column => 0, :row => row)
  Tk::Tile::Button.new(content) {text "Next"; command "helper #{index}"}.grid(:column => 0, :row => row, :sticky => 'w')
  Tk.mainloop
end

def run_quiz
  $character_window.destroy if defined? $character_window
  $point_totals = Array.new($descriptions.size, 0)
  display_questions(0)
end

quiz_name = ARGV[0]
begin
  questions_file = "#{Dir.home}/quiz_data/#{quiz_name.tr(' ', '-')}-questions.csv"
  descriptions_file = "#{Dir.home}/quiz_data/#{quiz_name.tr(' ', '-')}-descriptions.csv"
  images_folder = "#{Dir.home}/quiz_data/#{quiz_name.tr(' ', '-')}-images/"
  $title, $questions, $descriptions = load_quiz(questions_file, descriptions_file, images_folder)
rescue
  puts "Game engine unable to find properly formatted game data."
  puts "Check command line argument and game data files."
  exit
end

TkRoot.new {geometry "+#{DX}+#{DY}"}
run_quiz
