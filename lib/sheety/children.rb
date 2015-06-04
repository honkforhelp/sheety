module Sheety::Children
  def self.included base
    base.extend ClassMethods
  end

  def _passes_constraint(i_val, c_val)
    case c_val # Good Read: http://ruby.about.com/od/beginningruby/qt/On-Case-And-Class.htm
      when Range
        c_val.include? i_val
      when Array
        c_val.include? i_val
      when Regexp
        c_val =~ i_val
      when String
        c_val == i_val.to_s
      else
        c_val == i_val
    end
  end

  def _get_i_val(item, c_key, accessor=nil)
    if accessor && item.respond_to?(accessor)
      return item.send(accessor, c_key)
    else
      return item.try(c_key)
    end
  end

  module ClassMethods
    def atom_children(symbol, options)

      if options.blank?
        raise ArgumentError.new("blank options #{options} are not valid options for bear_children")
      end

      if options[:klass].blank? || options[:klass].class != Class
        raise ArgumentError.new("#{options} must have a :klass that is a Class, not a #{options[:klass].class}")
      end

      if options[:link].blank?
        raise ArgumentError.new("#{options} must have a non-blank :link")
      end

      unless method_defined?(:link)
        raise TypeError.new("#{self} must respond to :link to bear_children")
      end

      if options[:merge_links] && method_defined?(:add_links) == false
        raise TypeError.new("#{self} must respond to :add_links to bear_children with mrege_links=true")
      end

      plural = symbol.to_s
      singular = plural.singularize

      inst_var_sym = :"@#{symbol}"

      get_method = :"#{plural}"
      new_method = :"new_#{singular}"
      enum_method = :"_enumerate_#{plural}_by_method"
      where_method = :"#{plural}_where"
      except_method = :"#{plural}_except"
      except_any_method = :"#{plural}_except_any"
      find_first_method = :"find_#{singular}"

      define_method(new_method) do |entry=nil|
        options[:klass].new(self, entry)
      end

      define_method(get_method) do |force_refetch=false|
        if instance_variable_get(inst_var_sym).nil? || force_refetch
          list = Sheety::Api.inst.get_feed(link(options[:link])) # sort of a cyclic dependency, suboptimal

          # TODO: Create a ListFeed Object so the links we get here don't need to be worried about collisions on link ids
          add_links(list['link']) if !list['link'].blank? && options[:merge_links]

          list = (list['entry'] || []).map do |entry|
            method(new_method).call(entry)
          end

          instance_variable_set(inst_var_sym, list)
        end

        return instance_variable_get(inst_var_sym)
      end

      define_method(enum_method) do |constraints, method|
        return method(get_method).call().send(method) do |item|
          constraints.all? do |constraint|
            _passes_constraint(_get_i_val(item, constraint[0], options[:accessor]), constraint[1])
          end
        end
      end

      define_method(where_method) do |constraints|
        return method(enum_method).call(constraints, :find_all)
      end

      define_method(find_first_method) do |constraints|
        return method(enum_method).call(constraints, :detect)
      end

      define_method(except_method) do |constraints|
        return method(enum_method).call(constraints, :reject)
      end

      define_method(except_any_method) do |constraints|
        return method(get_method).call().reject do |item|
          constraints.any? do |constraint|
            _passes_constraint(_get_i_val(item, constraint[0], options[:accessor]), constraint[1])
          end
        end
      end
    end
  end
end