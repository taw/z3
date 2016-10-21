require "set"

class RegexpStringMatcher
  # rx comes from SimpleRegexpParser
  # str is a bunch of Z3.Ints with proper constraints (0..127)
  def initialize(solver, rx, str)
    @solver = solver
    @rx = rx
    @str = str
    @subexprs = Set[]
  end

  def group_equal(group_identifier, str)
    Z3.And(
      Z3.Int("group-#{group_identifier}-size") == str.size,
      *str.each_with_index.map{|s,i| Z3.Int("group-#{group_identifier}-char[#{i}]") == s }
    )
  end

  # @subexprs just prevents loops for self-referential regexps
  def regexp_match(rx, str)
    var = Z3.Bool("#{rx} =~ #{str}")
    return var if @subexprs.include?(var)
    @subexprs << var
    case rx[0]
    when :seq
      rx_a, rx_b = rx[1], rx[2]
      possibilities = (0..str.size).map do |i|
        a, b = str[0...i], str[i..-1]
        a_ok = regexp_match(rx_a, a)
        b_ok = regexp_match(rx_b, b)
        a_ok & b_ok
      end
      @solver.assert var == Z3.Or(*possibilities)
    when :set
      if str.size == 1
        @solver.assert var == Z3.Or(*rx[1].map{|c| str[0] == c })
      else
        @solver.assert var == false
      end
    when :neg_set
      if str.size == 1
        @solver.assert var == ~Z3.Or(*rx[1].map{|c| str[0] == c })
      else
        @solver.assert var == false
      end
    when :alt
      rx_a, rx_b = rx[1], rx[2]
      a_ok = regexp_match(rx_a, str)
      b_ok = regexp_match(rx_b, str)
      @solver.assert var == (a_ok | b_ok)
    when :star
      if str.size == 0
        @solver.assert var == true
      else
        r = rx[1]
        possibilities = (1..str.size).map do |i|
          a, b = str[0...i], str[i..-1]
          a_ok = regexp_match(r, a)
          b_ok = regexp_match(rx, b)
          a_ok & b_ok
        end
        @solver.assert var == Z3.Or(*possibilities)
      end
    when :group
      n = rx[1]
      rx_a = rx[2]
      @solver.assert var == (regexp_match(rx_a, str) & group_equal(n, str))
    when :backref
      @solver.assert var == group_equal(rx[1], str)
    when :empty
      @solver.assert var == (str.size == 0)
    else
      raise "Unknown regexp type #{rx[0]}"
    end
    var
  end

  def run!
    @solver.assert regexp_match(@rx, @str)
  end
end
