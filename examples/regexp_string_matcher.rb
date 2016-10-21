require "set"

class RegexpStringMatcher
  # rx comes from SimpleRegexpParser
  # str is a bunch of Z3.Ints with proper constraints (0..127)
  def initialize(solver, rx, str, context)
    @solver = solver
    @rx = rx
    @str = str
    @context = context
    @subexprs = Set[]
  end

  def group_equal(group_identifier, start_idx, end_idx)
    str = @str[start_idx...end_idx]
    Z3.And(
      Z3.Int("group-#{group_identifier}-size") == str.size,
      *str.each_with_index.map{|s,i| Z3.Int("group-#{group_identifier}-char[#{i}]") == s }
    )
  end

  def anchor_match(anchor, start_idx)
    case anchor[0]
    when :bos
      start_idx == 0
    when :eos
      start_idx == @str.size
    when :bol
      if start_idx == 0
        true
      else
        @str[start_idx-1] == 10
      end
    when :eol
      # This is actually tricky
      # $ matches both before and after \n
      if start_idx == @str.size
        true
      elsif start_idx == 0
        (@str[start_idx] == 10)
      else
        (@str[start_idx] == 10) | (@str[start_idx-1] == 10)
      end
    when :lookahead
      regexp_match([:seq, anchor[1], [:any_star]], start_idx, @str.size)
    when :negative_lookahead
      ~regexp_match([:seq, anchor[1], [:any_star]], start_idx, @str.size)
    when :lookbehind
      regexp_match([:seq, [:any_star], anchor[1]], 0, start_idx)
    when :lookbehind
      ~regexp_match([:seq, [:any_star], anchor[1]], 0, start_idx)
    else
      raise "Unknown anchor type #{anchor[0]}"
    end
  end

  # @subexprs just prevents loops for self-referential regexps
  def regexp_match(rx, start_idx, end_idx)
    str = @str[start_idx...end_idx]
    var = Z3.Bool("#{rx} =~ #{@context}[#{start_idx}...#{end_idx}]")
    return var if @subexprs.include?(var)
    @subexprs << var

    expr = case rx[0]
    when :seq
      rx_a, rx_b = rx[1], rx[2]
      possibilities = (start_idx..end_idx).map do |i|
        a_ok = regexp_match(rx_a, start_idx, i)
        b_ok = regexp_match(rx_b, i, end_idx)
        a_ok & b_ok
      end
      Z3.Or(*possibilities)
    when :set
      if str.size == 1
        Z3.Or(*rx[1].map{|c| str[0] == c })
      else
        false
      end
    when :neg_set
      if str.size == 1
        ~Z3.Or(*rx[1].map{|c| str[0] == c })
      else
        false
      end
    when :alt
      rx_a, rx_b = rx[1], rx[2]
      regexp_match(rx_a, start_idx, end_idx) | regexp_match(rx_b, start_idx, end_idx)
    when :star
      if str.size == 0
        true
      else
        r = rx[1]
        possibilities = (start_idx+1..end_idx).map do |i|
          regexp_match(r, start_idx, i) & regexp_match(rx, i, end_idx)
        end
        Z3.Or(*possibilities)
      end
    when :group
      n = rx[1]
      rx_a = rx[2]
      regexp_match(rx_a, start_idx, end_idx) & group_equal(n, start_idx, end_idx)
    when :backref
      group_equal(rx[1], start_idx, end_idx)
    when :empty
      (str.size == 0)
    when :anchor
      if str.size == 0
        anchor_match(rx[1..-1], start_idx)
      else
        false
      end
    when :any_star # like /.*/m or /.*/s depending on language
      true
    else
      raise "Unknown regexp type #{rx[0]}"
    end
    @solver.assert (var == expr).simplify
    var
  end

  def run!
    @solver.assert regexp_match(@rx, 0, @str.length)
  end
end
