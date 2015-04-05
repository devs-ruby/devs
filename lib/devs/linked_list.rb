module DEVS
  class LinkedList
    include Enumerable

    attr_reader :size, :head

    class Node
      attr_accessor :value, :next
      def initialize(v=nil, n=nil)
        @value = v
        @next = n
      end
    end

    def initialize(size = 0)
      @head = nil
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
      "<#{self.class}: size=#{@size}, head=#{@head}>"
    end

    def clear
      @head = nil
      @size = 0
    end

    def empty?
      @size == 0
    end

    # Append (0(1)) - Pushes the given object(s) on to the beginning of this
    # list.
    #
    # See also {#pop} for the opposite effect.
    #
    # @return [Node] the newly created node wrapping the given object
    def <<(obj)
      node = Node.new(obj, @head)
      @head = node
      @size += 1
      node
    end
    alias_method :push, :<<
    alias_method :push_front, :<<

    def push_node(node)
      node.next = @head
      @head = node
      @size += 1
      self
    end
    alias_method :push_front_node, :push_node

    # Removes (O(1)) the first element from self and returns it, or nil if the
    # list is empty.
    #
    # See also {#push} for the opposite effect
    #
    # @return [Node] the node wrapping the first element
    def pop
      return nil if @size == 0
      item = @head
      @head = @head.next
      @size -= 1
      item.next = nil
      item
    end
    alias_method :shift, :pop

    def concat(list)
      if list.is_a?(LinkedList)
        n = list.head
        if n
          self << n.value
          while n.next
            insert_after(n, n.next.value)
            n = n.next
          end
        end
      elsif list.is_a?(Array)
        i = list.size-1
        while i >= 0
          self << list[i]
          i -= 1
        end
      else
        list.reverse_each { |v| self << v }
      end
      self
    end

    # Inserts (O(1)) the given object after the element with the given node.
    #
    # @return [Node] the newly created node wrapping the given element
    def insert_after(node, obj)
      new_node = Node.new(obj, node.next)
      node.next = new_node
      @size += 1
      new_node
    end

    # Inserts (O(1)) the given node after the element with the given node.
    #
    # @return [Node] the inserted node
    def insert_node_after(node, new_node)
      new_node.next = node.next
      node.next = new_node
      @size += 1
      new_node
    end

    # Deletes (O(1)) the node after the given node from <tt>self</tt>.
    def delete_node_after(node)
      deleted = node.next
      if deleted
        node.next = deleted.next
        deleted.next = nil
        @size -= 1
      end
      deleted
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

    # Returns the first element of the list, or nil if the list is empty
    #
    # @return [Node] the node wrapping the first element
    def first
      @head
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
