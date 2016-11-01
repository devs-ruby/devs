require "spec_helper"

class Ev
  attr_accessor :time_next

  def initialize(tn)
    @time_next = tn
  end
end

describe "Event sets" do
  let(:cq) { CalendarQueue.new }
  let(:lq) { LadderQueue.new }
  let(:st) { SplayTree.new }
  let(:bh) { BinaryHeap.new }

  let(:eventsets) { [cq,lq,st,bh] }

  ["(CalendarQueue)","(LadderQueue)","(SplayTree)","(BinaryHeap)"].each_with_index do |it_key,pes_index|

    describe "empty state" do
      describe "size should be zero" do
        it(it_key) do
          pes = eventsets[pes_index]

          pes.size.must_equal 0
          pes.must_be :empty?
        end
      end
    end

    describe "does clear" do
      it(it_key) do
        pes = eventsets[pes_index]

        3.times { |i| pes.push(Ev.new(i)) }
        pes.clear
        pes.size.must_equal 0
      end
    end

    describe "priorities elements" do
      it(it_key) do
        pes = eventsets[pes_index]

        events = [ Ev.new(2), Ev.new(12), Ev.new(257) ]
        events.each { |e| pes.push(e) }

        pes.pop.time_next.must_equal(2)

        pes.push(Ev.new(0))

        pes.pop.time_next.must_equal(0)
        pes.pop.time_next.must_equal(12)
        pes.pop.time_next.must_equal(257)
      end
    end

    describe "peeks lowest priority" do
      it(it_key) do
        pes = eventsets[pes_index]

        n = 30
        (0...n).map { |i| Ev.new(i) }.shuffle.each { |e| pes.push(e) }
        pes.peek.time_next.must_equal(0)
      end
    end

    describe "deletes" do
      it(it_key) do
        pes = eventsets[pes_index]

        events = [ Ev.new(2), Ev.new(12), Ev.new(257) ]
        events.each { |e| pes.push(e) }

        ev = pes.delete(events[1])

        ev.wont_be_nil
        ev.time_next.must_equal 12
      end
    end

    describe "adjust" do
      it(it_key) do
        pes = eventsets[pes_index]

        events = [ Ev.new(2), Ev.new(12), Ev.new(257) ]
        events.each { |e| pes.push(e) }

        ev = pes.delete(events[1])

        ev.wont_be_nil
        ev.time_next.must_equal(12)

        ev.time_next = 0
        pes.push(ev)

        pes.peek.time_next.must_equal(0)
      end
    end

    describe "passes pdevs test" do
      n = 500
      steps = 200
      max_reschedules = 30

      it(it_key) do
        pes = eventsets[pes_index]

        events = []
        n.times do
          ev = Ev.new(rand(0..n))
          events << ev
          pes << ev
        end

        pes.size.must_equal(n)

        steps.times do
          prio = pes.peek.try(:time_next) || INFINITY
          imm = pes.pop_simultaneous

          imm.each do |ev|
            ev.time_next.must_equal(prio)
            ev.time_next += rand(0..n)
            pes.push(ev)
          end

          rand(max_reschedules).times do
            ev = events[rand(events.size)]
            c = pes.delete(ev)

            c.wont_be_nil
            ev.must_be_same_as(c)
            ev.time_next.must_equal(c.time_next)

            ev.time_next += rand(0..n)
            pes.push(ev)
          end
        end
      end
    end

  end
end
