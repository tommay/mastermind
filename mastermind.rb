#!/usr/bin/env ruby

class Mastermind
  @@colors = [:white, :yellow, :pink, :purple, :orange, :turquoise]

  # Create all valid scores, i.e., different numbers of red/white.

  @@scores = (0..4).map  do |r|
    (0..(4-r)).map do |w|
      ([:red] * r) + ([:white] * w)
    end
  end.flatten(1)

  @@all_codes = @@colors.permutation(4).to_a

  def initialize(use_all_codes)
    @codes = @@all_codes
    @use_all_codes = use_all_codes
  end

  def random_code(codes = @@all_codes)
    codes.sample
  end

  def size
    @codes.size
  end

  def make_guess
    case
      when @codes == @@all_codes
        # This saves time on the first guess.
        random_code(@codes)
      when @codes.size == 1
        # This case is only necessary if we're making guesses from
        # @@all_codes instead of @codes.
        @codes[0]
      else
        # Choosing a guess from all possible codes may narrow down the
        # possibilities later.
        (@use_all_codes ? @@all_codes : @codes).min_by do |guess|
          score_count = 0
          @@scores.each do |score|
            filtered_count = filter_codes(@codes, guess, score).size
            if filtered_count > score_count
              score_count = filtered_count
            end
          end
          score_count
        end
    end
  end

  def set_score(guess, score)
    @codes = filter_codes(@codes, guess, score)
  end

  def compute_score(code, guess)
    code = code.clone
    guess = guess.clone
    score = []
    # Red matches.
    guess.each_index do |i|
      if guess[i] == code[i]
        score << :red
        guess[i] = nil
        code[i] = nil
      end
    end
    # White matches.
    guess.each do |color|
      i = color && code.index(color)
      if i
        score << :white
        code[i] = nil
      end
    end
    score
  end

  # Return the codes for which the given guess gets the given score.

  def filter_codes(codes, guess, score)
    codes.select do |code|
      compute_score(code, guess) == score
    end
  end
end

if false
m = Mastermind.new
code = m.random_code
puts code.inspect

loop do
  guess = m.make_guess
  score = m.compute_score(code, guess)
  m.set_score(guess, score)
  puts "#{guess.inspect} => #{score.inspect} => #{m.size}"
  break if guess == code
end
end

class GamePlayer
  def initialize(use_all_codes = true)
    @use_all_codes = use_all_codes
  end

  def play_games(n = 10)
    t = Time.now
    total_turns = 0
    n.times do
      total_turns += play_a_game(Mastermind.new(@use_all_codes))
      STDOUT.write(".")
    end
    puts
    puts total_turns.to_f / n
    puts Time.now - t
    nil
  end

  def play_a_game(m)
    code = m.random_code
    turns = 0
    loop do
      turns += 1
      guess = m.make_guess
      if guess == code
        return turns
      end
      score = m.compute_score(code, guess)
      m.set_score(guess, score)
    end
  end
end
