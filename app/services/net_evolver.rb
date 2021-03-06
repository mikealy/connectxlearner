# frozen_string_literal: true

require 'benchmark'

# Evolves a bot over time by running it through game iterations
# Params:
# bot:                bot
# iterations:         int
# gamesPerIteration:  int
# NetEvolver.new(bot: Bot.last, iterations: 50).call
class NetEvolver
  def initialize(bot:, iterations:)
    @bot = bot
    @base_net = NeuralNet.new(bot: bot)
    @iterations = iterations
  end

  # Create N slightly randomized versions of the original bot
  # Play games against each other (and the original) round robin
  # promote the best performer to the next version

  def call
    n = 0.0
    @iterations.times do
      @base_net = evolve
      n += 1
      printf("\rProgress: %f", n / @iterations * 100) if n % (iterations/100) == 0
    end

    @base_net.save_evolved_net
  end

  private

  attr_reader :base_net

  def evolve
    all_nets = [base_net] + get_mutated_nets(4)
    all_nets.map!.with_index { |net, id| { id: id, wins: 0, net: net } }

    # Regular Run

    all_nets.combination(2) do |player_nets|
      game = BotGameEvaluator.new(player_nets: player_nets.pluck(:net))
      winner_id = game.play

      # if winner_id is -1 no one won
      player_nets[winner_id][:wins] += 1 if winner_id >= 0
    end

    # Thread Run

    # puts Benchmark.measure {
    #   threads = []
    #   all_nets.combination(2) do |player_nets|
    #     threads << Thread.new do
    #       winner = BotGameEvaluator.new(player_nets: player_nets.pluck(:net)).play
    #       if winner >= 0
    #         player_nets[winner][:id]
    #       else
    #         -1
    #       end
    #     end
    #   end

    #   threads.map do |t|
    #     t.join
    #     winner = t.value
    #     all_nets[winner][:wins] += 1 if winner >= 0
    #   end
    # }

    # Process Fork run

    # puts Benchmark.measure {
      
    # }

    # return the bot with the max amount of wins
    all_nets.max { |h| h[:wins] }[:net]
  end

  def get_mutated_nets(num_children)
    num_children.times.map { NeuralNet.new(bot: base_net, mutation_weight: 1.0) }
  end
end
