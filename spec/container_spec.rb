require "spec_helper"
require "coupling_helper"

describe "Coupler" do
  describe "component handling" do
    describe "fetch" do
      it "raises if component doesn't exist" do
        assert_raises NoSuchChildError do
          MyCoupler.new("c")["component"]
        end

        assert_raises NoSuchChildError do
          MyCoupler.new("c").fetch_child("component")
        end
      end

      it "gets nilable" do
        MyCoupler.new("c").fetch_child?("component").must_be_nil
      end
    end
  end

  describe "coupling" do
    describe "attach" do
      it "raises when coupling two ports of same component" do
        coupler = MyCoupler.new("c")
        a = MyCoupleable.new("a")
        coupler.add_child a
        ip = a.add_input_port("in")
        op = a.add_output_port("out")

        assert_raises FeedbackLoopError do
          coupler.attach(op, to: ip)
        end
      end

      it "raises if wrong hosts" do
        coupler1 = MyCoupler.new("c1")
        coupler2 = MyCoupler.new("c2")
        a = MyCoupleable.new "a"
        b = MyCoupleable.new "b"
        coupler1.add_child a
        coupler2.add_child b
        aop = b.add_output_port("out")
        bip = a.add_input_port("in")

        assert_raises InvalidPortHostError do
          coupler1.attach(aop, to: bip)
        end

        assert_raises InvalidPortHostError do
          coupler2.attach(aop, to: bip)
        end

        c1in = coupler1.add_input_port("c1in")
        c1out = coupler1.add_output_port("c1in")

        c2in = coupler2.add_input_port("c2in")
        c2out = coupler2.add_output_port("c2in")

        assert_raises InvalidPortHostError do
          coupler1.attach(c1in, to: c2in)
        end

        assert_raises InvalidPortHostError do
          coupler2.attach(c1out, to: c2in)
        end
      end

      it "raises when coupling ports with wrong IO modes" do
        coupler = MyCoupler.new("c")
        a = MyCoupleable.new("a")
        b = MyCoupleable.new("b")
        coupler << a << b
        myip = coupler.add_input_port("myin")
        myop = coupler.add_output_port("myout")
        aip = a.add_input_port("in")
        bop = b.add_output_port("out")

        # IC
        assert_raises InvalidPortTypeError do
          coupler.attach(aip, to: bop)
        end

        # EOC
        assert_raises InvalidPortTypeError do
          coupler.attach(myop, to: bop)
        end

        # EIC
        assert_raises InvalidPortTypeError do
          coupler.attach(myip, to: bop)
        end

        assert_raises InvalidPortTypeError do
          coupler.attach(bop, to: myip)
        end

        assert_raises InvalidPortTypeError do
          coupler.attach(aip, to: myop)
        end
      end
    end

    describe "detach" do
      coupler = MyCoupler.new("c")
      a = MyCoupleable.new("a")
      b = MyCoupleable.new("b")
      coupler << a << b

      aip = a.add_input_port("in")
      bop = b.add_output_port("out")
      it "detaches IC" do
        coupler.attach(bop, to: aip)
        coupler.detach(bop, from: aip).must_equal true
      end

      myip = coupler.add_input_port("myin")
      it "detaches EIC" do
        coupler.attach(myip, to: aip)
        coupler.detach(myip, from: aip).must_equal true
      end

      myop = coupler.add_output_port("myout")
      it "detaches EOC" do
        coupler.attach(bop, to: myop)
        coupler.detach(bop, from: myop).must_equal true
      end

      it "is falsey when coupling illegal or doesn't exist" do
        coupler.detach(aip, from: bop).must_equal false
        coupler.detach(myop, from: bop).must_equal false
        coupler.detach(myip, from: bop).must_equal false
        coupler.detach(bop, from: myip).must_equal false
        coupler.detach(aip, from: myop).must_equal false

        coupler.attach(bop, to: a.add_input_port("in2"))
        coupler.detach(bop, from: aip).must_equal false
      end
    end

  end
end
