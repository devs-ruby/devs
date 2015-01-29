require 'bundler/setup'
require 'codeclimate-test-reporter'

class Ev
  attr_accessor :time_next
  def initialize(tn)
    @time_next = tn
  end
end

CodeClimate::TestReporter.start
