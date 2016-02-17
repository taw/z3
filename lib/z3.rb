module Z3
  class <<self
    def version
      Z3::LowLevel.get_version.join(".")
    end

    def set_param(k,v)
      Z3::LowLevel.global_param_set(k,v)
    end
  end
end

class Z3::Exception < StandardError
end

require_relative "z3/very_low_level"
require_relative "z3/low_level"
require_relative "z3/context"
require_relative "z3/solver"
require_relative "z3/sort"
require_relative "z3/ast"
require_relative "z3/model"
require_relative "z3/func_decl"

Z3::LowLevel.set_error_handler do |ctx, error|
  error_codes_enum = %W[
    Z3_OK
    Z3_SORT_ERROR
    Z3_IOB
    Z3_INVALID_ARG
    Z3_PARSER_ERROR
    Z3_NO_PARSER
    Z3_INVALID_PATTERN
    Z3_MEMOUT_FAIL
    Z3_FILE_ACCESS_ERROR
    Z3_INTERNAL_FATAL
    Z3_INVALID_USAGE
    Z3_DEC_REF_ERROR
    Z3_EXCEPTION
  ]
  error = error_codes_enum[error] || error
  raise Z3::Exception, "Z3 library failed with error #{error}"
end
