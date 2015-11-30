module DEVS
  # This class represent the interface to the simulation
  class Simulation
    include Logging
    include Enumerable

    attr_reader :duration, :start_time, :final_time, :time, :processor,
                :build_start_time, :build_end_time, :build_elapsed_secs

    # @!attribute [r] time
    #   @return [Numeric] Returns the current simulation time

    # @!attribute [r] start_time
    #   @return [Time] Returns the time at which the simulation started

    # @!attribute [rw] duration
    #   @return [Numeric] Returns the total duration of the simulation time

    # @!attribute [r] init_time
    #   @return [Numeric] Returns the duration of the initialization

    # Returns a new {Simulation} instance.
    #
    # @param child [Coordinator] the child coordinator
    # @param strategy [Module] the strategy responding ro run
    # @param duration [Numeric] the duration of the simulation
    # @raise [ArgumentError] if the child is not a coordinator
    def initialize(processor, duration, build_start_time)
      @duration = duration
      @time = 0
      @processor = processor
      @lock = Mutex.new
      @build_start_time = build_start_time
      @build_end_time = Time.now
      @build_elapsed_secs = @build_end_time - @build_start_time
      info "*** Builded simulation at #{@build_end_time} after #{@build_elapsed_secs} secs." if DEVS.logger
    end

    def inspect
      "<#{self.class}: status=\"#{status}\", time=#{time}, duration=#{@duration}>"
    end

    def time
      @lock.lock
      t = @time
      @lock.unlock
      t
    end
    alias_method :clock, :time

    def duration
      @lock.lock
      d = @duration
      @lock.unlock
      d
    end

    def duration=(v)
      @lock.lock
      @duration = v
      @lock.unlock
      v
    end

    def start_time
      @lock.synchronize { @start_time }
    end

    def final_time
      @lock.synchronize { @final_time }
    end

    # Returns <tt>true</tt> if the simulation is done, <tt>false</tt> otherwise.
    #
    # @return [Boolean]
    def done?
      @lock.synchronize { @time >= @duration }
    end

    # Returns <tt>true</tt> if the simulation is currently running,
    #   <tt>false</tt> otherwise.
    #
    # @return [Boolean]
    def running?
      @lock.synchronize { defined?(@start_time) } && !done?
    end

    # Returns <tt>true</tt> if the simulation is waiting to be started,
    #   <tt>false</tt> otherwise.
    #
    # @return [Boolean]
    def waiting?
      @lock.synchronize { !defined?(@start_time) }
    end

    # Returns the simulation status: <tt>waiting</tt>, <tt>running</tt> or
    #   <tt>done</tt>.
    #
    # @return [Symbol] the simulation status
    def status
      if waiting?
        :waiting
      elsif running?
        :running
      elsif done?
        :done
      end
    end

    def percentage
      case status
      when :waiting then 0.0 * 100
      when :done    then 1.0 * 100
      when :running
        @lock.lock
        val = if @time > @duration
          1.0 * 100
        else
          @time.to_f / @duration.to_f * 100
        end
        @lock.unlock
        val
      end
    end

    def elapsed_secs
      case status
      when :waiting
        0.0
      when :done
        @lock.lock
        t = @final_time - @start_time
        @lock.unlock
        t
      when :running
        Time.now - self.start_time
      end
    end

    # Returns the number of transitions per model along with the total
    #
    # @return [Hash<Symbol, Fixnum>]
    def transition_stats
      if done?
        @transition_stats ||= (
          stats = {}
          hierarchy = @processor.children.dup
          i = 0
          while i < hierarchy.size
            child = hierarchy[i]
            if child.model.coupled?
              hierarchy.concat(child.children)
            else
              stats[child.model.name] = child.transition_stats
            end
            i+=1
          end
          total = Hash.new(0)
          stats.values.each { |h| h.each { |k, v| total[k] += v }}
          stats[:TOTAL] = total
          stats
        )
      end
    end

    # Run the simulation in a new thread
    def simulate
      if waiting?
        start_time = begin_simulation
        self.time = @processor.initialize_state(self.time)
        while self.time < self.duration
          debug "* Tick at: #{self.time}, #{Time.now - start_time} secs elapsed" if DEVS.logger && DEVS.logger.debug?
          self.time = @processor.step(self.time)
        end
        end_simulation
      else
        if running?
          error "The simulation already started at #{self.start_time} and is currently running."
        else
          error "The simulation is already done. Started at #{self.start_time} and finished at #{self.final_time} in #{elapsed_secs} secs."
        end if DEVS.logger
      end
      self
    end

    def each(&block)
      if waiting?
        if block_given?
          start_time = begin_simulation
          self.time = @processor.initialize_state(self.time)
          while time < self.duration
            debug "* Tick at: #{self.time}, #{Time.now - start_time} secs elapsed" if DEVS.logger && DEVS.logger.debug?
            self.time = @processor.step(self.time)
            yield(self)
          end
          end_simulation
        else
          return enum_for(:each, &block)
        end
      elsif DEVS.logger
        if running?
          error "The simulation already started at #{self.start_time} and is currently running."
        else
          error "The simulation is already done. Started at #{self.start_time} and finished at #{self.final_time} in #{elapsed_secs} secs."
        end
        nil
      end
    end

    private
    def time=(v)
      @lock.lock
      @time = v
      @lock.unlock
      v
    end

    def begin_simulation
      t = Time.now
      @lock.lock
      @start_time = t
      info "*** Beginning simulation at #{@start_time} with duration: #{@duration}" if DEVS.logger
      @lock.unlock
      t
    end

    def end_simulation
      final_time = Time.now
      @lock.lock
      @final_time = final_time
      @lock.unlock

      if DEVS.logger
        info "*** Simulation ended at #{final_time} after #{elapsed_secs} secs."
        debug "* Transition stats : {"
        transition_stats.each { |k, v| debug "    #{k} => #{v}" }
        debug "* }"
        debug "* Running post simulation hook"
      end

      Hooks.notifier.publish(:post_simulation_hook)
    end
  end
end
