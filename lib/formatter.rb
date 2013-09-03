require_relative "./vsql_node_extensions"

module VSql
  module Formatter
    extend self

    def indent(value, amount = 2, first_line = false)
      spacer = (" " * amount)
      (first_line ? spacer : "") + value.gsub("\n", "\n#{spacer}")
    end
    
    def eager_indent(value, amount = 2)
      indent(value, amount, true)
    end
    
    def quote_alias_if_needed(a)
      if a.match(/[^a-z0-9_]/)
        '"' + a + '"'
      else
        a
      end
    end

    DEFAULT_FORMATTER = lambda { |n|
      n.pieces.map { |p|
        p.is_a?(String) ? p : format_node(p)
      }.join
    }
    
    NODE_FORMATTERS = {
      SelectExpression => lambda { |n|
        formatted_expr = format_node(n.elements[0])
        if n.alias_node
          expr_alias = n.alias_node.text_value
          [formatted_expr, " AS ", quote_alias_if_needed(expr_alias)].join
        else
          formatted_expr
        end
      },
      SelectStatement => lambda { |n|
        statements = n.match(SelectExpression, Query)
        "\nSELECT\n" + eager_indent(statements.map { |s| format_node(s) }.join(",\n"))
      },
      LimitStatement => lambda { |n|
        "\nLIMIT" + n.elements[1..-1].map(&:text_value).join
      },
      WhereStatement  => lambda { |n|
        exprs = n.elements.select {|e| e.is_a?(Expression) }
        "\nWHERE " + indent(exprs.map {|e| DEFAULT_FORMATTER[e] }.join)
      },
      FromStatement   => lambda { |n|
        expressions = n.match(FromExpression, Query)
        "\nFROM " + indent(expressions.map {|e| format_node(e) }.join("\n"))
      },
      JoinStatement   => lambda { |n|
        join_keyword = n.match(JoinKeyword, Query)[0]
        from, criteria = n.elements.select {|e| e.is_a?(Expression) }
        ["\n",
         join_keyword.text_value.upcase,
         " ",
         indent(format_node(from)),
         " ON ",
         indent(format_node(criteria))].join
      },
      OrderByStatement   => lambda { |n|
        exprs = n.elements.select {|e| e.is_a?(OrderByExpression) }
        "\nORDER BY " + indent(exprs.map {|e| DEFAULT_FORMATTER[e] }.join)
      }
    }

    FORMATTERS = Hash.new(DEFAULT_FORMATTER).update(NODE_FORMATTERS)

    def format_node(node)
      FORMATTERS[node.class][node]
    end

    def format(node)
      format_node(node).split("\n").map(&:rstrip).join("\n").strip + "\n"
    end
  end
end
