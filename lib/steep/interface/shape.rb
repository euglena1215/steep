module Steep
  module Interface
    class Shape
      class Entry
        attr_reader :method_types, :private_method

        def initialize(method_types:, private_method:)
          @method_types = method_types
          @private_method = private_method
        end

        def to_s
          "{ #{method_types.join(" || ")} }"
        end

        def private_method?
          private_method
        end

        def public_method?
          !private_method
        end
      end

      class Methods
        attr_reader :substs, :methods, :resolved_methods

        include Enumerable

        def initialize(substs:, methods:)
          @substs = substs
          @methods = methods
          @resolved_methods = methods.transform_values { nil }
        end

        def key?(name)
          methods.key?(name)
        end

        def []=(name, entry)
          resolved_methods[name] = nil
          methods[name] = entry
        end

        def [](name)
          return nil unless key?(name)

          resolved_methods[name] ||= begin
            entry = methods[name]
            Entry.new(
              method_types: entry.method_types.map do |method_type|
                method_type.subst(subst)
              end,
              private_method: entry.private_method?
            )
          end
        end

        def each(&block)
          if block
            methods.each_key do |name|
              entry = self[name] or raise
              yield [name, entry]
            end
          else
            enum_for :each
          end
        end

        def each_name(&block)
          if block
            methods.each_key(&block)
          else
            enum_for :each_name
          end
        end

        def subst
          @subst ||= begin
            substs.each_with_object(Substitution.empty) do |s, ss|
              ss.merge!(s, overwrite: true)
            end
          end
        end

        def push_substitution(subst)
          Methods.new(substs: [*substs, subst], methods: methods)
        end

        def merge!(other, &block)
          other.each do |name, entry|
            if block && (old_entry = methods[name])
              methods[name] = yield(name, old_entry, entry)
            else
              methods[name] = entry
            end
          end
        end

        def public_methods
          Methods.new(
            substs: substs,
            methods: methods.reject {|_, entry| entry.private_method? }
          )
        end
      end

      attr_reader :type
      attr_reader :methods

      def initialize(type:, private:, methods: nil)
        @type = type
        @private = private
        @methods = methods || Methods.new(substs: [], methods: {})
      end

      def to_s
        "#<#{self.class.name}: type=#{type}, private?=#{@private}, methods={#{methods.each_name.sort.join(", ")}}"
      end

      def update(type: self.type, methods: self.methods)
        _ = self.class.new(type: type, private: private?, methods: methods)
      end

      def subst(s, type: nil)
        ty =
          if type
            type
          else
            self.type.subst(s)
          end

        Shape.new(type: ty, private: private?, methods: methods.push_substitution(s))
      end

      def private?
        @private
      end

      def public?
        !private?
      end

      def public_shape
        if public?
          self
        else
          @public_shape ||= Shape.new(
            type: type,
            private: false,
            methods: methods.public_methods
          )
        end
      end
    end
  end
end
