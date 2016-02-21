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
      warn "Failed because: #{e}"
      false
    end
  end

  def api_arguments
    raise if @arguments.any?{|a,| a != :in}
    arg_types = @arguments.map(&:last)
    arg_types.shift if arg_types[0] == "CONTEXT"
    case arg_types
    when ["AST"]
      ["ast"]
    when ["AST", "AST"]
      ["ast1", "ast2"]
    when ["AST", "AST", "AST"]
      ["ast1", "ast2", "ast3"]
    when ["AST", "AST", "AST", "AST"]
      ["ast1", "ast2", "ast3", "ast4"]
    when ["AST", "AST", "SORT"]
      ["ast1", "ast2", "sort"]
    when ["STRING", "SORT"]
      ["str", "sort"]
    when ["STRING"]
      ["str"]
    when ["SOLVER"]
      ["solver"]
    when ["SOLVER", "AST"]
      ["solver", "ast1"]
    when ["SOLVER", "AST", "AST"]
      ["solver", "ast1", "ast2"]
    when ["SOLVER", "UINT"]
      ["solver", "num"]
    when ["RCF_NUM"]
      ["num"]
    when ["RCF_NUM", "RCF_NUM"]
      ["num1", "num2"]
    when ["PROBE"]
      ["probe"]
    when ["PROBE", "PROBE"]
      ["probe1", "probe2"]
    when ["UINT"]
      ["num"]
    when ["AST", "UINT"]
      ["ast", "num"]
    when []
      []
    when ["SORT"]
      ["sort"]
    when ["SORT", "SORT"]
      ["sort1", "sort2"]
    when ["SORT", "UINT"]
      ["sort", "num"]
    when ["STRING", "STRING"]
      ["str1", "str2"]
    when ["FUNC_DECL", "AST", "AST"]
      ["func_decl", "ast1", "ast2"]
    when ["SYMBOL", "SORT"]
      ["symbol", "sort"]
    when ["SYMBOL"]
      ["symbol"]
    when ["GOAL"]
      ["goal"]
    when ["MODEL"]
      ["model"]
    when ["PARAMS"]
      ["params"]
    when ["OPTIMIZE"]
      ["optimize"]
    when ["PATTERN"]
      ["pattern"]
    else
      raise "Unknown API argument combinations #{arg_types.inspect}"
      # p arg_types
      # require 'pry'; binding.pry
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
      when "AST", "SORT", "SOLVER", "MODEL", "GOAL", "FIXEDPOINT", "FUNC_DECL",
          "PATTERN", "PROBE", "RCF_NUM", "OPTIMIZE", "PARAMS"
        "#{n}._#{t.downcase}"
      when "SYMBOL"
        # FFI but not wrapped
        n
      when "INT", "UINT", "STRING", "BOOLEAN"
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
      "ctx_pointer"
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
         "PATTERN"
      "#{type.downcase}_pointer"
    else
      raise "Unsupported type `#{type.inspect}'"
    end
  end

  def ffi_ret_type
    ffi_type(ret_type)
  end

  def ffi_args
    @arguments.map do |arg|
      raise "Only in arguments supported" unless arg[0] == :in
      ffi_type(arg[1])
    end
  end

  def ffi
    "attach_function :Z3_#{@name}, [#{ffi_args.join(", ")}], #{ffi_ret_type}"
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
