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
    @last_guess = nil
    @use_all_codes = use_all_codes
  end

  def random_code(codes = @@all_codes)
    codes[rand(codes.size)]
  end

  def size
    @codes.size
  end

  def make_guess
    @last_guess = case
      when !@last_guess
        # This saves time on the first guess.
        random_code(@codes)
      when @codes.size == 1
        # This case is only necessary if we're making guess from
        # @@all_codes instead of @codes.
        @codes[0]
      else
        code_count = nil
        next_guess = nil
        # Choosing a guess fron all possible codes may narrow down the
        # possibilities later.
        (@use_all_codes ? @@all_codes : @codes).shuffle.each do |guess|
          score_count = 0
          @@scores.each do |score|
            filtered_count = filter_codes(@codes, guess, score).size
            if filtered_count > score_count
              score_count = filtered_count
            end
          end
          if !code_count || score_count < code_count
            code_count = score_count
            next_guess = guess
          end
        end
        next_guess
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
    guess.each_index.to_a.reverse.each do |i|
      if guess[i] == code[i]
        score << :red
        guess.delete_at(i)
        code.delete_at(i)
      end
    end
    # White matches.
    guess.each do |color|
      i = code.index(color)
      if i
        code.delete_at(i)
        score << :white
      end
    end
    score
  end

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
