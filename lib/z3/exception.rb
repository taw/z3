module Z3
  class Exception < StandardError
  end


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
end
