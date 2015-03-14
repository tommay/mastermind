#!/usr/bin/env ruby

require_relative "log.rb"

class Mastermind
  COLORS = [:white, :yellow, :pink, :purple] #, :orange, :turquoise]

  # Create all valid scores, i.e., different numbers of red/white.

  N = 3

  SCORES = (0..N).map do |r|
    (0..(N-r)).map do |w|
      ([:red] * r) + ([:white] * w)
    end
  end.flatten(1)

  # Returns all combinations of length size of the elements in the
  # array.  Each combination will use each element zero to size times.
  # If size is zero the result is [[]] because there is one combination
  # of zero elements and it is empty.

  def self.combinations(size, array)
    accum = [[]]
    size.times do
      accum = accum.flat_map do |c|
        array.map{|e| c + [e]}
      end
    end
    accum
  end

  CODES = Mastermind.combinations(N, COLORS)

  # use_all_codes: true means make guesses from CODES which contains
  # all possible codes.  This requires more guesses with the one-ply
  # search so it's a lose.  False means make guesses only from codes.
  # codes: an Array of all codes that are possible given the previous
  # guesses and scores.  Tests on one-ply searches show using all
  # codes on average takes more guesses.
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
        # For each possible guess we need to know the worst-case path
        # then we pick the guess with the shortest worst-case path.
        best_guess[0]
    end
  end

  def final_code
    @codes[0]
  end

  # Returns [guess, path_length].

  require "byebug"

  def best_guess
    @codes.map do |code|
      SCORES.map do |score|
        m = new_for_guess_and_score(code, score)
        case m.size
        when 0
          # This score is not possible; no remaining code could result
          # in this score.
          nil
        when 1
          # There is only one possible code remaining, so it is a final guess.
          [m.final_code, 0]
        else
          m.best_guess
        end
      end.compact.max_by do |code, path_length|
        path_length
      end.let do |code, path_length|
        [code, path_length + 1]
      end
    end.min_by do |code, path_length|
      path_length
    end
  end

  # If we make the given guess, what is the resulting worst-case path
  # length for solving the code?

  def path_length(guess)
    Log.indent("path_length #{guess.inspect}") do
      do_path_length(guess).tap{|x| Log.debug("returning #{x.inspect}")}
    end
  end

  def do_path_length(guess)
    path_length = SCORES.map do |score|
     Log.indent("score #{score.inspect}") do
      m = self.new_for_guess_and_score(guess, score)
      case m.size
      when self.size
        # This guess/score doesn't reduce the set of possible @codes.
        # Probably we've guessed it before.
        nil
      when 0
        # This score is not possible; no remaining @codes could result
        # in this score.
        nil
      when 1
        # There is only one possible code remaining, so it is a final guess.
        0
      else
        # Return the path_length for the worst-case code.
        @codes.map do |code|
          m.path_length(code)
        end.compact.max
      end.tap{|x|Log.debug("returns #{x.inspect}")}
     end
    end.compact.max
    path_length && path_length + 1
  end

  class Object
    def let(&block)
      block.call(self)
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

# GamePlayer.new.play_a_game(Mastermind.new)
# GamePlayer.new.play_games(10)
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

m = Mastermind.new
g = [:white, :yellow, :pink]
m.path_length(g)
