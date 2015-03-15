#!/usr/bin/env ruby

class Mastermind
  COLORS = [:white, :yellow, :pink, :purple, :orange, :turquoise]

  # Create all valid scores, i.e., different numbers of red/white.

  SCORES = (0..4).map  do |r|
    (0..(4-r)).map do |w|
      ([:red] * r) + ([:white] * w)
    end
  end.flatten(1)

  CODES = COLORS.permutation(4).to_a

  # use_all_codes: true means make guesses from CODES which contains
  # all possible codes.  It remains to be seen whether having a larger
  # set of guesses makes solving faster.  False means make guesses
  # only from codes.  codes: an Array of all codes that are possible
  # given the previous guesses and scores.
  #
  def initialize(use_all_codes = true, codes = CODES)
    @use_all_codes = use_all_codes
    @codes = codes
  end

  def self.random_code(codes = CODES)
    codes.sample
  end

  def size
    @codes.size
  end

  def make_guess
    case
      when @codes == CODES
        # This saves time on the first guess.  It's unknown whether
        # some guesses might be better, e.g., guesses with more or
        # less duplicate colors.
        Mastermind.random_code(@codes)
      when @codes.size == 1
        # This case is only necessary if we're making guesses from
        # CODES instead of @codes.
        @codes[0]
      else
        # Choosing a guess from all possible codes may narrow down the
        # possibilities later.
        (@use_all_codes ? CODES : @codes).min_by do |guess|
          SCORES.map do |score|
            new_for_guess_and_score(guess, score).size
          end.max
        end
    end
  end

  def new_for_guess_and_score(guess, score)
    Mastermind.new(@use_all_codes, Mastermind.filter_codes(@codes, guess, score))
  end

  def self.compute_score(code, guess)
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

  def self.filter_codes(codes, guess, score)
    codes.select do |code|
      Mastermind.compute_score(code, guess) == score
    end
  end
end

if false
m = Mastermind.new
code = Mastermind.random_code
puts code.inspect

loop do
  guess = m.make_guess
  score = Mastermind.compute_score(code, guess)
  m.new_for_guess_and_score(guess, score)
  puts "#{guess.inspect} => #{score.inspect} => #{m.size}"
  break if guess == code
end
end

# GamePlayer.new.play_a_game(Mastermind.new)
#
class GamePlayer
  def initialize(use_all_codes = true)
    @use_all_codes = use_all_codes
  end

  def play_games(n = 10)
    t = Time.now
    turns = (1..n).map do
      play_a_game(Mastermind.new(@use_all_codes)).tap do
        STDOUT.write(".")
      end
    end
    puts
    puts turns.reduce(&:+).to_f / n
    puts turns.minmax
    puts (Time.now - t) / n
    nil
  end

  def play_a_game(m)
    code = Mastermind.random_code
    turns = 0
    loop do
      turns += 1
      guess = m.make_guess
      if guess == code
        return turns
      end
      score = Mastermind.compute_score(code, guess)
      m = m.new_for_guess_and_score(guess, score)
    end
  end
end
