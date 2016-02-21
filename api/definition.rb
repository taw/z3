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
    ["???"]
  end

  def api_def
    if api_arguments.empty?
      "#{@name}"
    else
      "#{@name}(#{api_arguments.join(", ")})"
    end
  end

  def ffi_call_args
    ["???"]
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
    when "CONTEXT"
      "ctx_pointer"
    when "AST"
      "ast_pointer"
    when "SORT"
      "sort_pointer"
    else
      raise "Unsupported return type #{ret_type}"
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
