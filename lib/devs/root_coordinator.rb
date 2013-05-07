module DEVS
  # This class represent the processor on top of the simulation tree,
  # responsible for coordinating the simulation
  class RootCoordinator < Simulator
    # used for hooks
    include Observable

    # The default duration of the simulation if argument omitted
    DEFAULT_DURATION = 60

    undef :model, :time_last, :time_next, :parent, :parent=

    attr_reader :time, :duration, :child, :start_time

    alias_method :clock, :time

    # @!attribute [r] time
    #   @return [Fixnum] Returns the current simulation time

    # @!attribute [r] start_time
    #   @return [Time] Returns the time at which the simulation started

    # @!attribute [r] duration
    #   @return [Fixnum] Returns the total duration of the simulation time

    # @!attribute [r] child
    #   Returns the coordinator which <i>self</i> is managing.
    #   @return [Coordinator] Returns the coordinator associated with the
    #     <i>self</i>

    # Returns a new {RootCoordinator} instance.
    #
    # @param child [Coordinator] the child coordinator
    # @param duration [Numeric] the duration of the simulation
    # @raise [ArgumentError] if the child is not a coordinator
    def initialize(child, duration = DEFAULT_DURATION)
      unless child.is_a?(Coordinator)
        raise ArgumentError, 'child must be of Coordinator type'
      end
      @duration = duration
      @time = 0
      @child = child
      @events_count = Hash.new(0)
    end

    # Run the simulation
    def simulate
      @start_time = Time.now
      info "*** Beginning simulation at #{@start_time} with duration:" \
         + "#{@duration}"

      # root coordinator strategy
      run

      msg = "*** Simulation ended after #{Time.now - @start_time} secs."
      DEVS.logger ? info(msg) : puts(msg)

      info "* Events stats :"
      stats = child.stats
      stats[:total] = stats.values.reduce(&:+)
      info "    OVERALL #{stats}"

      info "* Calling post simulation hooks"
      changed
      notify_observers(:post_simulation)
    end

    private
    attr_writer :time
  end
end