module VSql
  module Helpers
    def self.find_elements(node, klass, skip_klass = nil)
      results = []
      return results unless node.elements
      node.elements.each do |e|
        case
        when e.is_a?(klass)
          results << e
          results.concat(find_elements(e, klass, skip_klass))
        when skip_klass && e.is_a?(skip_klass)
          next
        else
          results.concat(find_elements(e, klass, skip_klass))
        end
      end
      results
    end
  end

  class VSqlSyntaxNode < Treetop::Runtime::SyntaxNode
    def match(klass)
      Helpers.find_elements(self, klass)
    end

    def find(klass)
      match(klass).first
    end
  end

  class Operator < VSqlSyntaxNode
  end

  class Statement < VSqlSyntaxNode
  end

  class SelectStatement < VSqlSyntaxNode
    def expressions
      Helpers.find_elements(self, SelectExpression)
    end
  end

  class SelectExpression < VSqlSyntaxNode
    def expression_sql
    end

    def alias_node
      @alias_node ||= Helpers.find_elements(self, Alias, Query).first
    end

    def root_nodes
      elements[0].elements.select { |e| ! e.text_value.empty? }
    end

    def name
      case
      when alias_node
        alias_node.text_value
      when root_nodes.length == 1 && root_nodes.first.is_a?(Function)
        root_nodes.first.name
      when root_nodes.length == 1 && root_nodes.first.is_a?(FieldRef)
        element =
          Helpers.find_elements(self, FieldGlob).last ||
          Helpers.find_elements(self, Name).last
        element.text_value
      else "?column?"
      end
    end
  end

  class NameExpression < VSqlSyntaxNode
  end

  class FromExpression < VSqlSyntaxNode
  end

  class Name < VSqlSyntaxNode
  end

  class FieldRef < VSqlSyntaxNode
  end

  class TablePart < VSqlSyntaxNode
  end

  class FieldGlob < VSqlSyntaxNode
  end

  class Alias < VSqlSyntaxNode
  end

  class Function < VSqlSyntaxNode
    def name
      elements[0].text_value
    end
  end

  class Entity < VSqlSyntaxNode
    # def to_array
    #   return self.elements[0].to_array
    # end
  end

  class QuotedEntity < Entity
  end

  class Query < VSqlSyntaxNode
    # def to_array
    #   return self.elements.map {|x| x.to_array}
    # end
    # def select_statement
    #   elements.detect { |e| e.is_a?(SelectStatement) }
    # end
  end

  class SubQuery < VSqlSyntaxNode
  end
end
