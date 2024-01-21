require 'yaml'

class Game
	def game
		loop do
			@round = load_or_new_game
			@round.play
			sleep(1.5)
			play_again = ask_to_play_again
			break if play_again == 'n'
		end
		puts 'Thank you for playing!'
	end

	private

	def load_or_new_game
		puts "\nDo you want to load a saved game or start a new one? (l/n)"
		choice = gets.chomp.downcase
		loop do
			break if ['l', 'n'].include?(choice)

			puts "Invalid input. Please enter 'l' for load or 'n' for new."
			choice = gets.chomp.downcase
		end

		if choice == 'l'
			return Round.from_yaml
		else
			return Round.new
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

class Round
	def initialize(word = Word.new, guesses = [], incorrect_guesses = [], chances = 7)
		@word = word
		@guesses = guesses
		@incorrect_guesses = incorrect_guesses
		@chances = chances
	end

	def play
		until @word.solved? || @chances.zero?
			display_game_state
			guess = get_valid_guess
			@guesses.push(guess)

			unless @word.make_guess(guess)
				@incorrect_guesses.push(guess)
				@chances -= 1
			end
		end

		display_game_state
		display_game_result
	end

	private

	def display_game_state
		puts "\n#{@word}"
		puts "\nIncorrect guesses: #{@incorrect_guesses.join(' ')}"
		puts "\nChances: #{@chances}"
	end

	def get_valid_guess
		puts 'Enter your guess:'
		guess = gets.chomp.upcase

		loop do
			to_yaml if guess == 'SAVE'
			return guess if guess.match?(/[A-Z]/) && guess.length == 1 && !@guesses.include?(guess)
			puts 'Invalid input. Please enter one letter you have not already guessed.'
			guess = gets.chomp.upcase
		end
	end

	def display_game_result
		if @word.solved?
			puts "\nWell done! You guessed the right word!"
		else
			puts "\nBad luck! The word was #{@word}."
		end
	end

	def to_yaml
		dump = YAML.dump ({word: {word: @word.word,
			guessed_word: @word.guessed_word,
			chances: @word.chances},
		guesses: @guesses,
		incorrect_guesses: @incorrect_guesses,
		chances: @chances
    })

		puts "\nSave file detected. Are you sure you want to play overwrite save data? (y/n)"
		response = gets.chomp.downcase

		loop do
			break if ['y', 'n'].include?(response)
			puts "Invalid input. Please enter 'y' for yes or 'n' for no."
			response = gets.chomp.downcase
		end

		if response == 'n'
			puts 'Exiting saving.'
			return
		end

		File.open('saved_game.yaml', 'w') { |file| file.write dump }
		puts "\nGame Saved!"
		exit
	end

	def self.from_yaml
		unless File.exist?('saved_game.yaml')
			puts 'No save data found. Starting new game.'
			return self.new
		end
		file = File.open('saved_game.yaml', 'r')
		data = File.read(file)
		saved_game = YAML.load(data)
		word_data = saved_game[:word]

		word = Word.new(word_data[:word], word_data[:guessed_word], word_data[:chances])
		puts 'Successfully loaded data!'
		self.new(word, saved_game[:guesses], saved_game[:incorrect_guesses], saved_game[:chances])
	end
end

class Word
	attr_reader :word, :guessed_word, :chances

	def initialize(word = nil, guessed_word = nil, chances = 7)
		if word && guessed_word
			@word = word
			@guessed_word = guessed_word
		else
			choose_word
		end
		@chances = chances
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

Game.new.game