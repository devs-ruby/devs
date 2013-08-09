module DEVS
  # This class represent the processor on top of the simulation tree,
  # responsible for coordinating the simulation
  class RootCoordinator
    # used for hooks
    include Observable
    include Logging

    attr_accessor :duration

    # The default duration of the simulation if argument omitted
    DEFAULT_DURATION = 60

    attr_reader :time, :duration, :child, :start_time, :final_time

    alias_method :clock, :time

    # @!attribute [r] time
    #   @return [Numeric] Returns the current simulation time

    # @!attribute [r] start_time
    #   @return [Time] Returns the time at which the simulation started

    # @!attribute [r] duration
    #   @return [Numeric] Returns the total duration of the simulation time

    # @!attribute [r] child
    #   Returns the coordinator which <tt>self</tt> is managing.
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
    end

    # Returns <tt>true</tt> if the simulation is done, <tt>false</tt> otherwise.
    #
    # @return [Boolean]
    def done?
      @time >= @duration
    end

    # Returns <tt>true</tt> if the simulation is currently running,
    #   <tt>false</tt> otherwise.
    #
    # @return [Boolean]
    def running?
      defined?(@start_time) && !done?
    end

    # Returns <tt>true</tt> if the simulation is waiting to be started,
    #   <tt>false</tt> otherwise.
    #
    # @return [Boolean]
    def waiting?
      !defined?(@start_time)
    end

    # Returns the number of messages per model along with the total
    #
    # @return [Hash<Symbol, Fixnum>]
    def stats
      unless waiting?
        stats = child.stats
        total = Hash.new(0)
        stats.values.each { |h| h.each { |k, v| total[k] += v }}
        stats[:TOTAL] = total
        stats
      end
    end

    # Run the simulation
    def simulate
      @start_time = Time.now
      info "*** Beginning simulation at #{@start_time} with duration: #{@duration}"

      # root coordinator strategy
      run

      @final_time = Time.now
      info "*** Simulation ended at #{@final_time} after #{@final_time - @start_time} secs."

      info "* Events stats : {"
      stats.each { |k, v| info "    #{k} => #{v}" }
      info "* }"

      info "* Calling post simulation hooks"
      changed
      notify_observers(:post_simulation)

      self
    end

    private
    attr_writer :time
  end
end
