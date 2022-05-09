require 'open-uri'
require 'json'

class GamesController < ApplicationController
  def new
    @letters = generate_letter_grid(10)
  end

  def score
    @end_time = Time.now
    @word = params[:input]
    @start_time = params[:start_time].to_datetime
    @letters = params[:letters]
    @result = run_game(@word, @letters, @start_time, @end_time)
  end

  private

  MESSAGE = {
    invalid: 'The word you entered is not a valid answer - Read the instructions carefully and try again!',
    valid_not_found: 'Uh-oh, it seems that the word you entered is not an English word - Try again!',
    valid_found: 'Good job!'
  }.freeze

  SCRABBLE_ALPHABET = [
    %w[A E I L N O R S T U] * 10,
    %w[D G] * 9,
    %w[B C M P] * 8,
    %w[F H V W Y] * 7,
    %w[K] * 6,
    %w[J X] * 3,
    %w[Q Z]
  ].join.chars

  VOWELS = %w[A E I O U].freeze

  def enough_vowels?(letters)
    letters.any? { |letter| VOWELS.include?(letter) }
  end

  def enough_consonants?(letters, grid_size)
    VOWELS.map { |letter| letters.count(letter) }.reduce(:+) <= (grid_size / 2)
  end

  def generate_letter_grid(grid_size, letters = [])
    until enough_vowels?(letters) && enough_consonants?(letters, grid_size)
      letters = []
      grid_size.times { letters << SCRABBLE_ALPHABET.sample }
    end
    letters
  end

  def run_game(word, letters, start_time, end_time)
    time = (end_time - start_time).round(2)

    return { time: time, score: 0, message: MESSAGE[:invalid] } unless word.upcase.chars.all? do |letter|
      letters.count(letter) >= word.upcase.count(letter) && letters.include?(letter)
    end

    word_validation = JSON.parse(URI.open("https://wagon-dictionary.herokuapp.com/#{word}").read)
    return { time: time, score: 0, message: MESSAGE[:valid_not_found] } unless word_validation['found']

    score = (word_validation['length'] * (1600 / letters.length)) / time
    { time: time, score: score.floor, message: MESSAGE[:valid_found] }
  end
end
