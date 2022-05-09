require 'open-uri'

class GamesController < ApplicationController
  def new
    @letters = generate_letter_grid(10)
  end

  def score
    @end_time = Time.now
    @start_time = params[:start_time].to_datetime
    @total_time = (@end_time - @start_time).round(2)

    @word = params[:input]
    @letters = params[:letters]

    @json = JSON.parse(URI.open("https://wagon-dictionary.herokuapp.com/#{@word}").read)

    @result = run_game
    @total_score = total_score
  end

  private

  def generate_letter_grid(grid_size, letters = [])
    until enough_vowels?(letters) && enough_consonants?(letters, grid_size)
      letters = []
      grid_size.times { letters << SCRABBLE_ALPHABET.sample }
    end
    letters
  end

  def run_game
    return { time: @total_time, score: 0, message: MESSAGE[:invalid] } unless valid?

    return { time: @total_time, score: 0, message: MESSAGE[:valid_not_found] } unless @json['found']

    score = (@json['length'] * (1600 / @letters.length)) / @total_time
    { time: @total_time, score: score.floor, message: MESSAGE[:valid_found] }
  end

  def total_score
    session[:score] = 0 if session[:score].nil?
    session[:score] += @result[:score]
  end

  def valid?
    @word.upcase.chars.all? do |letter|
      @letters.count(letter) >= @word.upcase.count(letter) && @letters.include?(letter)
    end
  end

  def enough_vowels?(letters)
    letters.any? { |letter| VOWELS.include?(letter) }
  end

  def enough_consonants?(letters, grid_size)
    VOWELS.map { |letter| letters.count(letter) }.reduce(:+) <= (grid_size / 2)
  end

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

  MESSAGE = {
    invalid: 'The word you entered is not a valid answer - Try again!',
    valid_not_found: 'Uh-oh, it seems that the word you entered is not an English word - Try again!',
    valid_found: 'Good job!'
  }.freeze
end
