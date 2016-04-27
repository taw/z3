class Definition
  attr_reader :name, :ret_type, :arguments
  def initialize(str)
    parse_definition!(str)
  end

  def supported?
    begin
      ffi
      api_def
      api_body
      true
    rescue Exception => e
      warn "Failed because: #{e} # #{@name}"
      false
    end
  end

  def type_to_api_argument_name(t)
    case t
    when "INT", "UINT", "RCF_NUM", "INT64", "UINT64"
      "num"
    when "BOOL"
      "bool"
    when "SYMBOL"
      "sym"
    when "STRING"
      "str"
    else
      "#{t.downcase}"
    end
  end

  def api_arguments
    raise if @arguments.any?{|a,| a != :in}
    arg_types = @arguments.map(&:last)
    arg_types.shift if arg_types[0] == "CONTEXT"

    cnts = Hash.new(0)
    idx = Hash.new(0)
    arg_names = arg_types.map{|t| type_to_api_argument_name(t)}
    arg_names.each do |n|
      cnts[n] += 1
    end
    arg_names.map do |n|
      if cnts[n] == 1
        n
      else
        i = "#{n}#{idx[n] += 1}"
      end
    end
  end

  def api_def
    if api_arguments.empty?
      "#{@name}"
    else
      "#{@name}(#{api_arguments.join(", ")})"
    end
  end

  def ffi_call_args
    raise if @arguments.any?{|a,| a != :in}
    arg_types = @arguments.map(&:last)
    result = []
    if arg_types[0] == "CONTEXT"
      result << "_ctx_pointer"
      arg_types.shift
    end
    result + arg_types.zip(api_arguments).map do |t,n|
      case t
      when "AST", "SORT", "FUNC_DECL", "PATTERN", "APP"
        "#{n}._ast"
      when "SOLVER", "MODEL", "GOAL", "FIXEDPOINT",
           "PROBE", "RCF_NUM", "OPTIMIZE", "PARAMS", "PARAM_DESCRS", "TACTIC",
           "CONTEXT", "AST_VECTOR", "AST_MAP", "APPLY_RESULT", "FUNC_INTERP", "CONFIG",
           "CONSTRUCTOR", "CONSTRUCTOR_LIST", "STATS", "FUNC_ENTRY"
        "#{n}._#{t.downcase}"
      when "SYMBOL"
        # FFI but not wrapped
        n
      when "INT", "UINT", "STRING", "BOOL", "INT64", "UINT64", "DOUBLE", "FLOAT"
        n
      else
        raise "Unknown API/FFI argument #{t}"
        # require 'pry'; binding.pry
      end
    end
  end

  def api_body
    "Z3::VeryLowLevel.Z3_#{@name}(#{ffi_call_args.join(", ")})"
  end

  def api
    [
      "    def #{api_def} #=> #{ffi_ret_type}\n",
      "      #{api_body}\n",
      "    end\n",
    ].join
  end

  def ffi_type(type)
    case type
    when "VOID"
      ":void"
    when "STRING"
      ":string"
    when "UINT"
      ":uint"
    when "INT"
      ":int"
    when "INT64"
      ":int64"
    when "UINT64"
      ":uint64"
    when "DOUBLE"
      ":double"
    when "FLOAT"
      ":float"
    when "BOOL"
      ":bool"
    when "CONTEXT"
      ":ctx_pointer"
    when "AST",
         "FIXEDPOINT",
         "FUNC_DECL",
         "FUNC_ENTRY",
         "FUNC_INTERP",
         "GOAL",
         "GOAL",
         "OPTIMIZE",
         "PARAMS",
         "PARAM_DESCRS",
         "PROBE",
         "SOLVER",
         "SORT",
         "SYMBOL",
         "TACTIC",
         "STATS",
         "RCF_NUM",
         "MODEL",
         "PATTERN",
         "AST_MAP",
         "AST_VECTOR",
         "CONFIG",
         "FUNC_ENTRY",
         "CONSTRUCTOR",
         "CONSTRUCTOR_LIST",
         "APPLY_RESULT",
         "APP"
      ":#{type.downcase}_pointer"
    # These are enums
         # "ERROR_CODE"
         # "PRINT_MODE"
    else
      raise "Unsupported type `#{type.inspect}'"
    end
  end

  def ffi_ret_type
    ffi_type(ret_type)
  end

  def ffi_args
    @arguments.map do |arg|
      raise "Only in arguments supported: #{@arguments.inspect}" unless arg[0] == :in
      ffi_type(arg[1])
    end
  end

  def ffi
    "  attach_function :Z3_#{@name}, [#{ffi_args.join(", ")}], #{ffi_ret_type}"
  end

  private

  def parse_definition!(definition_str)
    raise "Parse error: `#{definition_str}'" unless definition_str =~ /
      \A
      def_API
      \(
      '
      (\w+)
      '
      \s*,\s*
      (\w+)
      \s*,\s*
      \(
      (.*)
      \)
      \s*
      \)
      \z
    /x
    name = $1
    @ret_type = $2
    argument_str = $3

    @arguments = []
    until argument_str.empty?
      if argument_str.sub!(/\A_in\( (\w+) \)/x, "")
        arguments << [:in, $1]
      elsif argument_str.sub!(/\A_out\( (\w+) \)/x, "")
        arguments << [:out, $1]
      elsif argument_str.sub!(/\A_in_array\( (\d+) \s*,\s* (\w+) \)/x, "")
        arguments << [:in_array, $1.to_i, $2]
      elsif argument_str.sub!(/\A_out_array\( (\d+) \s*,\s* (\w+) \)/x, "")
        arguments << [:out_array, $1.to_i, $2]
      elsif argument_str.sub!(/\A_out_managed_array\( (\d+) \s*,\s* (\w+) \)/x, "")
        arguments << [:out_managed_array, $1.to_i, $2]
      elsif argument_str.sub!(/\A_inout_array\( (\d+) \s*,\s* (\w+) \)/x, "")
        arguments << [:inout_array, $1.to_i, $2]
      elsif argument_str.sub!(/\A[,\s]+/, "")
        # OK
      else
        require 'pry'; binding.pry
      end
    end
    if name =~ /\AZ3_/
      @name = name.sub(/\AZ3_/, "")
    else
      raise "Bad name: `#{name}'"
    end
  end
end
