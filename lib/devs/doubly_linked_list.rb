module DEVS
  class DoublyLinkedList
    include Enumerable

    attr_reader :size, :head, :tail

    class Node
      attr_accessor :value, :previous, :next
      def initialize(v=nil, p=nil, n=nil)
        @value = v
        @previous = p
        @next = n
      end
    end

    def initialize(size = 0)
      @head = @tail = nil
      @size = 0

      if block_given? && size > 0
        i = 0
        while i < size
          self << yield(i)
          i += 1
        end
      end
    end

    def inspect
      "<#{self.class}: size=#{@size}, head=#{@head}, tail=#{@tail}>"
    end

    def clear
      @head = @tail = nil
      @size = 0
    end

    def empty?
      @size == 0
    end

    # Append (O(1)) — Pushes the given object on to the end of this list.
    #
    # See also {#pop} for the opposite effect.
    #
    # @return [Node] the newly created node wrapping the given object
    def <<(obj)
      node = Node.new(obj)
      if @head == nil
        @head = @tail = node
      else
        node.previous = @tail
        @tail.next = node
        @tail = node
      end
      @size += 1
      node
    end
    alias_method :push, :<<

    def push_node(node)
      if @head == nil
        @head = @tail = node
      else
        node.previous = @tail
        @tail.next = node
        @tail = node
      end
      @size += 1
      self
    end

    # Append (0(1)) - Pushes the given object(s) on to the beginning of this
    # list.
    #
    # See also {#take} for the opposite effect.
    #
    # @return [Node] the newly created node wrapping the given object
    def push_front(obj)
      node = Node.new(obj)
      if @head == nil
        @head = @tail = node
      else
        node.next = @head
        @head.previous = node
        @head = node
      end
      @size += 1
      node
    end

    def push_node_front(node)
      if @head == nil
        @head = @tail = node
      else
        node.next = @head
        @head.previous = node
        @head = node
      end
      @size += 1
      self
    end

    # Removes (O(1)) the first element from self and returns it, or nil if the
    # list is empty.
    #
    # See also {#push_front} for the opposite effect
    #
    # @return [Node] the node wrapping the first element
    def shift
      return nil if @size == 0
      item = @head
      if @head == @tail
        @head = nil
        @tail = nil
      else
        @head = @head.next
        @head.previous = nil
      end
      @size -= 1
      item.next = nil
      item
    end

    # Removes (O(1)) the last element from self and returns it, or nil if the
    # list is empty.
    #
    # See also {#push} for the opposite effect.
    #
    # @return [Node] the node wrapping the first element
    def pop
      return nil if @size == 0
      item = @tail
      if @tail == @head
        @tail = @head = nil
      else
        @tail = @tail.previous
        @tail.next = nil
      end
      @size -= 1
      item.previous = nil
      item
    end

    # Deletes (O(1)) the given node from <tt>self</tt>.
    def delete(node)
      if node == @head && node == @tail
        @head = @tail = nil
      elsif node == @head
        n = node.next
        @head = n
      elsif node == @tail
        p = node.previous
        @tail = p
      else
        p = node.previous
        n = node.next
        p.next = n
        n.previous = p
      end
      @size -= 1
      node.previous = node.next = nil
      node
    end

    # Returns the first node from self that is equal to obj, or nil if no
    # matching item is found.
    #
    # @return [Node, nil] the matching node, or nil
    def search(obj)
      n = @head
      while n && obj != n.value
        n = n.next
      end
      n
    end

    def concat(list)
      if list.is_a?(LinkedList)
        n = list.head
        while n
         self << n.value
         n = n.next
        end
      elsif list.is_a?(Array)
        i = 0
        while i < list.size
          self << list[i]
          i += 1
        end
      else
        list.each { |v| self << v }
      end
      self
    end

    # Inserts (O(1)) the given object before the element with the given node.
    #
    # @return [Node] the newly created node wrapping the given element
    def insert_before(node, obj)
      new_node = Node.new(obj)
      if node == @head
        node.next = new_node
        new_node.previous = node
        @head = new_node
      else
        previous = node.previous
        previous.next = new_node
        new_node.previous = previous
        new_node.next = node
        node.previous = new_node
      end
      @size += 1
      new_node
    end

    # Inserts (O(1)) the given object after the element with the given node.
    #
    # @return [Node] the newly created node wrapping the given element
    def insert_after(node, obj)
      new_node = Node.new(obj)
      if node == @tail
        node.next = new_node
        new_node.previous = node
        @tail = new_node
      else
        nnext = node.next
        nnext.previous = new_node
        new_node.next = nnext
        new_node.previous = node
        node.next = new_node
      end
      @size += 1
      new_node
    end

    # Returns the first element of the list, or nil if the list is empty
    #
    # @return [Node] the node wrapping the first element
    def first
      @head
    end

    # Returns the last element of the list, or nil if the list is empty
    #
    # @return [Node] the node wrapping the first element
    def last
      @tail
    end

    # Calls the given block once for each element in <tt>self</tt>, passing that
    # element as a parameter.
    def each
      return enum_for(:each) unless block_given?
      n = @head
      while n
        yield n.value
        n = n.next
      end
    end

    # Calls the given block once for each node in <tt>self</tt>, passing that
    # element as a parameter.
    def each_node
      return enum_for(:each_node) unless block_given?
      n = @head
      while n
        yield n
        n = n.next
      end
    end
  end
end
