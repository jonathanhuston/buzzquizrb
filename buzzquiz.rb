require 'csv'
require 'tk'
require 'tkextlib/tile'
require 'tkextlib/tkimg'

DX = 300
DY = 0

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
    records[count][:color] = line[1].intern
    records[count][:description] = line[2]
    records[count][:image] = $images_folder+line[0].tr(' ', '-')+".jpg"
    count += 1
  end
  records
end

def load_quiz()
  lines = CSV.read($questions_file)
  lines[0][0].delete!("\ufeff")
  title = lines.shift[0]
  lines.shift
  questions = parse_questions(lines)
  lines = CSV.read($descriptions_file)
  lines[0][0].delete!("\ufeff")
  descriptions = parse_descriptions(lines)
  [title, questions, descriptions]
end


#FIX: dual displays
def display_character(character)
  $content = Tk::Tile::Frame.new($root) {padding "20"}.grid(:column => 0, :row => 0, :sticky => 'nsew')
  Tk::Tile::Label.new($content) {text "You are #{character[:name]}."; foreground character[:color]}.grid(:column => 0, :row => 0, :sticky => 'w')
  Tk::Tile::Label.new($content) {text character[:description]; wraplength 320; foreground character[:color]}.grid(:column => 0, :row => 1, :columnspan => 3, :sticky => 'w')
  image = TkPhotoImage.new(:file => character[:image])
  Tk::Tile::Label.new($content) {padding "0 20"; image image}.grid(:column => 0, :row => 2, :sticky => 'w')
  Tk::Tile::Frame.new($content) {height 60}.grid(:column => 0, :row => 3)
  Tk::Tile::Button.new($content) {text "Play again?"; command proc { new_game }}.grid(:column => 0, :row => 3, :sticky => 'w')
  Tk::Tile::Button.new($content) {text "Quit"; command 'exit'}.grid(:column => 0, :row => 3, :sticky => 'e')
end

def display_questions(index)
  $content = Tk::Tile::Frame.new($root) {padding "20"}.grid(:column => 0, :row => 0, :sticky => 'nsew')
  Tk::Tile::Frame.new($content) {width 400; height 40}.grid(:column => 0, :row => 0, :sticky => 'w')
  Tk::Tile::Label.new($content) {text $questions[index][:question]}.grid(:column => 0, :row => 0, :sticky => 'w')
  $answer = TkVariable.new($content)
  row = 1
  $questions[index][:answers].each do |answer|
    if answer[-4..-1] == ".jpg"
      image = TkPhotoImage.new(:file => $images_folder+answer)
      scale = image.height / 75
      scale = 1 if scale < 1
      scaled_image = TkPhotoImage.new.copy(image, :subsample => [scale, scale])
      image = nil
      Tk::Tile::RadioButton.new($content) {text ""; image scaled_image; variable $answer; value row}.grid(:column => 0, :row => row, :sticky => 'w')
    else
      Tk::Tile::RadioButton.new($content) {text answer; variable $answer; value row}.grid(:column => 0, :row => row, :sticky => 'w')
    end
    row += 1
  end
  Tk::Tile::Frame.new($content) {width 400; height 60}.grid(:column => 0, :row => row)
  Tk::Tile::Button.new($content) {text "Next"; command proc { next_question index }}.grid(:column => 0, :row => row, :sticky => 'w')
end


def run_quiz(index)
  if index < $questions.size 
    display_questions(index)
  else
    character = $descriptions[$point_totals.each_with_index.max[1]]
    $root.title = character[:name]
    display_character(character)
  end
end

def next_question(index)
  $content.destroy
  $point_totals.map!.with_index { |point_total, i| point_total + $questions[index][:points][$answer.to_i-1][i].to_i }
  run_quiz index + 1
end

def new_game()
  $content.destroy
  $point_totals = Array.new($descriptions.size, 0)
  $root.title = $title
  run_quiz 0
end


quiz_name = ARGV[0]
begin
  $questions_file = "#{Dir.home}/quiz_data/#{quiz_name.tr(' ', '-')}-questions.csv"
  $descriptions_file = "#{Dir.home}/quiz_data/#{quiz_name.tr(' ', '-')}-descriptions.csv"
  $images_folder = "#{Dir.home}/quiz_data/#{quiz_name.tr(' ', '-')}-images/"
  $title, $questions, $descriptions = load_quiz()
rescue
  puts "Game engine unable to find properly formatted game data."
  puts "Check command line argument and game data files."
  exit
end

$root = TkRoot.new {title $title; geometry "+#{DX}+#{DY}"}
$point_totals = Array.new($descriptions.size, 0)
run_quiz 0
Tk.mainloop
