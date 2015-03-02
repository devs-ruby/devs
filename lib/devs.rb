require 'set'
require 'logger'
require 'observer'

# @author Romain Franceschini <franceschini.romain@gmail.com>
module DEVS
  INFINITY = Float::INFINITY
end

require 'devs/version'
require 'devs/logging'
require 'devs/errors'
require 'devs/linked_list'
require 'devs/core_ext'
require 'devs/message'
require 'devs/coupling'
require 'devs/port'
require 'devs/model'
require 'devs/atomic_model'
require 'devs/coupled_model'
require 'devs/processor'
require 'devs/simulator'
require 'devs/coordinator'
require 'devs/schedulers'
require 'devs/simulation'
require 'devs/builders'
require 'devs/hooks'
require 'devs/parallel'
require 'devs/classic'

module DEVS
  # Builds a simulation
  #
  # @param opts [Hash] the configuration hash
  # @example
  #   simulation = DEVS.build do
  #     duration = 200
  #     # ...
  #   end
  #   simulation.simulate
  def build(opts={}, &block)
    builder = SimulationBuilder.new(opts, &block)
    builder.build
  end
  module_function :build

  # Builds a simulation
  #
  # @param opts [Hash] the configuration hash
  # @example
  #   DEVS.simulate do
  #     duration = 200
  #     # ...
  #   end
  def simulate(opts={}, &block)
    build(opts, &block).simulate
  end
  module_function :simulate

  # Returns the current version of the gem
  #
  # @return [String] the string representation of the version
  def version
    VERSION
  end
  module_function :version
end
