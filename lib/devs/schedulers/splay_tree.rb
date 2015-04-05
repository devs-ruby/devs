module DEVS
  class SplayTree
    class Node
      attr_accessor :value, :left, :right, :parent
      def initialize(v, l=nil, r=nil, p=nil)
        @value = v
        @left = l
        @right = r
        @parent = p
      end
    end

    attr_reader :size

    def initialize(elements = nil)
      @size = 0
      if elements
        i = 0
        while i < elements.size
          self << elements[i]
          i += 1
        end
      end
    end

    def empty?
      @size == 0
    end

    def <<(obj)
      z = @root
      p = nil
      tn = obj.time_next

      while z
        p = z
        if z.value.time_next < tn
          z = z.right
        else
          z = z.left
        end
      end

      z = Node.new(obj)
      z.parent = p

      if p == nil
        @root = z
      elsif p.value.time_next < z.value.time_next
        p.right = z
      else
        p.left = z
      end

      splay(z)
      @size += 1
    end
    alias_method :push, :<<
    alias_method :enqueue, :<<

    def find(obj)
      z = @root
      tn = obj.time_next
      while z
        if z.value.time_next < tn
          z = z.right
        elsif z.value.time_next > tn
          z = z.left
        else
          if z.value.equal?(obj)
            return z
          else
            return search_tree(obj)
          end
        end
      end
      nil
    end

    def delete(obj)
      z = obj.is_a?(Node) ? obj : find(obj)
      return nil unless z

      splay(z)

      if z.left == nil
        replace(z, z.right)
      elsif z.right == nil
        replace(z, z.left)
      else
        y = subtree_min(z.right)
        if y.parent != z
          replace(y, y.right)
          y.right = z.right
          y.right.parent = y
        end
        replace(z, y)
        y.left = z.left
        y.left.parent = y
      end
      @size -= 1
      z.value
    end

    def peek
      return nil if @size == 0
      subtree_min(@root).value
    end
    alias_method :find_min, :peek

    def find_max
      return nil if @size == 0
      subtree_max(@root).value
    end

    def pop
      return nil if @size == 0
      delete(subtree_min(@root))
    end
    alias_method :dequeue, :pop

    def pop_simultaneous
      a = []
      if @size > 0
        time = self.peek.time_next
        a << self.pop while @size > 0 && self.peek.time_next == time
      end
      a
    end
    alias_method :dequeue_simultaneous, :pop_simultaneous

    private

    def search_tree(obj)
      ary = []
      return @root if @root.value.equal?(obj)
      ary << @root.left if @root.left
      ary << @root.right if @root.right

      i = 0
      while i < ary.size
        x = ary[i]
        if x.value.equal?(obj)
          return x
        else
          ary << x.left if x.left
          ary << x.right if x.right
        end
        i += 1
      end
    end

    def left_rotate(x)
      y = x.right
      if y
        x.right = y.left
        y.left.parent = x if y.left
        y.parent = x.parent
      end

      if x.parent == nil
        @root = y
      elsif x == x.parent.left
        x.parent.left = y
      else
        x.parent.right = y
      end

      y.left = x if y
      x.parent = y
    end

    def right_rotate(x)
      y = x.left
      if y
        x.left = y.right
        y.right.parent = x if y.right
        y.parent = x.parent
      end

      if x.parent == nil
        @root = y
      elsif x == x.parent.left
        x.parent.left = y
      else
        x.parent.right = y
      end

      y.right = x if y
      x.parent = y
    end

    def splay(x)
      while x.parent
        if x.parent.parent == nil
          if x.parent.left == x
            right_rotate(x.parent)
          else
            left_rotate(x.parent)
          end
        elsif x.parent.left == x && x.parent.parent.left == x.parent
          right_rotate(x.parent.parent)
          right_rotate(x.parent)
        elsif x.parent.right == x && x.parent.parent.right == x.parent
          left_rotate(x.parent.parent)
          left_rotate(x.parent)
        elsif x.parent.left == x && x.parent.parent.right == x.parent
          right_rotate(x.parent)
          left_rotate(x.parent)
        else
          left_rotate(x.parent)
          right_rotate(x.parent)
        end
      end
    end

    def replace(u, v)
      if u.parent == nil
        @root = v
      elsif u == u.parent.left
        u.parent.left = v
      else
        u.parent.right = v
      end
      v.parent = u.parent if v
    end

    def subtree_min(u)
      u = u.left while u.left
      u
    end

    def subtree_max(u)
      u = u.right while u.right
      u
    end
  end
end
