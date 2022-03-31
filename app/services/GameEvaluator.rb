# frozen_string_literal: true

require 'matrix'

# Handles the game logic and victory determination
# Params:
# players: Iterable of bots
class GameEvaluator
  TIE = -1
  CONTINUE = 0
  WON = 1

  def initialize(players:)
    @players = players
    @game = players.first.game
    @nets = players.map { |player| NeuralNet.new(player) }
    @player_ids = players.map(&:id)
    @game_array = Matrix.zero(game.height, game.width)
    @col_tracker = Array.new(@game.width, 0)
  end

  def play
    # Flip a coin to see who goes first
    turn_index = rand.round

    (game.height * game.width).times do |turn|
      net_value = nets[turn_index].getValue(game_array)
      result = playPiece(player: player_ids[turn_index], column: net_value)
      return result unless result[:gameState] == CONTINUE
      turn_index = (turn_index + 1) % 2
    end
  end

  def playPiece(player_id:, column:)
    validatePlayer(player_id)
    raise StandardError.new("Column #{column} is full") if (col_tracker[column] + 1) > (game_array.row_count - 1)

    # TODO: Allow multiple players to play
    if player == players[0]
      game_array[col_tracker[column], column] = 1
    else
      game_array[col_tracker[column], column] = -1
    end
    col_tracker[column] += 1
    
    # If the gamearray is full and no one's won its a tie
    if col_tracker.uniq == [game_array.row_count - 1]
      { gameState: TIE }
    else
      result = checkVictory(row: col_tracker[column], column: column)
      if result
        { gameState: WON, playerId: result }
      else
        { gameState: CONTINUE }
      end
    end
  end

  # Get the game state from the perspective of player
  # 1 = your pieces
  # -1 = enemy pieces
  def getGameState(player_id)
    validatePlayer(player_id)
    # TODO: more comprehensive converter capable of handling multiple players
    if player == players[0]
      game_array
    else
      game_array * -1
    end
  end

  private
    attr_reader :players, :player_ids, :game, :nets
    attr_accessor :col_tracker, :game_array

    def checkVictory(row:, column:)
      raise StandardError.new("No player token") if game_array[height, width] == 0
      playerId = game_array[row, column]
      # Vertical
      checkDirections(row: row, column: column, vertical: 1)  ||
      # Horizontal
      checkDirections(row: row, column: column, horizontal: 1) ||
      # Diagonal NE - SW
      checkDirections(row: row, column: column, horizontal: 1, vertical: 1) ||
      # Diagonal SE - NW
      checkDirections(row: row, column: column, horizontal: 1, vertical: -1)
    end

    def checkDirections(row:, column:, horizontal:0, vertical:0)
      first = checkDirection(row: row, column: column, horizontal: horizontal, vertical: vertical)
      second = checkDirection(row: row, column: column, horizontal: horizontal * -1, vertical: vertical * -1, count: 3-north)
      if north + south >= 3
        return playerId
      else
        nil
      end
    end

    # Horizontal -1 (West), 1 (East)
    # Vertical -1 (South), 1 (North)
    def checkDirection(row:, column:, horizontal:0, vertical:0, count: 4)
      playerId = game_array[row, column]
      playerDirection = 0
      count.times do |n|
        if game_array[row + n*vertical, column + n*horizontal] == playerId
          playerDirection += 1
        else
          return playerDirection
        end
      end

      playerDirection
    end

    def validatePlayer(player_id)
      raise ArgumentError.new("Bot ID must be in #{player_ids}") unless player_id.in?(player_ids)
    end
end