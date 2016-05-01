module Z3
  module LowLevel
    class << self
      def algebraic_add(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_algebraic_add(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def algebraic_div(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_algebraic_div(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def algebraic_eq(ast1, ast2) #=> :bool
        VeryLowLevel.Z3_algebraic_eq(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def algebraic_ge(ast1, ast2) #=> :bool
        VeryLowLevel.Z3_algebraic_ge(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def algebraic_gt(ast1, ast2) #=> :bool
        VeryLowLevel.Z3_algebraic_gt(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def algebraic_is_neg(ast) #=> :bool
        VeryLowLevel.Z3_algebraic_is_neg(_ctx_pointer, ast._ast)
      end

      def algebraic_is_pos(ast) #=> :bool
        VeryLowLevel.Z3_algebraic_is_pos(_ctx_pointer, ast._ast)
      end

      def algebraic_is_value(ast) #=> :bool
        VeryLowLevel.Z3_algebraic_is_value(_ctx_pointer, ast._ast)
      end

      def algebraic_is_zero(ast) #=> :bool
        VeryLowLevel.Z3_algebraic_is_zero(_ctx_pointer, ast._ast)
      end

      def algebraic_le(ast1, ast2) #=> :bool
        VeryLowLevel.Z3_algebraic_le(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def algebraic_lt(ast1, ast2) #=> :bool
        VeryLowLevel.Z3_algebraic_lt(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def algebraic_mul(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_algebraic_mul(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def algebraic_neq(ast1, ast2) #=> :bool
        VeryLowLevel.Z3_algebraic_neq(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def algebraic_power(ast, num) #=> :ast_pointer
        VeryLowLevel.Z3_algebraic_power(_ctx_pointer, ast._ast, num)
      end

      def algebraic_root(ast, num) #=> :ast_pointer
        VeryLowLevel.Z3_algebraic_root(_ctx_pointer, ast._ast, num)
      end

      def algebraic_sign(ast) #=> :int
        VeryLowLevel.Z3_algebraic_sign(_ctx_pointer, ast._ast)
      end

      def algebraic_sub(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_algebraic_sub(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def apply_result_convert_model(apply_result, num, model) #=> :model_pointer
        VeryLowLevel.Z3_apply_result_convert_model(_ctx_pointer, apply_result._apply_result, num, model._model)
      end

      def apply_result_dec_ref(apply_result) #=> :void
        VeryLowLevel.Z3_apply_result_dec_ref(_ctx_pointer, apply_result._apply_result)
      end

      def apply_result_get_num_subgoals(apply_result) #=> :uint
        VeryLowLevel.Z3_apply_result_get_num_subgoals(_ctx_pointer, apply_result._apply_result)
      end

      def apply_result_get_subgoal(apply_result, num) #=> :goal_pointer
        VeryLowLevel.Z3_apply_result_get_subgoal(_ctx_pointer, apply_result._apply_result, num)
      end

      def apply_result_inc_ref(apply_result) #=> :void
        VeryLowLevel.Z3_apply_result_inc_ref(_ctx_pointer, apply_result._apply_result)
      end

      def apply_result_to_string(apply_result) #=> :string
        VeryLowLevel.Z3_apply_result_to_string(_ctx_pointer, apply_result._apply_result)
      end

      def ast_map_contains(ast_map, ast) #=> :bool
        VeryLowLevel.Z3_ast_map_contains(_ctx_pointer, ast_map._ast_map, ast._ast)
      end

      def ast_map_dec_ref(ast_map) #=> :void
        VeryLowLevel.Z3_ast_map_dec_ref(_ctx_pointer, ast_map._ast_map)
      end

      def ast_map_erase(ast_map, ast) #=> :void
        VeryLowLevel.Z3_ast_map_erase(_ctx_pointer, ast_map._ast_map, ast._ast)
      end

      def ast_map_find(ast_map, ast) #=> :ast_pointer
        VeryLowLevel.Z3_ast_map_find(_ctx_pointer, ast_map._ast_map, ast._ast)
      end

      def ast_map_inc_ref(ast_map) #=> :void
        VeryLowLevel.Z3_ast_map_inc_ref(_ctx_pointer, ast_map._ast_map)
      end

      def ast_map_insert(ast_map, ast1, ast2) #=> :void
        VeryLowLevel.Z3_ast_map_insert(_ctx_pointer, ast_map._ast_map, ast1._ast, ast2._ast)
      end

      def ast_map_keys(ast_map) #=> :ast_vector_pointer
        VeryLowLevel.Z3_ast_map_keys(_ctx_pointer, ast_map._ast_map)
      end

      def ast_map_reset(ast_map) #=> :void
        VeryLowLevel.Z3_ast_map_reset(_ctx_pointer, ast_map._ast_map)
      end

      def ast_map_size(ast_map) #=> :uint
        VeryLowLevel.Z3_ast_map_size(_ctx_pointer, ast_map._ast_map)
      end

      def ast_map_to_string(ast_map) #=> :string
        VeryLowLevel.Z3_ast_map_to_string(_ctx_pointer, ast_map._ast_map)
      end

      def ast_to_string(ast) #=> :string
        VeryLowLevel.Z3_ast_to_string(_ctx_pointer, ast._ast)
      end

      def ast_vector_dec_ref(ast_vector) #=> :void
        VeryLowLevel.Z3_ast_vector_dec_ref(_ctx_pointer, ast_vector)
      end

      def ast_vector_get(ast_vector, num) #=> :ast_pointer
        VeryLowLevel.Z3_ast_vector_get(_ctx_pointer, ast_vector, num)
      end

      def ast_vector_inc_ref(ast_vector) #=> :void
        VeryLowLevel.Z3_ast_vector_inc_ref(_ctx_pointer, ast_vector)
      end

      def ast_vector_push(ast_vector, ast) #=> :void
        VeryLowLevel.Z3_ast_vector_push(_ctx_pointer, ast_vector, ast._ast)
      end

      def ast_vector_resize(ast_vector, num) #=> :void
        VeryLowLevel.Z3_ast_vector_resize(_ctx_pointer, ast_vector, num)
      end

      def ast_vector_set(ast_vector, num, ast) #=> :void
        VeryLowLevel.Z3_ast_vector_set(_ctx_pointer, ast_vector, num, ast._ast)
      end

      def ast_vector_size(ast_vector) #=> :uint
        VeryLowLevel.Z3_ast_vector_size(_ctx_pointer, ast_vector)
      end

      def ast_vector_to_string(ast_vector) #=> :string
        VeryLowLevel.Z3_ast_vector_to_string(_ctx_pointer, ast_vector)
      end

      def ast_vector_translate(ast_vector, context) #=> :ast_vector_pointer
        VeryLowLevel.Z3_ast_vector_translate(_ctx_pointer, ast_vector, context._context)
      end

      def datatype_update_field(func_decl, ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_datatype_update_field(_ctx_pointer, func_decl._ast, ast1._ast, ast2._ast)
      end

      def dec_ref(ast) #=> :void
        VeryLowLevel.Z3_dec_ref(_ctx_pointer, ast._ast)
      end

      def del_config(config) #=> :void
        VeryLowLevel.Z3_del_config(config._config)
      end

      def del_constructor(constructor) #=> :void
        VeryLowLevel.Z3_del_constructor(_ctx_pointer, constructor._constructor)
      end

      def del_constructor_list(constructor_list) #=> :void
        VeryLowLevel.Z3_del_constructor_list(_ctx_pointer, constructor_list._constructor_list)
      end

      def del_context #=> :void
        VeryLowLevel.Z3_del_context(_ctx_pointer)
      end

      def disable_trace(str) #=> :void
        VeryLowLevel.Z3_disable_trace(str)
      end

      def enable_trace(str) #=> :void
        VeryLowLevel.Z3_enable_trace(str)
      end

      def finalize_memory #=> :void
        VeryLowLevel.Z3_finalize_memory()
      end

      def fixedpoint_add_cover(fixedpoint, num, func_decl, ast) #=> :void
        VeryLowLevel.Z3_fixedpoint_add_cover(_ctx_pointer, fixedpoint._fixedpoint, num, func_decl._ast, ast._ast)
      end

      def fixedpoint_add_rule(fixedpoint, ast, sym) #=> :void
        VeryLowLevel.Z3_fixedpoint_add_rule(_ctx_pointer, fixedpoint._fixedpoint, ast._ast, sym)
      end

      def fixedpoint_assert(fixedpoint, ast) #=> :void
        VeryLowLevel.Z3_fixedpoint_assert(_ctx_pointer, fixedpoint._fixedpoint, ast._ast)
      end

      def fixedpoint_dec_ref(fixedpoint) #=> :void
        VeryLowLevel.Z3_fixedpoint_dec_ref(_ctx_pointer, fixedpoint._fixedpoint)
      end

      def fixedpoint_from_file(fixedpoint, str) #=> :ast_vector_pointer
        VeryLowLevel.Z3_fixedpoint_from_file(_ctx_pointer, fixedpoint._fixedpoint, str)
      end

      def fixedpoint_from_string(fixedpoint, str) #=> :ast_vector_pointer
        VeryLowLevel.Z3_fixedpoint_from_string(_ctx_pointer, fixedpoint._fixedpoint, str)
      end

      def fixedpoint_get_answer(fixedpoint) #=> :ast_pointer
        VeryLowLevel.Z3_fixedpoint_get_answer(_ctx_pointer, fixedpoint._fixedpoint)
      end

      def fixedpoint_get_assertions(fixedpoint) #=> :ast_vector_pointer
        VeryLowLevel.Z3_fixedpoint_get_assertions(_ctx_pointer, fixedpoint._fixedpoint)
      end

      def fixedpoint_get_cover_delta(fixedpoint, num, func_decl) #=> :ast_pointer
        VeryLowLevel.Z3_fixedpoint_get_cover_delta(_ctx_pointer, fixedpoint._fixedpoint, num, func_decl._ast)
      end

      def fixedpoint_get_help(fixedpoint) #=> :string
        VeryLowLevel.Z3_fixedpoint_get_help(_ctx_pointer, fixedpoint._fixedpoint)
      end

      def fixedpoint_get_num_levels(fixedpoint, func_decl) #=> :uint
        VeryLowLevel.Z3_fixedpoint_get_num_levels(_ctx_pointer, fixedpoint._fixedpoint, func_decl._ast)
      end

      def fixedpoint_get_param_descrs(fixedpoint) #=> :param_descrs_pointer
        VeryLowLevel.Z3_fixedpoint_get_param_descrs(_ctx_pointer, fixedpoint._fixedpoint)
      end

      def fixedpoint_get_reason_unknown(fixedpoint) #=> :string
        VeryLowLevel.Z3_fixedpoint_get_reason_unknown(_ctx_pointer, fixedpoint._fixedpoint)
      end

      def fixedpoint_get_rules(fixedpoint) #=> :ast_vector_pointer
        VeryLowLevel.Z3_fixedpoint_get_rules(_ctx_pointer, fixedpoint._fixedpoint)
      end

      def fixedpoint_get_statistics(fixedpoint) #=> :stats_pointer
        VeryLowLevel.Z3_fixedpoint_get_statistics(_ctx_pointer, fixedpoint._fixedpoint)
      end

      def fixedpoint_inc_ref(fixedpoint) #=> :void
        VeryLowLevel.Z3_fixedpoint_inc_ref(_ctx_pointer, fixedpoint._fixedpoint)
      end

      def fixedpoint_pop(fixedpoint) #=> :void
        VeryLowLevel.Z3_fixedpoint_pop(_ctx_pointer, fixedpoint._fixedpoint)
      end

      def fixedpoint_push(fixedpoint) #=> :void
        VeryLowLevel.Z3_fixedpoint_push(_ctx_pointer, fixedpoint._fixedpoint)
      end

      def fixedpoint_query(fixedpoint, ast) #=> :int
        VeryLowLevel.Z3_fixedpoint_query(_ctx_pointer, fixedpoint._fixedpoint, ast._ast)
      end

      def fixedpoint_register_relation(fixedpoint, func_decl) #=> :void
        VeryLowLevel.Z3_fixedpoint_register_relation(_ctx_pointer, fixedpoint._fixedpoint, func_decl._ast)
      end

      def fixedpoint_set_params(fixedpoint, params) #=> :void
        VeryLowLevel.Z3_fixedpoint_set_params(_ctx_pointer, fixedpoint._fixedpoint, params._params)
      end

      def fixedpoint_update_rule(fixedpoint, ast, sym) #=> :void
        VeryLowLevel.Z3_fixedpoint_update_rule(_ctx_pointer, fixedpoint._fixedpoint, ast._ast, sym)
      end

      def fpa_get_ebits(sort) #=> :uint
        VeryLowLevel.Z3_fpa_get_ebits(_ctx_pointer, sort._ast)
      end

      def fpa_get_numeral_exponent_string(ast) #=> :string
        VeryLowLevel.Z3_fpa_get_numeral_exponent_string(_ctx_pointer, ast._ast)
      end

      def fpa_get_numeral_significand_string(ast) #=> :string
        VeryLowLevel.Z3_fpa_get_numeral_significand_string(_ctx_pointer, ast._ast)
      end

      def fpa_get_sbits(sort) #=> :uint
        VeryLowLevel.Z3_fpa_get_sbits(_ctx_pointer, sort._ast)
      end

      def func_entry_dec_ref(func_entry) #=> :void
        VeryLowLevel.Z3_func_entry_dec_ref(_ctx_pointer, func_entry._func_entry)
      end

      def func_entry_get_arg(func_entry, num) #=> :ast_pointer
        VeryLowLevel.Z3_func_entry_get_arg(_ctx_pointer, func_entry._func_entry, num)
      end

      def func_entry_get_num_args(func_entry) #=> :uint
        VeryLowLevel.Z3_func_entry_get_num_args(_ctx_pointer, func_entry._func_entry)
      end

      def func_entry_get_value(func_entry) #=> :ast_pointer
        VeryLowLevel.Z3_func_entry_get_value(_ctx_pointer, func_entry._func_entry)
      end

      def func_entry_inc_ref(func_entry) #=> :void
        VeryLowLevel.Z3_func_entry_inc_ref(_ctx_pointer, func_entry._func_entry)
      end

      def func_interp_dec_ref(func_interp) #=> :void
        VeryLowLevel.Z3_func_interp_dec_ref(_ctx_pointer, func_interp._func_interp)
      end

      def func_interp_get_arity(func_interp) #=> :uint
        VeryLowLevel.Z3_func_interp_get_arity(_ctx_pointer, func_interp._func_interp)
      end

      def func_interp_get_else(func_interp) #=> :ast_pointer
        VeryLowLevel.Z3_func_interp_get_else(_ctx_pointer, func_interp._func_interp)
      end

      def func_interp_get_entry(func_interp, num) #=> :func_entry_pointer
        VeryLowLevel.Z3_func_interp_get_entry(_ctx_pointer, func_interp._func_interp, num)
      end

      def func_interp_get_num_entries(func_interp) #=> :uint
        VeryLowLevel.Z3_func_interp_get_num_entries(_ctx_pointer, func_interp._func_interp)
      end

      def func_interp_inc_ref(func_interp) #=> :void
        VeryLowLevel.Z3_func_interp_inc_ref(_ctx_pointer, func_interp._func_interp)
      end

      def get_algebraic_number_lower(ast, num) #=> :ast_pointer
        VeryLowLevel.Z3_get_algebraic_number_lower(_ctx_pointer, ast._ast, num)
      end

      def get_algebraic_number_upper(ast, num) #=> :ast_pointer
        VeryLowLevel.Z3_get_algebraic_number_upper(_ctx_pointer, ast._ast, num)
      end

      def get_app_arg(app, num) #=> :ast_pointer
        VeryLowLevel.Z3_get_app_arg(_ctx_pointer, app._ast, num)
      end

      def get_app_decl(app) #=> :func_decl_pointer
        VeryLowLevel.Z3_get_app_decl(_ctx_pointer, app._ast)
      end

      def get_app_num_args(app) #=> :uint
        VeryLowLevel.Z3_get_app_num_args(_ctx_pointer, app._ast)
      end

      def get_arity(func_decl) #=> :uint
        VeryLowLevel.Z3_get_arity(_ctx_pointer, func_decl._ast)
      end

      def get_array_sort_domain(sort) #=> :sort_pointer
        VeryLowLevel.Z3_get_array_sort_domain(_ctx_pointer, sort._ast)
      end

      def get_array_sort_range(sort) #=> :sort_pointer
        VeryLowLevel.Z3_get_array_sort_range(_ctx_pointer, sort._ast)
      end

      def get_as_array_func_decl(ast) #=> :func_decl_pointer
        VeryLowLevel.Z3_get_as_array_func_decl(_ctx_pointer, ast._ast)
      end

      def get_ast_hash(ast) #=> :uint
        VeryLowLevel.Z3_get_ast_hash(_ctx_pointer, ast._ast)
      end

      def get_ast_id(ast) #=> :uint
        VeryLowLevel.Z3_get_ast_id(_ctx_pointer, ast._ast)
      end

      def get_ast_kind(ast) #=> :uint
        VeryLowLevel.Z3_get_ast_kind(_ctx_pointer, ast._ast)
      end

      def get_bool_value(ast) #=> :int
        VeryLowLevel.Z3_get_bool_value(_ctx_pointer, ast._ast)
      end

      def get_bv_sort_size(sort) #=> :uint
        VeryLowLevel.Z3_get_bv_sort_size(_ctx_pointer, sort._ast)
      end

      def get_datatype_sort_constructor(sort, num) #=> :func_decl_pointer
        VeryLowLevel.Z3_get_datatype_sort_constructor(_ctx_pointer, sort._ast, num)
      end

      def get_datatype_sort_constructor_accessor(sort, num1, num2) #=> :func_decl_pointer
        VeryLowLevel.Z3_get_datatype_sort_constructor_accessor(_ctx_pointer, sort._ast, num1, num2)
      end

      def get_datatype_sort_num_constructors(sort) #=> :uint
        VeryLowLevel.Z3_get_datatype_sort_num_constructors(_ctx_pointer, sort._ast)
      end

      def get_datatype_sort_recognizer(sort, num) #=> :func_decl_pointer
        VeryLowLevel.Z3_get_datatype_sort_recognizer(_ctx_pointer, sort._ast, num)
      end

      def get_decl_ast_parameter(func_decl, num) #=> :ast_pointer
        VeryLowLevel.Z3_get_decl_ast_parameter(_ctx_pointer, func_decl._ast, num)
      end

      def get_decl_double_parameter(func_decl, num) #=> :double
        VeryLowLevel.Z3_get_decl_double_parameter(_ctx_pointer, func_decl._ast, num)
      end

      def get_decl_func_decl_parameter(func_decl, num) #=> :func_decl_pointer
        VeryLowLevel.Z3_get_decl_func_decl_parameter(_ctx_pointer, func_decl._ast, num)
      end

      def get_decl_int_parameter(func_decl, num) #=> :int
        VeryLowLevel.Z3_get_decl_int_parameter(_ctx_pointer, func_decl._ast, num)
      end

      def get_decl_kind(func_decl) #=> :uint
        VeryLowLevel.Z3_get_decl_kind(_ctx_pointer, func_decl._ast)
      end

      def get_decl_name(func_decl) #=> :symbol_pointer
        VeryLowLevel.Z3_get_decl_name(_ctx_pointer, func_decl._ast)
      end

      def get_decl_num_parameters(func_decl) #=> :uint
        VeryLowLevel.Z3_get_decl_num_parameters(_ctx_pointer, func_decl._ast)
      end

      def get_decl_parameter_kind(func_decl, num) #=> :uint
        VeryLowLevel.Z3_get_decl_parameter_kind(_ctx_pointer, func_decl._ast, num)
      end

      def get_decl_rational_parameter(func_decl, num) #=> :string
        VeryLowLevel.Z3_get_decl_rational_parameter(_ctx_pointer, func_decl._ast, num)
      end

      def get_decl_sort_parameter(func_decl, num) #=> :sort_pointer
        VeryLowLevel.Z3_get_decl_sort_parameter(_ctx_pointer, func_decl._ast, num)
      end

      def get_decl_symbol_parameter(func_decl, num) #=> :symbol_pointer
        VeryLowLevel.Z3_get_decl_symbol_parameter(_ctx_pointer, func_decl._ast, num)
      end

      def get_denominator(ast) #=> :ast_pointer
        VeryLowLevel.Z3_get_denominator(_ctx_pointer, ast._ast)
      end

      def get_domain(func_decl, num) #=> :sort_pointer
        VeryLowLevel.Z3_get_domain(_ctx_pointer, func_decl._ast, num)
      end

      def get_domain_size(func_decl) #=> :uint
        VeryLowLevel.Z3_get_domain_size(_ctx_pointer, func_decl._ast)
      end

      def get_error_code #=> :uint
        VeryLowLevel.Z3_get_error_code(_ctx_pointer)
      end

      def get_func_decl_id(func_decl) #=> :uint
        VeryLowLevel.Z3_get_func_decl_id(_ctx_pointer, func_decl._ast)
      end

      def get_index_value(ast) #=> :uint
        VeryLowLevel.Z3_get_index_value(_ctx_pointer, ast._ast)
      end

      def get_interpolant(ast1, ast2, params) #=> :ast_vector_pointer
        VeryLowLevel.Z3_get_interpolant(_ctx_pointer, ast1._ast, ast2._ast, params._params)
      end

      def get_num_probes #=> :uint
        VeryLowLevel.Z3_get_num_probes(_ctx_pointer)
      end

      def get_num_tactics #=> :uint
        VeryLowLevel.Z3_get_num_tactics(_ctx_pointer)
      end

      def get_numeral_decimal_string(ast, num) #=> :string
        VeryLowLevel.Z3_get_numeral_decimal_string(_ctx_pointer, ast._ast, num)
      end

      def get_numeral_string(ast) #=> :string
        VeryLowLevel.Z3_get_numeral_string(_ctx_pointer, ast._ast)
      end

      def get_numerator(ast) #=> :ast_pointer
        VeryLowLevel.Z3_get_numerator(_ctx_pointer, ast._ast)
      end

      def get_pattern(pattern, num) #=> :ast_pointer
        VeryLowLevel.Z3_get_pattern(_ctx_pointer, pattern._ast, num)
      end

      def get_pattern_num_terms(pattern) #=> :uint
        VeryLowLevel.Z3_get_pattern_num_terms(_ctx_pointer, pattern._ast)
      end

      def get_probe_name(num) #=> :string
        VeryLowLevel.Z3_get_probe_name(_ctx_pointer, num)
      end

      def get_quantifier_body(ast) #=> :ast_pointer
        VeryLowLevel.Z3_get_quantifier_body(_ctx_pointer, ast._ast)
      end

      def get_quantifier_bound_name(ast, num) #=> :symbol_pointer
        VeryLowLevel.Z3_get_quantifier_bound_name(_ctx_pointer, ast._ast, num)
      end

      def get_quantifier_bound_sort(ast, num) #=> :sort_pointer
        VeryLowLevel.Z3_get_quantifier_bound_sort(_ctx_pointer, ast._ast, num)
      end

      def get_quantifier_no_pattern_ast(ast, num) #=> :ast_pointer
        VeryLowLevel.Z3_get_quantifier_no_pattern_ast(_ctx_pointer, ast._ast, num)
      end

      def get_quantifier_num_bound(ast) #=> :uint
        VeryLowLevel.Z3_get_quantifier_num_bound(_ctx_pointer, ast._ast)
      end

      def get_quantifier_num_no_patterns(ast) #=> :uint
        VeryLowLevel.Z3_get_quantifier_num_no_patterns(_ctx_pointer, ast._ast)
      end

      def get_quantifier_num_patterns(ast) #=> :uint
        VeryLowLevel.Z3_get_quantifier_num_patterns(_ctx_pointer, ast._ast)
      end

      def get_quantifier_pattern_ast(ast, num) #=> :pattern_pointer
        VeryLowLevel.Z3_get_quantifier_pattern_ast(_ctx_pointer, ast._ast, num)
      end

      def get_quantifier_weight(ast) #=> :uint
        VeryLowLevel.Z3_get_quantifier_weight(_ctx_pointer, ast._ast)
      end

      def get_range(func_decl) #=> :sort_pointer
        VeryLowLevel.Z3_get_range(_ctx_pointer, func_decl._ast)
      end

      def get_relation_arity(sort) #=> :uint
        VeryLowLevel.Z3_get_relation_arity(_ctx_pointer, sort._ast)
      end

      def get_relation_column(sort, num) #=> :sort_pointer
        VeryLowLevel.Z3_get_relation_column(_ctx_pointer, sort._ast, num)
      end

      def get_smtlib_assumption(num) #=> :ast_pointer
        VeryLowLevel.Z3_get_smtlib_assumption(_ctx_pointer, num)
      end

      def get_smtlib_decl(num) #=> :func_decl_pointer
        VeryLowLevel.Z3_get_smtlib_decl(_ctx_pointer, num)
      end

      def get_smtlib_error #=> :string
        VeryLowLevel.Z3_get_smtlib_error(_ctx_pointer)
      end

      def get_smtlib_formula(num) #=> :ast_pointer
        VeryLowLevel.Z3_get_smtlib_formula(_ctx_pointer, num)
      end

      def get_smtlib_num_assumptions #=> :uint
        VeryLowLevel.Z3_get_smtlib_num_assumptions(_ctx_pointer)
      end

      def get_smtlib_num_decls #=> :uint
        VeryLowLevel.Z3_get_smtlib_num_decls(_ctx_pointer)
      end

      def get_smtlib_num_formulas #=> :uint
        VeryLowLevel.Z3_get_smtlib_num_formulas(_ctx_pointer)
      end

      def get_smtlib_num_sorts #=> :uint
        VeryLowLevel.Z3_get_smtlib_num_sorts(_ctx_pointer)
      end

      def get_smtlib_sort(num) #=> :sort_pointer
        VeryLowLevel.Z3_get_smtlib_sort(_ctx_pointer, num)
      end

      def get_sort(ast) #=> :sort_pointer
        VeryLowLevel.Z3_get_sort(_ctx_pointer, ast._ast)
      end

      def get_sort_id(sort) #=> :uint
        VeryLowLevel.Z3_get_sort_id(_ctx_pointer, sort._ast)
      end

      def get_sort_kind(sort) #=> :uint
        VeryLowLevel.Z3_get_sort_kind(_ctx_pointer, sort._ast)
      end

      def get_sort_name(sort) #=> :symbol_pointer
        VeryLowLevel.Z3_get_sort_name(_ctx_pointer, sort._ast)
      end

      def get_symbol_int(sym) #=> :int
        VeryLowLevel.Z3_get_symbol_int(_ctx_pointer, sym)
      end

      def get_symbol_kind(sym) #=> :uint
        VeryLowLevel.Z3_get_symbol_kind(_ctx_pointer, sym)
      end

      def get_symbol_string(sym) #=> :string
        VeryLowLevel.Z3_get_symbol_string(_ctx_pointer, sym)
      end

      def get_tactic_name(num) #=> :string
        VeryLowLevel.Z3_get_tactic_name(_ctx_pointer, num)
      end

      def get_tuple_sort_field_decl(sort, num) #=> :func_decl_pointer
        VeryLowLevel.Z3_get_tuple_sort_field_decl(_ctx_pointer, sort._ast, num)
      end

      def get_tuple_sort_mk_decl(sort) #=> :func_decl_pointer
        VeryLowLevel.Z3_get_tuple_sort_mk_decl(_ctx_pointer, sort._ast)
      end

      def get_tuple_sort_num_fields(sort) #=> :uint
        VeryLowLevel.Z3_get_tuple_sort_num_fields(_ctx_pointer, sort._ast)
      end

      def global_param_reset_all #=> :void
        VeryLowLevel.Z3_global_param_reset_all()
      end

      def global_param_set(str1, str2) #=> :void
        VeryLowLevel.Z3_global_param_set(str1, str2)
      end

      def goal_assert(goal, ast) #=> :void
        VeryLowLevel.Z3_goal_assert(_ctx_pointer, goal._goal, ast._ast)
      end

      def goal_dec_ref(goal) #=> :void
        VeryLowLevel.Z3_goal_dec_ref(_ctx_pointer, goal._goal)
      end

      def goal_depth(goal) #=> :uint
        VeryLowLevel.Z3_goal_depth(_ctx_pointer, goal._goal)
      end

      def goal_formula(goal, num) #=> :ast_pointer
        VeryLowLevel.Z3_goal_formula(_ctx_pointer, goal._goal, num)
      end

      def goal_inc_ref(goal) #=> :void
        VeryLowLevel.Z3_goal_inc_ref(_ctx_pointer, goal._goal)
      end

      def goal_inconsistent(goal) #=> :bool
        VeryLowLevel.Z3_goal_inconsistent(_ctx_pointer, goal._goal)
      end

      def goal_is_decided_sat(goal) #=> :bool
        VeryLowLevel.Z3_goal_is_decided_sat(_ctx_pointer, goal._goal)
      end

      def goal_is_decided_unsat(goal) #=> :bool
        VeryLowLevel.Z3_goal_is_decided_unsat(_ctx_pointer, goal._goal)
      end

      def goal_num_exprs(goal) #=> :uint
        VeryLowLevel.Z3_goal_num_exprs(_ctx_pointer, goal._goal)
      end

      def goal_precision(goal) #=> :uint
        VeryLowLevel.Z3_goal_precision(_ctx_pointer, goal._goal)
      end

      def goal_reset(goal) #=> :void
        VeryLowLevel.Z3_goal_reset(_ctx_pointer, goal._goal)
      end

      def goal_size(goal) #=> :uint
        VeryLowLevel.Z3_goal_size(_ctx_pointer, goal._goal)
      end

      def goal_to_string(goal) #=> :string
        VeryLowLevel.Z3_goal_to_string(_ctx_pointer, goal._goal)
      end

      def goal_translate(goal, context) #=> :goal_pointer
        VeryLowLevel.Z3_goal_translate(_ctx_pointer, goal._goal, context._context)
      end

      def inc_ref(ast) #=> :void
        VeryLowLevel.Z3_inc_ref(_ctx_pointer, ast._ast)
      end

      def interpolation_profile #=> :string
        VeryLowLevel.Z3_interpolation_profile(_ctx_pointer)
      end

      def interrupt #=> :void
        VeryLowLevel.Z3_interrupt(_ctx_pointer)
      end

      def is_algebraic_number(ast) #=> :bool
        VeryLowLevel.Z3_is_algebraic_number(_ctx_pointer, ast._ast)
      end

      def is_app(ast) #=> :bool
        VeryLowLevel.Z3_is_app(_ctx_pointer, ast._ast)
      end

      def is_as_array(ast) #=> :bool
        VeryLowLevel.Z3_is_as_array(_ctx_pointer, ast._ast)
      end

      def is_eq_ast(ast1, ast2) #=> :bool
        VeryLowLevel.Z3_is_eq_ast(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def is_eq_func_decl(func_decl1, func_decl2) #=> :bool
        VeryLowLevel.Z3_is_eq_func_decl(_ctx_pointer, func_decl1._ast, func_decl2._ast)
      end

      def is_eq_sort(sort1, sort2) #=> :bool
        VeryLowLevel.Z3_is_eq_sort(_ctx_pointer, sort1._ast, sort2._ast)
      end

      def is_numeral_ast(ast) #=> :bool
        VeryLowLevel.Z3_is_numeral_ast(_ctx_pointer, ast._ast)
      end

      def is_quantifier_forall(ast) #=> :bool
        VeryLowLevel.Z3_is_quantifier_forall(_ctx_pointer, ast._ast)
      end

      def is_well_sorted(ast) #=> :bool
        VeryLowLevel.Z3_is_well_sorted(_ctx_pointer, ast._ast)
      end

      def mk_array_default(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_array_default(_ctx_pointer, ast._ast)
      end

      def mk_array_sort(sort1, sort2) #=> :sort_pointer
        VeryLowLevel.Z3_mk_array_sort(_ctx_pointer, sort1._ast, sort2._ast)
      end

      def mk_ast_map #=> :ast_map_pointer
        VeryLowLevel.Z3_mk_ast_map(_ctx_pointer)
      end

      def mk_ast_vector #=> :ast_vector_pointer
        VeryLowLevel.Z3_mk_ast_vector(_ctx_pointer)
      end

      def mk_bool_sort #=> :sort_pointer
        VeryLowLevel.Z3_mk_bool_sort(_ctx_pointer)
      end

      def mk_bound(num, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bound(_ctx_pointer, num, sort._ast)
      end

      def mk_bv2int(ast, bool) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bv2int(_ctx_pointer, ast._ast, bool)
      end

      def mk_bv_sort(num) #=> :sort_pointer
        VeryLowLevel.Z3_mk_bv_sort(_ctx_pointer, num)
      end

      def mk_bvadd(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvadd(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvadd_no_overflow(ast1, ast2, bool) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvadd_no_overflow(_ctx_pointer, ast1._ast, ast2._ast, bool)
      end

      def mk_bvadd_no_underflow(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvadd_no_underflow(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvand(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvand(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvashr(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvashr(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvlshr(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvlshr(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvmul(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvmul(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvmul_no_overflow(ast1, ast2, bool) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvmul_no_overflow(_ctx_pointer, ast1._ast, ast2._ast, bool)
      end

      def mk_bvmul_no_underflow(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvmul_no_underflow(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvnand(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvnand(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvneg(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvneg(_ctx_pointer, ast._ast)
      end

      def mk_bvneg_no_overflow(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvneg_no_overflow(_ctx_pointer, ast._ast)
      end

      def mk_bvnor(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvnor(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvnot(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvnot(_ctx_pointer, ast._ast)
      end

      def mk_bvor(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvor(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvredand(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvredand(_ctx_pointer, ast._ast)
      end

      def mk_bvredor(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvredor(_ctx_pointer, ast._ast)
      end

      def mk_bvsdiv(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvsdiv(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvsdiv_no_overflow(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvsdiv_no_overflow(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvsge(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvsge(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvsgt(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvsgt(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvshl(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvshl(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvsle(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvsle(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvslt(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvslt(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvsmod(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvsmod(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvsrem(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvsrem(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvsub(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvsub(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvsub_no_overflow(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvsub_no_overflow(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvsub_no_underflow(ast1, ast2, bool) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvsub_no_underflow(_ctx_pointer, ast1._ast, ast2._ast, bool)
      end

      def mk_bvudiv(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvudiv(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvuge(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvuge(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvugt(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvugt(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvule(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvule(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvult(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvult(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvurem(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvurem(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvxnor(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvxnor(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_bvxor(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_bvxor(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_concat(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_concat(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_config #=> :config_pointer
        VeryLowLevel.Z3_mk_config()
      end

      def mk_const(sym, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_const(_ctx_pointer, sym, sort._ast)
      end

      def mk_const_array(sort, ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_const_array(_ctx_pointer, sort._ast, ast._ast)
      end

      def mk_context_rc(config) #=> :ctx_pointer
        VeryLowLevel.Z3_mk_context_rc(config._config)
      end

      def mk_div(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_div(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_empty_set(sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_empty_set(_ctx_pointer, sort._ast)
      end

      def mk_eq(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_eq(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_ext_rotate_left(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_ext_rotate_left(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_ext_rotate_right(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_ext_rotate_right(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_extract(num1, num2, ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_extract(_ctx_pointer, num1, num2, ast._ast)
      end

      def mk_false #=> :ast_pointer
        VeryLowLevel.Z3_mk_false(_ctx_pointer)
      end

      def mk_finite_domain_sort(sym, num) #=> :sort_pointer
        VeryLowLevel.Z3_mk_finite_domain_sort(_ctx_pointer, sym, num)
      end

      def mk_fixedpoint #=> :fixedpoint_pointer
        VeryLowLevel.Z3_mk_fixedpoint(_ctx_pointer)
      end

      def mk_fpa_abs(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_abs(_ctx_pointer, ast._ast)
      end

      def mk_fpa_add(ast1, ast2, ast3) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_add(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast)
      end

      def mk_fpa_div(ast1, ast2, ast3) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_div(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast)
      end

      def mk_fpa_eq(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_eq(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_fpa_fma(ast1, ast2, ast3, ast4) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_fma(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast, ast4._ast)
      end

      def mk_fpa_fp(ast1, ast2, ast3) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_fp(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast)
      end

      def mk_fpa_geq(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_geq(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_fpa_gt(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_gt(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_fpa_inf(sort, bool) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_inf(_ctx_pointer, sort._ast, bool)
      end

      def mk_fpa_is_infinite(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_is_infinite(_ctx_pointer, ast._ast)
      end

      def mk_fpa_is_nan(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_is_nan(_ctx_pointer, ast._ast)
      end

      def mk_fpa_is_negative(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_is_negative(_ctx_pointer, ast._ast)
      end

      def mk_fpa_is_normal(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_is_normal(_ctx_pointer, ast._ast)
      end

      def mk_fpa_is_positive(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_is_positive(_ctx_pointer, ast._ast)
      end

      def mk_fpa_is_subnormal(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_is_subnormal(_ctx_pointer, ast._ast)
      end

      def mk_fpa_is_zero(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_is_zero(_ctx_pointer, ast._ast)
      end

      def mk_fpa_leq(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_leq(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_fpa_lt(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_lt(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_fpa_max(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_max(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_fpa_min(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_min(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_fpa_mul(ast1, ast2, ast3) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_mul(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast)
      end

      def mk_fpa_nan(sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_nan(_ctx_pointer, sort._ast)
      end

      def mk_fpa_neg(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_neg(_ctx_pointer, ast._ast)
      end

      def mk_fpa_numeral_double(double, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_numeral_double(_ctx_pointer, double, sort._ast)
      end

      def mk_fpa_numeral_float(float, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_numeral_float(_ctx_pointer, float, sort._ast)
      end

      def mk_fpa_numeral_int(num, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_numeral_int(_ctx_pointer, num, sort._ast)
      end

      def mk_fpa_numeral_int64_uint64(bool, num1, num2, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_numeral_int64_uint64(_ctx_pointer, bool, num1, num2, sort._ast)
      end

      def mk_fpa_numeral_int_uint(bool, num1, num2, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_numeral_int_uint(_ctx_pointer, bool, num1, num2, sort._ast)
      end

      def mk_fpa_rem(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_rem(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_fpa_rna #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_rna(_ctx_pointer)
      end

      def mk_fpa_rne #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_rne(_ctx_pointer)
      end

      def mk_fpa_round_nearest_ties_to_away #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_round_nearest_ties_to_away(_ctx_pointer)
      end

      def mk_fpa_round_nearest_ties_to_even #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_round_nearest_ties_to_even(_ctx_pointer)
      end

      def mk_fpa_round_to_integral(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_round_to_integral(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_fpa_round_toward_negative #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_round_toward_negative(_ctx_pointer)
      end

      def mk_fpa_round_toward_positive #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_round_toward_positive(_ctx_pointer)
      end

      def mk_fpa_round_toward_zero #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_round_toward_zero(_ctx_pointer)
      end

      def mk_fpa_rounding_mode_sort #=> :sort_pointer
        VeryLowLevel.Z3_mk_fpa_rounding_mode_sort(_ctx_pointer)
      end

      def mk_fpa_rtn #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_rtn(_ctx_pointer)
      end

      def mk_fpa_rtp #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_rtp(_ctx_pointer)
      end

      def mk_fpa_rtz #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_rtz(_ctx_pointer)
      end

      def mk_fpa_sort(num1, num2) #=> :sort_pointer
        VeryLowLevel.Z3_mk_fpa_sort(_ctx_pointer, num1, num2)
      end

      def mk_fpa_sort_128 #=> :sort_pointer
        VeryLowLevel.Z3_mk_fpa_sort_128(_ctx_pointer)
      end

      def mk_fpa_sort_16 #=> :sort_pointer
        VeryLowLevel.Z3_mk_fpa_sort_16(_ctx_pointer)
      end

      def mk_fpa_sort_32 #=> :sort_pointer
        VeryLowLevel.Z3_mk_fpa_sort_32(_ctx_pointer)
      end

      def mk_fpa_sort_64 #=> :sort_pointer
        VeryLowLevel.Z3_mk_fpa_sort_64(_ctx_pointer)
      end

      def mk_fpa_sort_double #=> :sort_pointer
        VeryLowLevel.Z3_mk_fpa_sort_double(_ctx_pointer)
      end

      def mk_fpa_sort_half #=> :sort_pointer
        VeryLowLevel.Z3_mk_fpa_sort_half(_ctx_pointer)
      end

      def mk_fpa_sort_quadruple #=> :sort_pointer
        VeryLowLevel.Z3_mk_fpa_sort_quadruple(_ctx_pointer)
      end

      def mk_fpa_sort_single #=> :sort_pointer
        VeryLowLevel.Z3_mk_fpa_sort_single(_ctx_pointer)
      end

      def mk_fpa_sqrt(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_sqrt(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_fpa_sub(ast1, ast2, ast3) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_sub(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast)
      end

      def mk_fpa_to_fp_bv(ast, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_to_fp_bv(_ctx_pointer, ast._ast, sort._ast)
      end

      def mk_fpa_to_fp_float(ast1, ast2, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_to_fp_float(_ctx_pointer, ast1._ast, ast2._ast, sort._ast)
      end

      def mk_fpa_to_fp_int_real(ast1, ast2, ast3, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_to_fp_int_real(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast, sort._ast)
      end

      def mk_fpa_to_fp_real(ast1, ast2, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_to_fp_real(_ctx_pointer, ast1._ast, ast2._ast, sort._ast)
      end

      def mk_fpa_to_fp_signed(ast1, ast2, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_to_fp_signed(_ctx_pointer, ast1._ast, ast2._ast, sort._ast)
      end

      def mk_fpa_to_fp_unsigned(ast1, ast2, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_to_fp_unsigned(_ctx_pointer, ast1._ast, ast2._ast, sort._ast)
      end

      def mk_fpa_to_ieee_bv(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_to_ieee_bv(_ctx_pointer, ast._ast)
      end

      def mk_fpa_to_real(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_to_real(_ctx_pointer, ast._ast)
      end

      def mk_fpa_to_sbv(ast1, ast2, num) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_to_sbv(_ctx_pointer, ast1._ast, ast2._ast, num)
      end

      def mk_fpa_to_ubv(ast1, ast2, num) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_to_ubv(_ctx_pointer, ast1._ast, ast2._ast, num)
      end

      def mk_fpa_zero(sort, bool) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fpa_zero(_ctx_pointer, sort._ast, bool)
      end

      def mk_fresh_const(str, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_fresh_const(_ctx_pointer, str, sort._ast)
      end

      def mk_full_set(sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_full_set(_ctx_pointer, sort._ast)
      end

      def mk_ge(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_ge(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_goal(bool1, bool2, bool3) #=> :goal_pointer
        VeryLowLevel.Z3_mk_goal(_ctx_pointer, bool1, bool2, bool3)
      end

      def mk_gt(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_gt(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_iff(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_iff(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_implies(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_implies(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_int(num, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_int(_ctx_pointer, num, sort._ast)
      end

      def mk_int2bv(num, ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_int2bv(_ctx_pointer, num, ast._ast)
      end

      def mk_int2real(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_int2real(_ctx_pointer, ast._ast)
      end

      def mk_int64(num, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_int64(_ctx_pointer, num, sort._ast)
      end

      def mk_int_sort #=> :sort_pointer
        VeryLowLevel.Z3_mk_int_sort(_ctx_pointer)
      end

      def mk_int_symbol(num) #=> :symbol_pointer
        VeryLowLevel.Z3_mk_int_symbol(_ctx_pointer, num)
      end

      def mk_interpolant(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_interpolant(_ctx_pointer, ast._ast)
      end

      def mk_interpolation_context(config) #=> :ctx_pointer
        VeryLowLevel.Z3_mk_interpolation_context(config._config)
      end

      def mk_is_int(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_is_int(_ctx_pointer, ast._ast)
      end

      def mk_ite(ast1, ast2, ast3) #=> :ast_pointer
        VeryLowLevel.Z3_mk_ite(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast)
      end

      def mk_le(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_le(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_lt(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_lt(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_mod(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_mod(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_not(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_not(_ctx_pointer, ast._ast)
      end

      def mk_numeral(str, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_numeral(_ctx_pointer, str, sort._ast)
      end

      def mk_optimize #=> :optimize_pointer
        VeryLowLevel.Z3_mk_optimize(_ctx_pointer)
      end

      def mk_params #=> :params_pointer
        VeryLowLevel.Z3_mk_params(_ctx_pointer)
      end

      def mk_power(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_power(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_probe(str) #=> :probe_pointer
        VeryLowLevel.Z3_mk_probe(_ctx_pointer, str)
      end

      def mk_real(num1, num2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_real(_ctx_pointer, num1, num2)
      end

      def mk_real2int(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_real2int(_ctx_pointer, ast._ast)
      end

      def mk_real_sort #=> :sort_pointer
        VeryLowLevel.Z3_mk_real_sort(_ctx_pointer)
      end

      def mk_rem(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_rem(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_repeat(num, ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_repeat(_ctx_pointer, num, ast._ast)
      end

      def mk_rotate_left(num, ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_rotate_left(_ctx_pointer, num, ast._ast)
      end

      def mk_rotate_right(num, ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_rotate_right(_ctx_pointer, num, ast._ast)
      end

      def mk_select(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_select(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_set_add(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_set_add(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_set_complement(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_set_complement(_ctx_pointer, ast._ast)
      end

      def mk_set_del(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_set_del(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_set_difference(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_set_difference(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_set_member(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_set_member(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_set_sort(sort) #=> :sort_pointer
        VeryLowLevel.Z3_mk_set_sort(_ctx_pointer, sort._ast)
      end

      def mk_set_subset(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_set_subset(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_sign_ext(num, ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_sign_ext(_ctx_pointer, num, ast._ast)
      end

      def mk_simple_solver #=> :solver_pointer
        VeryLowLevel.Z3_mk_simple_solver(_ctx_pointer)
      end

      def mk_solver #=> :solver_pointer
        VeryLowLevel.Z3_mk_solver(_ctx_pointer)
      end

      def mk_solver_for_logic(sym) #=> :solver_pointer
        VeryLowLevel.Z3_mk_solver_for_logic(_ctx_pointer, sym)
      end

      def mk_solver_from_tactic(tactic) #=> :solver_pointer
        VeryLowLevel.Z3_mk_solver_from_tactic(_ctx_pointer, tactic._tactic)
      end

      def mk_store(ast1, ast2, ast3) #=> :ast_pointer
        VeryLowLevel.Z3_mk_store(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast)
      end

      def mk_string_symbol(str) #=> :symbol_pointer
        VeryLowLevel.Z3_mk_string_symbol(_ctx_pointer, str)
      end

      def mk_tactic(str) #=> :tactic_pointer
        VeryLowLevel.Z3_mk_tactic(_ctx_pointer, str)
      end

      def mk_true #=> :ast_pointer
        VeryLowLevel.Z3_mk_true(_ctx_pointer)
      end

      def mk_unary_minus(ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_unary_minus(_ctx_pointer, ast._ast)
      end

      def mk_uninterpreted_sort(sym) #=> :sort_pointer
        VeryLowLevel.Z3_mk_uninterpreted_sort(_ctx_pointer, sym)
      end

      def mk_unsigned_int(num, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_unsigned_int(_ctx_pointer, num, sort._ast)
      end

      def mk_unsigned_int64(num, sort) #=> :ast_pointer
        VeryLowLevel.Z3_mk_unsigned_int64(_ctx_pointer, num, sort._ast)
      end

      def mk_xor(ast1, ast2) #=> :ast_pointer
        VeryLowLevel.Z3_mk_xor(_ctx_pointer, ast1._ast, ast2._ast)
      end

      def mk_zero_ext(num, ast) #=> :ast_pointer
        VeryLowLevel.Z3_mk_zero_ext(_ctx_pointer, num, ast._ast)
      end

      def model_dec_ref(model) #=> :void
        VeryLowLevel.Z3_model_dec_ref(_ctx_pointer, model._model)
      end

      def model_get_const_decl(model, num) #=> :func_decl_pointer
        VeryLowLevel.Z3_model_get_const_decl(_ctx_pointer, model._model, num)
      end

      def model_get_const_interp(model, func_decl) #=> :ast_pointer
        VeryLowLevel.Z3_model_get_const_interp(_ctx_pointer, model._model, func_decl._ast)
      end

      def model_get_func_decl(model, num) #=> :func_decl_pointer
        VeryLowLevel.Z3_model_get_func_decl(_ctx_pointer, model._model, num)
      end

      def model_get_func_interp(model, func_decl) #=> :func_interp_pointer
        VeryLowLevel.Z3_model_get_func_interp(_ctx_pointer, model._model, func_decl._ast)
      end

      def model_get_num_consts(model) #=> :uint
        VeryLowLevel.Z3_model_get_num_consts(_ctx_pointer, model._model)
      end

      def model_get_num_funcs(model) #=> :uint
        VeryLowLevel.Z3_model_get_num_funcs(_ctx_pointer, model._model)
      end

      def model_get_num_sorts(model) #=> :uint
        VeryLowLevel.Z3_model_get_num_sorts(_ctx_pointer, model._model)
      end

      def model_get_sort(model, num) #=> :sort_pointer
        VeryLowLevel.Z3_model_get_sort(_ctx_pointer, model._model, num)
      end

      def model_get_sort_universe(model, sort) #=> :ast_vector_pointer
        VeryLowLevel.Z3_model_get_sort_universe(_ctx_pointer, model._model, sort._ast)
      end

      def model_has_interp(model, func_decl) #=> :bool
        VeryLowLevel.Z3_model_has_interp(_ctx_pointer, model._model, func_decl._ast)
      end

      def model_inc_ref(model) #=> :void
        VeryLowLevel.Z3_model_inc_ref(_ctx_pointer, model._model)
      end

      def model_to_string(model) #=> :string
        VeryLowLevel.Z3_model_to_string(_ctx_pointer, model._model)
      end

      def optimize_assert(optimize, ast) #=> :void
        VeryLowLevel.Z3_optimize_assert(_ctx_pointer, optimize._optimize, ast._ast)
      end

      def optimize_assert_soft(optimize, ast, str, sym) #=> :uint
        VeryLowLevel.Z3_optimize_assert_soft(_ctx_pointer, optimize._optimize, ast._ast, str, sym)
      end

      def optimize_check(optimize) #=> :int
        VeryLowLevel.Z3_optimize_check(_ctx_pointer, optimize._optimize)
      end

      def optimize_dec_ref(optimize) #=> :void
        VeryLowLevel.Z3_optimize_dec_ref(_ctx_pointer, optimize._optimize)
      end

      def optimize_get_help(optimize) #=> :string
        VeryLowLevel.Z3_optimize_get_help(_ctx_pointer, optimize._optimize)
      end

      def optimize_get_lower(optimize, num) #=> :ast_pointer
        VeryLowLevel.Z3_optimize_get_lower(_ctx_pointer, optimize._optimize, num)
      end

      def optimize_get_model(optimize) #=> :model_pointer
        VeryLowLevel.Z3_optimize_get_model(_ctx_pointer, optimize._optimize)
      end

      def optimize_get_param_descrs(optimize) #=> :param_descrs_pointer
        VeryLowLevel.Z3_optimize_get_param_descrs(_ctx_pointer, optimize._optimize)
      end

      def optimize_get_reason_unknown(optimize) #=> :string
        VeryLowLevel.Z3_optimize_get_reason_unknown(_ctx_pointer, optimize._optimize)
      end

      def optimize_get_statistics(optimize) #=> :stats_pointer
        VeryLowLevel.Z3_optimize_get_statistics(_ctx_pointer, optimize._optimize)
      end

      def optimize_get_upper(optimize, num) #=> :ast_pointer
        VeryLowLevel.Z3_optimize_get_upper(_ctx_pointer, optimize._optimize, num)
      end

      def optimize_inc_ref(optimize) #=> :void
        VeryLowLevel.Z3_optimize_inc_ref(_ctx_pointer, optimize._optimize)
      end

      def optimize_maximize(optimize, ast) #=> :uint
        VeryLowLevel.Z3_optimize_maximize(_ctx_pointer, optimize._optimize, ast._ast)
      end

      def optimize_minimize(optimize, ast) #=> :uint
        VeryLowLevel.Z3_optimize_minimize(_ctx_pointer, optimize._optimize, ast._ast)
      end

      def optimize_pop(optimize) #=> :void
        VeryLowLevel.Z3_optimize_pop(_ctx_pointer, optimize._optimize)
      end

      def optimize_push(optimize) #=> :void
        VeryLowLevel.Z3_optimize_push(_ctx_pointer, optimize._optimize)
      end

      def optimize_set_params(optimize, params) #=> :void
        VeryLowLevel.Z3_optimize_set_params(_ctx_pointer, optimize._optimize, params._params)
      end

      def optimize_to_string(optimize) #=> :string
        VeryLowLevel.Z3_optimize_to_string(_ctx_pointer, optimize._optimize)
      end

      def param_descrs_dec_ref(param_descrs) #=> :void
        VeryLowLevel.Z3_param_descrs_dec_ref(_ctx_pointer, param_descrs._param_descrs)
      end

      def param_descrs_get_kind(param_descrs, sym) #=> :uint
        VeryLowLevel.Z3_param_descrs_get_kind(_ctx_pointer, param_descrs._param_descrs, sym)
      end

      def param_descrs_get_name(param_descrs, num) #=> :symbol_pointer
        VeryLowLevel.Z3_param_descrs_get_name(_ctx_pointer, param_descrs._param_descrs, num)
      end

      def param_descrs_inc_ref(param_descrs) #=> :void
        VeryLowLevel.Z3_param_descrs_inc_ref(_ctx_pointer, param_descrs._param_descrs)
      end

      def param_descrs_size(param_descrs) #=> :uint
        VeryLowLevel.Z3_param_descrs_size(_ctx_pointer, param_descrs._param_descrs)
      end

      def param_descrs_to_string(param_descrs) #=> :string
        VeryLowLevel.Z3_param_descrs_to_string(_ctx_pointer, param_descrs._param_descrs)
      end

      def params_dec_ref(params) #=> :void
        VeryLowLevel.Z3_params_dec_ref(_ctx_pointer, params._params)
      end

      def params_inc_ref(params) #=> :void
        VeryLowLevel.Z3_params_inc_ref(_ctx_pointer, params._params)
      end

      def params_set_bool(params, sym, bool) #=> :void
        VeryLowLevel.Z3_params_set_bool(_ctx_pointer, params._params, sym, bool)
      end

      def params_set_double(params, sym, double) #=> :void
        VeryLowLevel.Z3_params_set_double(_ctx_pointer, params._params, sym, double)
      end

      def params_set_symbol(params, sym1, sym2) #=> :void
        VeryLowLevel.Z3_params_set_symbol(_ctx_pointer, params._params, sym1, sym2)
      end

      def params_set_uint(params, sym, num) #=> :void
        VeryLowLevel.Z3_params_set_uint(_ctx_pointer, params._params, sym, num)
      end

      def params_to_string(params) #=> :string
        VeryLowLevel.Z3_params_to_string(_ctx_pointer, params._params)
      end

      def params_validate(params, param_descrs) #=> :void
        VeryLowLevel.Z3_params_validate(_ctx_pointer, params._params, param_descrs._param_descrs)
      end

      def pattern_to_string(pattern) #=> :string
        VeryLowLevel.Z3_pattern_to_string(_ctx_pointer, pattern._ast)
      end

      def polynomial_subresultants(ast1, ast2, ast3) #=> :ast_vector_pointer
        VeryLowLevel.Z3_polynomial_subresultants(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast)
      end

      def probe_and(probe1, probe2) #=> :probe_pointer
        VeryLowLevel.Z3_probe_and(_ctx_pointer, probe1._probe, probe2._probe)
      end

      def probe_apply(probe, goal) #=> :double
        VeryLowLevel.Z3_probe_apply(_ctx_pointer, probe._probe, goal._goal)
      end

      def probe_const(double) #=> :probe_pointer
        VeryLowLevel.Z3_probe_const(_ctx_pointer, double)
      end

      def probe_dec_ref(probe) #=> :void
        VeryLowLevel.Z3_probe_dec_ref(_ctx_pointer, probe._probe)
      end

      def probe_eq(probe1, probe2) #=> :probe_pointer
        VeryLowLevel.Z3_probe_eq(_ctx_pointer, probe1._probe, probe2._probe)
      end

      def probe_ge(probe1, probe2) #=> :probe_pointer
        VeryLowLevel.Z3_probe_ge(_ctx_pointer, probe1._probe, probe2._probe)
      end

      def probe_get_descr(str) #=> :string
        VeryLowLevel.Z3_probe_get_descr(_ctx_pointer, str)
      end

      def probe_gt(probe1, probe2) #=> :probe_pointer
        VeryLowLevel.Z3_probe_gt(_ctx_pointer, probe1._probe, probe2._probe)
      end

      def probe_inc_ref(probe) #=> :void
        VeryLowLevel.Z3_probe_inc_ref(_ctx_pointer, probe._probe)
      end

      def probe_le(probe1, probe2) #=> :probe_pointer
        VeryLowLevel.Z3_probe_le(_ctx_pointer, probe1._probe, probe2._probe)
      end

      def probe_lt(probe1, probe2) #=> :probe_pointer
        VeryLowLevel.Z3_probe_lt(_ctx_pointer, probe1._probe, probe2._probe)
      end

      def probe_not(probe) #=> :probe_pointer
        VeryLowLevel.Z3_probe_not(_ctx_pointer, probe._probe)
      end

      def probe_or(probe1, probe2) #=> :probe_pointer
        VeryLowLevel.Z3_probe_or(_ctx_pointer, probe1._probe, probe2._probe)
      end

      def rcf_add(num1, num2) #=> :rcf_num_pointer
        VeryLowLevel.Z3_rcf_add(_ctx_pointer, num1._rcf_num, num2._rcf_num)
      end

      def rcf_del(num) #=> :void
        VeryLowLevel.Z3_rcf_del(_ctx_pointer, num._rcf_num)
      end

      def rcf_div(num1, num2) #=> :rcf_num_pointer
        VeryLowLevel.Z3_rcf_div(_ctx_pointer, num1._rcf_num, num2._rcf_num)
      end

      def rcf_eq(num1, num2) #=> :bool
        VeryLowLevel.Z3_rcf_eq(_ctx_pointer, num1._rcf_num, num2._rcf_num)
      end

      def rcf_ge(num1, num2) #=> :bool
        VeryLowLevel.Z3_rcf_ge(_ctx_pointer, num1._rcf_num, num2._rcf_num)
      end

      def rcf_gt(num1, num2) #=> :bool
        VeryLowLevel.Z3_rcf_gt(_ctx_pointer, num1._rcf_num, num2._rcf_num)
      end

      def rcf_inv(num) #=> :rcf_num_pointer
        VeryLowLevel.Z3_rcf_inv(_ctx_pointer, num._rcf_num)
      end

      def rcf_le(num1, num2) #=> :bool
        VeryLowLevel.Z3_rcf_le(_ctx_pointer, num1._rcf_num, num2._rcf_num)
      end

      def rcf_lt(num1, num2) #=> :bool
        VeryLowLevel.Z3_rcf_lt(_ctx_pointer, num1._rcf_num, num2._rcf_num)
      end

      def rcf_mk_e #=> :rcf_num_pointer
        VeryLowLevel.Z3_rcf_mk_e(_ctx_pointer)
      end

      def rcf_mk_infinitesimal #=> :rcf_num_pointer
        VeryLowLevel.Z3_rcf_mk_infinitesimal(_ctx_pointer)
      end

      def rcf_mk_pi #=> :rcf_num_pointer
        VeryLowLevel.Z3_rcf_mk_pi(_ctx_pointer)
      end

      def rcf_mk_rational(str) #=> :rcf_num_pointer
        VeryLowLevel.Z3_rcf_mk_rational(_ctx_pointer, str)
      end

      def rcf_mk_small_int(num) #=> :rcf_num_pointer
        VeryLowLevel.Z3_rcf_mk_small_int(_ctx_pointer, num)
      end

      def rcf_mul(num1, num2) #=> :rcf_num_pointer
        VeryLowLevel.Z3_rcf_mul(_ctx_pointer, num1._rcf_num, num2._rcf_num)
      end

      def rcf_neg(num) #=> :rcf_num_pointer
        VeryLowLevel.Z3_rcf_neg(_ctx_pointer, num._rcf_num)
      end

      def rcf_neq(num1, num2) #=> :bool
        VeryLowLevel.Z3_rcf_neq(_ctx_pointer, num1._rcf_num, num2._rcf_num)
      end

      def rcf_num_to_decimal_string(num1, num2) #=> :string
        VeryLowLevel.Z3_rcf_num_to_decimal_string(_ctx_pointer, num1._rcf_num, num2)
      end

      def rcf_num_to_string(num, bool1, bool2) #=> :string
        VeryLowLevel.Z3_rcf_num_to_string(_ctx_pointer, num._rcf_num, bool1, bool2)
      end

      def rcf_power(num1, num2) #=> :rcf_num_pointer
        VeryLowLevel.Z3_rcf_power(_ctx_pointer, num1._rcf_num, num2)
      end

      def rcf_sub(num1, num2) #=> :rcf_num_pointer
        VeryLowLevel.Z3_rcf_sub(_ctx_pointer, num1._rcf_num, num2._rcf_num)
      end

      def reset_memory #=> :void
        VeryLowLevel.Z3_reset_memory()
      end

      def set_param_value(config, str1, str2) #=> :void
        VeryLowLevel.Z3_set_param_value(config._config, str1, str2)
      end

      def simplify(ast) #=> :ast_pointer
        VeryLowLevel.Z3_simplify(_ctx_pointer, ast._ast)
      end

      def simplify_ex(ast, params) #=> :ast_pointer
        VeryLowLevel.Z3_simplify_ex(_ctx_pointer, ast._ast, params._params)
      end

      def simplify_get_help #=> :string
        VeryLowLevel.Z3_simplify_get_help(_ctx_pointer)
      end

      def simplify_get_param_descrs #=> :param_descrs_pointer
        VeryLowLevel.Z3_simplify_get_param_descrs(_ctx_pointer)
      end

      def solver_assert(solver, ast) #=> :void
        VeryLowLevel.Z3_solver_assert(_ctx_pointer, solver._solver, ast._ast)
      end

      def solver_assert_and_track(solver, ast1, ast2) #=> :void
        VeryLowLevel.Z3_solver_assert_and_track(_ctx_pointer, solver._solver, ast1._ast, ast2._ast)
      end

      def solver_check(solver) #=> :int
        VeryLowLevel.Z3_solver_check(_ctx_pointer, solver._solver)
      end

      def solver_dec_ref(solver) #=> :void
        VeryLowLevel.Z3_solver_dec_ref(_ctx_pointer, solver._solver)
      end

      def solver_get_assertions(solver) #=> :ast_vector_pointer
        VeryLowLevel.Z3_solver_get_assertions(_ctx_pointer, solver._solver)
      end

      def solver_get_help(solver) #=> :string
        VeryLowLevel.Z3_solver_get_help(_ctx_pointer, solver._solver)
      end

      def solver_get_model(solver) #=> :model_pointer
        VeryLowLevel.Z3_solver_get_model(_ctx_pointer, solver._solver)
      end

      def solver_get_num_scopes(solver) #=> :uint
        VeryLowLevel.Z3_solver_get_num_scopes(_ctx_pointer, solver._solver)
      end

      def solver_get_param_descrs(solver) #=> :param_descrs_pointer
        VeryLowLevel.Z3_solver_get_param_descrs(_ctx_pointer, solver._solver)
      end

      def solver_get_proof(solver) #=> :ast_pointer
        VeryLowLevel.Z3_solver_get_proof(_ctx_pointer, solver._solver)
      end

      def solver_get_reason_unknown(solver) #=> :string
        VeryLowLevel.Z3_solver_get_reason_unknown(_ctx_pointer, solver._solver)
      end

      def solver_get_statistics(solver) #=> :stats_pointer
        VeryLowLevel.Z3_solver_get_statistics(_ctx_pointer, solver._solver)
      end

      def solver_get_unsat_core(solver) #=> :ast_vector_pointer
        VeryLowLevel.Z3_solver_get_unsat_core(_ctx_pointer, solver._solver)
      end

      def solver_inc_ref(solver) #=> :void
        VeryLowLevel.Z3_solver_inc_ref(_ctx_pointer, solver._solver)
      end

      def solver_pop(solver, num) #=> :void
        VeryLowLevel.Z3_solver_pop(_ctx_pointer, solver._solver, num)
      end

      def solver_push(solver) #=> :void
        VeryLowLevel.Z3_solver_push(_ctx_pointer, solver._solver)
      end

      def solver_reset(solver) #=> :void
        VeryLowLevel.Z3_solver_reset(_ctx_pointer, solver._solver)
      end

      def solver_set_params(solver, params) #=> :void
        VeryLowLevel.Z3_solver_set_params(_ctx_pointer, solver._solver, params._params)
      end

      def solver_to_string(solver) #=> :string
        VeryLowLevel.Z3_solver_to_string(_ctx_pointer, solver._solver)
      end

      def stats_dec_ref(stats) #=> :void
        VeryLowLevel.Z3_stats_dec_ref(_ctx_pointer, stats)
      end

      def stats_get_double_value(stats, num) #=> :double
        VeryLowLevel.Z3_stats_get_double_value(_ctx_pointer, stats, num)
      end

      def stats_get_key(stats, num) #=> :string
        VeryLowLevel.Z3_stats_get_key(_ctx_pointer, stats, num)
      end

      def stats_get_uint_value(stats, num) #=> :uint
        VeryLowLevel.Z3_stats_get_uint_value(_ctx_pointer, stats, num)
      end

      def stats_inc_ref(stats) #=> :void
        VeryLowLevel.Z3_stats_inc_ref(_ctx_pointer, stats)
      end

      def stats_is_double(stats, num) #=> :bool
        VeryLowLevel.Z3_stats_is_double(_ctx_pointer, stats, num)
      end

      def stats_is_uint(stats, num) #=> :bool
        VeryLowLevel.Z3_stats_is_uint(_ctx_pointer, stats, num)
      end

      def stats_size(stats) #=> :uint
        VeryLowLevel.Z3_stats_size(_ctx_pointer, stats)
      end

      def stats_to_string(stats) #=> :string
        VeryLowLevel.Z3_stats_to_string(_ctx_pointer, stats)
      end

      def tactic_and_then(tactic1, tactic2) #=> :tactic_pointer
        VeryLowLevel.Z3_tactic_and_then(_ctx_pointer, tactic1._tactic, tactic2._tactic)
      end

      def tactic_apply(tactic, goal) #=> :apply_result_pointer
        VeryLowLevel.Z3_tactic_apply(_ctx_pointer, tactic._tactic, goal._goal)
      end

      def tactic_apply_ex(tactic, goal, params) #=> :apply_result_pointer
        VeryLowLevel.Z3_tactic_apply_ex(_ctx_pointer, tactic._tactic, goal._goal, params._params)
      end

      def tactic_cond(probe, tactic1, tactic2) #=> :tactic_pointer
        VeryLowLevel.Z3_tactic_cond(_ctx_pointer, probe._probe, tactic1._tactic, tactic2._tactic)
      end

      def tactic_dec_ref(tactic) #=> :void
        VeryLowLevel.Z3_tactic_dec_ref(_ctx_pointer, tactic._tactic)
      end

      def tactic_fail #=> :tactic_pointer
        VeryLowLevel.Z3_tactic_fail(_ctx_pointer)
      end

      def tactic_fail_if(probe) #=> :tactic_pointer
        VeryLowLevel.Z3_tactic_fail_if(_ctx_pointer, probe._probe)
      end

      def tactic_fail_if_not_decided #=> :tactic_pointer
        VeryLowLevel.Z3_tactic_fail_if_not_decided(_ctx_pointer)
      end

      def tactic_get_descr(str) #=> :string
        VeryLowLevel.Z3_tactic_get_descr(_ctx_pointer, str)
      end

      def tactic_get_help(tactic) #=> :string
        VeryLowLevel.Z3_tactic_get_help(_ctx_pointer, tactic._tactic)
      end

      def tactic_get_param_descrs(tactic) #=> :param_descrs_pointer
        VeryLowLevel.Z3_tactic_get_param_descrs(_ctx_pointer, tactic._tactic)
      end

      def tactic_inc_ref(tactic) #=> :void
        VeryLowLevel.Z3_tactic_inc_ref(_ctx_pointer, tactic._tactic)
      end

      def tactic_or_else(tactic1, tactic2) #=> :tactic_pointer
        VeryLowLevel.Z3_tactic_or_else(_ctx_pointer, tactic1._tactic, tactic2._tactic)
      end

      def tactic_par_and_then(tactic1, tactic2) #=> :tactic_pointer
        VeryLowLevel.Z3_tactic_par_and_then(_ctx_pointer, tactic1._tactic, tactic2._tactic)
      end

      def tactic_repeat(tactic, num) #=> :tactic_pointer
        VeryLowLevel.Z3_tactic_repeat(_ctx_pointer, tactic._tactic, num)
      end

      def tactic_skip #=> :tactic_pointer
        VeryLowLevel.Z3_tactic_skip(_ctx_pointer)
      end

      def tactic_try_for(tactic, num) #=> :tactic_pointer
        VeryLowLevel.Z3_tactic_try_for(_ctx_pointer, tactic._tactic, num)
      end

      def tactic_using_params(tactic, params) #=> :tactic_pointer
        VeryLowLevel.Z3_tactic_using_params(_ctx_pointer, tactic._tactic, params._params)
      end

      def tactic_when(probe, tactic) #=> :tactic_pointer
        VeryLowLevel.Z3_tactic_when(_ctx_pointer, probe._probe, tactic._tactic)
      end

      def toggle_warning_messages(bool) #=> :void
        VeryLowLevel.Z3_toggle_warning_messages(bool)
      end

      def translate(ast, context) #=> :ast_pointer
        VeryLowLevel.Z3_translate(_ctx_pointer, ast._ast, context._context)
      end

      def update_param_value(str1, str2) #=> :void
        VeryLowLevel.Z3_update_param_value(_ctx_pointer, str1, str2)
      end
    end
  end
end
