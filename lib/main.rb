class Game
	def game
		loop do
  	  @word = Word.new
			round
			sleep(2)
			play_again = ask_to_play_again
			break if play_again == 'n'
		end
		puts 'Thank you for playing!'
	end

  private

  def round
    guesses = []
    incorrect_guesses = []
    chances = 7

    until @word.solved? || chances.zero?
      display_game_state(incorrect_guesses, chances)
      guess = get_valid_guess(guesses)
      guesses.push(guess)

      unless @word.make_guess(guess)
        incorrect_guesses.push(guess)
        chances -= 1
      end
    end

    display_game_state(incorrect_guesses, chances)
    display_game_result
  end

  def display_game_state(incorrect_guesses, chances)
    puts "\n#{@word}"
    puts "\nIncorrect guesses: #{incorrect_guesses.join(' ')}"
    puts "\nChances: #{chances}"
  end

  def get_valid_guess(guesses)
    guess = UserInput.get_single_letter_guess

    loop do
      break unless guesses.include?(guess)
      puts 'Invalid input. Please guess something you have not already guessed.'
      guess = UserInput.get_single_letter_guess
    end

    guess
  end

  def display_game_result
    if @word.solved?
      puts "\nWell done! You guessed the right word!"
    else
      puts "\nBad luck! The word was #{@word}."
    end
  end

	def ask_to_play_again
		puts "\nDo you want to play again? (y/n)"
		loop do
			play_again = gets.chomp.downcase
			return play_again if ['y', 'n'].include?(play_again)

			puts "Invalid input. Please enter 'y' for yes or 'n' for no."
		end
	end
end

class Word
  def initialize
    choose_word
    @chances = 7
  end

  def to_s
    @chances.zero? ? @word : @guessed_word.split('').join(' ')
  end

  def make_guess(guess)
    if @word.include?(guess)
      @word.each_char.with_index { |char, index| @guessed_word[index] = guess if char == guess }
      true
    else
      @chances -= 1
      false
    end
  end

  def solved?
    !@guessed_word.include?('_')
  end

  private

  def choose_word
    words = []

    words_file = File.open('words.txt', 'r')

    words_file.each_line do |word|
      word = word.chomp
      words.push(word)
    end

    @word = words.sample.upcase
    @guessed_word = '_' * @word.length
  end
end

class UserInput
  def self.get_single_letter_guess
    guess = gets.chomp.upcase

    loop do
      break if guess.match?(/[A-Z]/) && guess.length == 1
      puts 'Invalid input. Please guess a single letter.'
      guess = gets.chomp.upcase
    end

    guess
  end
end

Game.new.game