require 'devs/schedulers/binary_heap'
require 'devs/schedulers/ladder_queue'
require 'devs/schedulers/splay_tree'
require 'devs/schedulers/calendar_queue'
require 'devs/schedulers/sorted_list'
require 'devs/schedulers/minimal_list'

module DEVS
  class << self
    attr_accessor :scheduler
  end
  @scheduler = LadderQueue
end
