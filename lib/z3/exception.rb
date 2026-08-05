module Z3
  class Exception < StandardError
    # Z3_error_code, in declaration order - the handler is given the raw integer
    ERROR_CODES = %W[
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
    ].freeze
  end

  LowLevel.set_error_handler do |_ctx, error_code|
    code = Exception::ERROR_CODES[error_code] || error_code
    # Z3 keeps a message for the error it's signalling, and it's usually far more
    # specific than the code - "logic 'QF_NOPE' is not recognized" rather than a bare
    # Z3_INVALID_ARG. Some errors have nothing to add beyond restating the code, and
    # the parser reports one `(error "line ... column ...")` line per problem found.
    message = LowLevel.get_error_msg(error_code).to_s.strip
    error = "Z3 library failed with error #{code}"
    error += ": #{message}" unless message.empty?
    raise Z3::Exception, error
  end
end
