class Enum
  attr_reader :name, :entries

  def initialize(str)
    parse_enum!(str)
  end

  def <=>(other)
    name <=> other.name
  end

  # Z3_decl_kind -> DECL_KIND, matching how Z3::Enums nests under the module that
  # already carries the Z3_ prefix
  def ruby_name
    name.sub(/\AZ3_/, "").upcase
  end

  def ruby
    [
      "    #{ruby_name} = {\n",
      *entries.map { |value, c_name| "      #{value} => \"#{c_name}\",\n" },
      "    }.freeze\n",
    ].join
  end

  private

  # Every value is either the previous one plus one, or an explicit `= N` that
  # resets the count - the only two forms the C enum syntax allows
  def parse_enum!(str)
    unless str =~ /\Atypedef\s+enum\s*\{(.*)\}\s*(Z3_\w+)\s*;\s*\z/m
      raise "Parse error: `#{str}'"
    end
    body = $1
    @name = $2
    @entries = {}
    value = -1
    body.each_line do |line|
      line = line.sub(%r{//.*}, "").strip
      next if line.empty?
      line.split(",").map(&:strip).reject(&:empty?).each do |entry|
        case entry
        when /\A(Z3_\w+)\s*=\s*(-?(?:0x[0-9a-fA-F]+|\d+))\z/
          @entries[value = Integer($2)] = $1
        when /\A(Z3_\w+)\z/
          @entries[value += 1] = $1
        else
          raise "Can't parse enum entry `#{entry}' in #{@name}"
        end
      end
    end
  end
end
