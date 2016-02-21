def algebraic_add(ast1, ast2)
  Z3::VeryLowLevel.Z3_algebraic_add(_ctx_pointer, ast1._ast, ast2._ast)
end

def algebraic_div(ast1, ast2)
  Z3::VeryLowLevel.Z3_algebraic_div(_ctx_pointer, ast1._ast, ast2._ast)
end

def algebraic_eq(ast1, ast2)
  Z3::VeryLowLevel.Z3_algebraic_eq(_ctx_pointer, ast1._ast, ast2._ast)
end

def algebraic_ge(ast1, ast2)
  Z3::VeryLowLevel.Z3_algebraic_ge(_ctx_pointer, ast1._ast, ast2._ast)
end

def algebraic_gt(ast1, ast2)
  Z3::VeryLowLevel.Z3_algebraic_gt(_ctx_pointer, ast1._ast, ast2._ast)
end

def algebraic_is_neg(ast)
  Z3::VeryLowLevel.Z3_algebraic_is_neg(_ctx_pointer, ast._ast)
end

def algebraic_is_pos(ast)
  Z3::VeryLowLevel.Z3_algebraic_is_pos(_ctx_pointer, ast._ast)
end

def algebraic_is_value(ast)
  Z3::VeryLowLevel.Z3_algebraic_is_value(_ctx_pointer, ast._ast)
end

def algebraic_is_zero(ast)
  Z3::VeryLowLevel.Z3_algebraic_is_zero(_ctx_pointer, ast._ast)
end

def algebraic_le(ast1, ast2)
  Z3::VeryLowLevel.Z3_algebraic_le(_ctx_pointer, ast1._ast, ast2._ast)
end

def algebraic_lt(ast1, ast2)
  Z3::VeryLowLevel.Z3_algebraic_lt(_ctx_pointer, ast1._ast, ast2._ast)
end

def algebraic_mul(ast1, ast2)
  Z3::VeryLowLevel.Z3_algebraic_mul(_ctx_pointer, ast1._ast, ast2._ast)
end

def algebraic_neq(ast1, ast2)
  Z3::VeryLowLevel.Z3_algebraic_neq(_ctx_pointer, ast1._ast, ast2._ast)
end

def algebraic_power(ast, num)
  Z3::VeryLowLevel.Z3_algebraic_power(_ctx_pointer, ast._ast, num)
end

def algebraic_root(ast, num)
  Z3::VeryLowLevel.Z3_algebraic_root(_ctx_pointer, ast._ast, num)
end

def algebraic_sign(ast)
  Z3::VeryLowLevel.Z3_algebraic_sign(_ctx_pointer, ast._ast)
end

def algebraic_sub(ast1, ast2)
  Z3::VeryLowLevel.Z3_algebraic_sub(_ctx_pointer, ast1._ast, ast2._ast)
end

def ast_to_string(ast)
  Z3::VeryLowLevel.Z3_ast_to_string(_ctx_pointer, ast._ast)
end

def datatype_update_field(func_decl, ast1, ast2)
  Z3::VeryLowLevel.Z3_datatype_update_field(_ctx_pointer, func_decl._func_decl, ast1._ast, ast2._ast)
end

def dec_ref(ast)
  Z3::VeryLowLevel.Z3_dec_ref(_ctx_pointer, ast._ast)
end

def del_context
  Z3::VeryLowLevel.Z3_del_context(_ctx_pointer)
end

def disable_trace(str)
  Z3::VeryLowLevel.Z3_disable_trace(str)
end

def enable_trace(str)
  Z3::VeryLowLevel.Z3_enable_trace(str)
end

def finalize_memory
  Z3::VeryLowLevel.Z3_finalize_memory()
end

def fpa_get_ebits(sort)
  Z3::VeryLowLevel.Z3_fpa_get_ebits(_ctx_pointer, sort._sort)
end

def fpa_get_numeral_exponent_string(ast)
  Z3::VeryLowLevel.Z3_fpa_get_numeral_exponent_string(_ctx_pointer, ast._ast)
end

def fpa_get_numeral_significand_string(ast)
  Z3::VeryLowLevel.Z3_fpa_get_numeral_significand_string(_ctx_pointer, ast._ast)
end

def fpa_get_sbits(sort)
  Z3::VeryLowLevel.Z3_fpa_get_sbits(_ctx_pointer, sort._sort)
end

def get_algebraic_number_lower(ast, num)
  Z3::VeryLowLevel.Z3_get_algebraic_number_lower(_ctx_pointer, ast._ast, num)
end

def get_algebraic_number_upper(ast, num)
  Z3::VeryLowLevel.Z3_get_algebraic_number_upper(_ctx_pointer, ast._ast, num)
end

def get_array_sort_domain(sort)
  Z3::VeryLowLevel.Z3_get_array_sort_domain(_ctx_pointer, sort._sort)
end

def get_array_sort_range(sort)
  Z3::VeryLowLevel.Z3_get_array_sort_range(_ctx_pointer, sort._sort)
end

def get_as_array_func_decl(ast)
  Z3::VeryLowLevel.Z3_get_as_array_func_decl(_ctx_pointer, ast._ast)
end

def get_ast_hash(ast)
  Z3::VeryLowLevel.Z3_get_ast_hash(_ctx_pointer, ast._ast)
end

def get_ast_id(ast)
  Z3::VeryLowLevel.Z3_get_ast_id(_ctx_pointer, ast._ast)
end

def get_ast_kind(ast)
  Z3::VeryLowLevel.Z3_get_ast_kind(_ctx_pointer, ast._ast)
end

def get_bool_value(ast)
  Z3::VeryLowLevel.Z3_get_bool_value(_ctx_pointer, ast._ast)
end

def get_bv_sort_size(sort)
  Z3::VeryLowLevel.Z3_get_bv_sort_size(_ctx_pointer, sort._sort)
end

def get_datatype_sort_constructor(sort, num)
  Z3::VeryLowLevel.Z3_get_datatype_sort_constructor(_ctx_pointer, sort._sort, num)
end

def get_datatype_sort_num_constructors(sort)
  Z3::VeryLowLevel.Z3_get_datatype_sort_num_constructors(_ctx_pointer, sort._sort)
end

def get_datatype_sort_recognizer(sort, num)
  Z3::VeryLowLevel.Z3_get_datatype_sort_recognizer(_ctx_pointer, sort._sort, num)
end

def get_denominator(ast)
  Z3::VeryLowLevel.Z3_get_denominator(_ctx_pointer, ast._ast)
end

def get_error_code
  Z3::VeryLowLevel.Z3_get_error_code(_ctx_pointer)
end

def get_index_value(ast)
  Z3::VeryLowLevel.Z3_get_index_value(_ctx_pointer, ast._ast)
end

def get_num_probes
  Z3::VeryLowLevel.Z3_get_num_probes(_ctx_pointer)
end

def get_num_tactics
  Z3::VeryLowLevel.Z3_get_num_tactics(_ctx_pointer)
end

def get_numeral_decimal_string(ast, num)
  Z3::VeryLowLevel.Z3_get_numeral_decimal_string(_ctx_pointer, ast._ast, num)
end

def get_numeral_string(ast)
  Z3::VeryLowLevel.Z3_get_numeral_string(_ctx_pointer, ast._ast)
end

def get_numerator(ast)
  Z3::VeryLowLevel.Z3_get_numerator(_ctx_pointer, ast._ast)
end

def get_pattern_num_terms(pattern)
  Z3::VeryLowLevel.Z3_get_pattern_num_terms(_ctx_pointer, pattern._pattern)
end

def get_probe_name(num)
  Z3::VeryLowLevel.Z3_get_probe_name(_ctx_pointer, num)
end

def get_quantifier_body(ast)
  Z3::VeryLowLevel.Z3_get_quantifier_body(_ctx_pointer, ast._ast)
end

def get_quantifier_bound_name(ast, num)
  Z3::VeryLowLevel.Z3_get_quantifier_bound_name(_ctx_pointer, ast._ast, num)
end

def get_quantifier_bound_sort(ast, num)
  Z3::VeryLowLevel.Z3_get_quantifier_bound_sort(_ctx_pointer, ast._ast, num)
end

def get_quantifier_no_pattern_ast(ast, num)
  Z3::VeryLowLevel.Z3_get_quantifier_no_pattern_ast(_ctx_pointer, ast._ast, num)
end

def get_quantifier_num_bound(ast)
  Z3::VeryLowLevel.Z3_get_quantifier_num_bound(_ctx_pointer, ast._ast)
end

def get_quantifier_num_no_patterns(ast)
  Z3::VeryLowLevel.Z3_get_quantifier_num_no_patterns(_ctx_pointer, ast._ast)
end

def get_quantifier_num_patterns(ast)
  Z3::VeryLowLevel.Z3_get_quantifier_num_patterns(_ctx_pointer, ast._ast)
end

def get_quantifier_pattern_ast(ast, num)
  Z3::VeryLowLevel.Z3_get_quantifier_pattern_ast(_ctx_pointer, ast._ast, num)
end

def get_quantifier_weight(ast)
  Z3::VeryLowLevel.Z3_get_quantifier_weight(_ctx_pointer, ast._ast)
end

def get_relation_arity(sort)
  Z3::VeryLowLevel.Z3_get_relation_arity(_ctx_pointer, sort._sort)
end

def get_relation_column(sort, num)
  Z3::VeryLowLevel.Z3_get_relation_column(_ctx_pointer, sort._sort, num)
end

def get_smtlib_assumption(num)
  Z3::VeryLowLevel.Z3_get_smtlib_assumption(_ctx_pointer, num)
end

def get_smtlib_decl(num)
  Z3::VeryLowLevel.Z3_get_smtlib_decl(_ctx_pointer, num)
end

def get_smtlib_error
  Z3::VeryLowLevel.Z3_get_smtlib_error(_ctx_pointer)
end

def get_smtlib_formula(num)
  Z3::VeryLowLevel.Z3_get_smtlib_formula(_ctx_pointer, num)
end

def get_smtlib_num_assumptions
  Z3::VeryLowLevel.Z3_get_smtlib_num_assumptions(_ctx_pointer)
end

def get_smtlib_num_decls
  Z3::VeryLowLevel.Z3_get_smtlib_num_decls(_ctx_pointer)
end

def get_smtlib_num_formulas
  Z3::VeryLowLevel.Z3_get_smtlib_num_formulas(_ctx_pointer)
end

def get_smtlib_num_sorts
  Z3::VeryLowLevel.Z3_get_smtlib_num_sorts(_ctx_pointer)
end

def get_smtlib_sort(num)
  Z3::VeryLowLevel.Z3_get_smtlib_sort(_ctx_pointer, num)
end

def get_sort(ast)
  Z3::VeryLowLevel.Z3_get_sort(_ctx_pointer, ast._ast)
end

def get_sort_id(sort)
  Z3::VeryLowLevel.Z3_get_sort_id(_ctx_pointer, sort._sort)
end

def get_sort_kind(sort)
  Z3::VeryLowLevel.Z3_get_sort_kind(_ctx_pointer, sort._sort)
end

def get_sort_name(sort)
  Z3::VeryLowLevel.Z3_get_sort_name(_ctx_pointer, sort._sort)
end

def get_symbol_int(symbol)
  Z3::VeryLowLevel.Z3_get_symbol_int(_ctx_pointer, symbol)
end

def get_symbol_kind(symbol)
  Z3::VeryLowLevel.Z3_get_symbol_kind(_ctx_pointer, symbol)
end

def get_symbol_string(symbol)
  Z3::VeryLowLevel.Z3_get_symbol_string(_ctx_pointer, symbol)
end

def get_tactic_name(num)
  Z3::VeryLowLevel.Z3_get_tactic_name(_ctx_pointer, num)
end

def get_tuple_sort_field_decl(sort, num)
  Z3::VeryLowLevel.Z3_get_tuple_sort_field_decl(_ctx_pointer, sort._sort, num)
end

def get_tuple_sort_mk_decl(sort)
  Z3::VeryLowLevel.Z3_get_tuple_sort_mk_decl(_ctx_pointer, sort._sort)
end

def get_tuple_sort_num_fields(sort)
  Z3::VeryLowLevel.Z3_get_tuple_sort_num_fields(_ctx_pointer, sort._sort)
end

def global_param_reset_all
  Z3::VeryLowLevel.Z3_global_param_reset_all()
end

def global_param_set(str1, str2)
  Z3::VeryLowLevel.Z3_global_param_set(str1, str2)
end

def goal_dec_ref(goal)
  Z3::VeryLowLevel.Z3_goal_dec_ref(_ctx_pointer, goal._goal)
end

def goal_depth(goal)
  Z3::VeryLowLevel.Z3_goal_depth(_ctx_pointer, goal._goal)
end

def goal_inc_ref(goal)
  Z3::VeryLowLevel.Z3_goal_inc_ref(_ctx_pointer, goal._goal)
end

def goal_inconsistent(goal)
  Z3::VeryLowLevel.Z3_goal_inconsistent(_ctx_pointer, goal._goal)
end

def goal_is_decided_sat(goal)
  Z3::VeryLowLevel.Z3_goal_is_decided_sat(_ctx_pointer, goal._goal)
end

def goal_is_decided_unsat(goal)
  Z3::VeryLowLevel.Z3_goal_is_decided_unsat(_ctx_pointer, goal._goal)
end

def goal_num_exprs(goal)
  Z3::VeryLowLevel.Z3_goal_num_exprs(_ctx_pointer, goal._goal)
end

def goal_precision(goal)
  Z3::VeryLowLevel.Z3_goal_precision(_ctx_pointer, goal._goal)
end

def goal_reset(goal)
  Z3::VeryLowLevel.Z3_goal_reset(_ctx_pointer, goal._goal)
end

def goal_size(goal)
  Z3::VeryLowLevel.Z3_goal_size(_ctx_pointer, goal._goal)
end

def goal_to_string(goal)
  Z3::VeryLowLevel.Z3_goal_to_string(_ctx_pointer, goal._goal)
end

def inc_ref(ast)
  Z3::VeryLowLevel.Z3_inc_ref(_ctx_pointer, ast._ast)
end

def interpolation_profile
  Z3::VeryLowLevel.Z3_interpolation_profile(_ctx_pointer)
end

def interrupt
  Z3::VeryLowLevel.Z3_interrupt(_ctx_pointer)
end

def is_algebraic_number(ast)
  Z3::VeryLowLevel.Z3_is_algebraic_number(_ctx_pointer, ast._ast)
end

def is_app(ast)
  Z3::VeryLowLevel.Z3_is_app(_ctx_pointer, ast._ast)
end

def is_as_array(ast)
  Z3::VeryLowLevel.Z3_is_as_array(_ctx_pointer, ast._ast)
end

def is_eq_ast(ast1, ast2)
  Z3::VeryLowLevel.Z3_is_eq_ast(_ctx_pointer, ast1._ast, ast2._ast)
end

def is_eq_sort(sort1, sort2)
  Z3::VeryLowLevel.Z3_is_eq_sort(_ctx_pointer, sort1._sort, sort2._sort)
end

def is_numeral_ast(ast)
  Z3::VeryLowLevel.Z3_is_numeral_ast(_ctx_pointer, ast._ast)
end

def is_quantifier_forall(ast)
  Z3::VeryLowLevel.Z3_is_quantifier_forall(_ctx_pointer, ast._ast)
end

def is_well_sorted(ast)
  Z3::VeryLowLevel.Z3_is_well_sorted(_ctx_pointer, ast._ast)
end

def mk_array_default(ast)
  Z3::VeryLowLevel.Z3_mk_array_default(_ctx_pointer, ast._ast)
end

def mk_array_sort(sort1, sort2)
  Z3::VeryLowLevel.Z3_mk_array_sort(_ctx_pointer, sort1._sort, sort2._sort)
end

def mk_bool_sort
  Z3::VeryLowLevel.Z3_mk_bool_sort(_ctx_pointer)
end

def mk_bv_sort(num)
  Z3::VeryLowLevel.Z3_mk_bv_sort(_ctx_pointer, num)
end

def mk_bvadd(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvadd(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvadd_no_underflow(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvadd_no_underflow(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvand(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvand(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvashr(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvashr(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvlshr(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvlshr(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvmul(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvmul(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvmul_no_underflow(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvmul_no_underflow(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvnand(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvnand(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvneg(ast)
  Z3::VeryLowLevel.Z3_mk_bvneg(_ctx_pointer, ast._ast)
end

def mk_bvneg_no_overflow(ast)
  Z3::VeryLowLevel.Z3_mk_bvneg_no_overflow(_ctx_pointer, ast._ast)
end

def mk_bvnor(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvnor(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvnot(ast)
  Z3::VeryLowLevel.Z3_mk_bvnot(_ctx_pointer, ast._ast)
end

def mk_bvor(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvor(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvredand(ast)
  Z3::VeryLowLevel.Z3_mk_bvredand(_ctx_pointer, ast._ast)
end

def mk_bvredor(ast)
  Z3::VeryLowLevel.Z3_mk_bvredor(_ctx_pointer, ast._ast)
end

def mk_bvsdiv(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvsdiv(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvsdiv_no_overflow(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvsdiv_no_overflow(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvsge(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvsge(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvsgt(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvsgt(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvshl(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvshl(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvsle(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvsle(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvslt(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvslt(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvsmod(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvsmod(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvsrem(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvsrem(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvsub(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvsub(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvsub_no_overflow(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvsub_no_overflow(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvudiv(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvudiv(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvuge(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvuge(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvugt(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvugt(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvule(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvule(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvult(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvult(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvurem(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvurem(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvxnor(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvxnor(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_bvxor(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_bvxor(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_concat(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_concat(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_const(symbol, sort)
  Z3::VeryLowLevel.Z3_mk_const(_ctx_pointer, symbol, sort._sort)
end

def mk_div(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_div(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_empty_set(sort)
  Z3::VeryLowLevel.Z3_mk_empty_set(_ctx_pointer, sort._sort)
end

def mk_eq(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_eq(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_ext_rotate_left(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_ext_rotate_left(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_ext_rotate_right(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_ext_rotate_right(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_false
  Z3::VeryLowLevel.Z3_mk_false(_ctx_pointer)
end

def mk_fixedpoint
  Z3::VeryLowLevel.Z3_mk_fixedpoint(_ctx_pointer)
end

def mk_fpa_abs(ast)
  Z3::VeryLowLevel.Z3_mk_fpa_abs(_ctx_pointer, ast._ast)
end

def mk_fpa_add(ast1, ast2, ast3)
  Z3::VeryLowLevel.Z3_mk_fpa_add(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast)
end

def mk_fpa_div(ast1, ast2, ast3)
  Z3::VeryLowLevel.Z3_mk_fpa_div(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast)
end

def mk_fpa_eq(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_fpa_eq(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_fpa_fma(ast1, ast2, ast3, ast4)
  Z3::VeryLowLevel.Z3_mk_fpa_fma(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast, ast4._ast)
end

def mk_fpa_fp(ast1, ast2, ast3)
  Z3::VeryLowLevel.Z3_mk_fpa_fp(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast)
end

def mk_fpa_geq(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_fpa_geq(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_fpa_gt(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_fpa_gt(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_fpa_is_infinite(ast)
  Z3::VeryLowLevel.Z3_mk_fpa_is_infinite(_ctx_pointer, ast._ast)
end

def mk_fpa_is_nan(ast)
  Z3::VeryLowLevel.Z3_mk_fpa_is_nan(_ctx_pointer, ast._ast)
end

def mk_fpa_is_negative(ast)
  Z3::VeryLowLevel.Z3_mk_fpa_is_negative(_ctx_pointer, ast._ast)
end

def mk_fpa_is_normal(ast)
  Z3::VeryLowLevel.Z3_mk_fpa_is_normal(_ctx_pointer, ast._ast)
end

def mk_fpa_is_positive(ast)
  Z3::VeryLowLevel.Z3_mk_fpa_is_positive(_ctx_pointer, ast._ast)
end

def mk_fpa_is_subnormal(ast)
  Z3::VeryLowLevel.Z3_mk_fpa_is_subnormal(_ctx_pointer, ast._ast)
end

def mk_fpa_is_zero(ast)
  Z3::VeryLowLevel.Z3_mk_fpa_is_zero(_ctx_pointer, ast._ast)
end

def mk_fpa_leq(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_fpa_leq(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_fpa_lt(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_fpa_lt(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_fpa_max(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_fpa_max(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_fpa_min(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_fpa_min(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_fpa_mul(ast1, ast2, ast3)
  Z3::VeryLowLevel.Z3_mk_fpa_mul(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast)
end

def mk_fpa_nan(sort)
  Z3::VeryLowLevel.Z3_mk_fpa_nan(_ctx_pointer, sort._sort)
end

def mk_fpa_neg(ast)
  Z3::VeryLowLevel.Z3_mk_fpa_neg(_ctx_pointer, ast._ast)
end

def mk_fpa_rem(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_fpa_rem(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_fpa_rna
  Z3::VeryLowLevel.Z3_mk_fpa_rna(_ctx_pointer)
end

def mk_fpa_rne
  Z3::VeryLowLevel.Z3_mk_fpa_rne(_ctx_pointer)
end

def mk_fpa_round_nearest_ties_to_away
  Z3::VeryLowLevel.Z3_mk_fpa_round_nearest_ties_to_away(_ctx_pointer)
end

def mk_fpa_round_nearest_ties_to_even
  Z3::VeryLowLevel.Z3_mk_fpa_round_nearest_ties_to_even(_ctx_pointer)
end

def mk_fpa_round_to_integral(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_fpa_round_to_integral(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_fpa_round_toward_negative
  Z3::VeryLowLevel.Z3_mk_fpa_round_toward_negative(_ctx_pointer)
end

def mk_fpa_round_toward_positive
  Z3::VeryLowLevel.Z3_mk_fpa_round_toward_positive(_ctx_pointer)
end

def mk_fpa_round_toward_zero
  Z3::VeryLowLevel.Z3_mk_fpa_round_toward_zero(_ctx_pointer)
end

def mk_fpa_rounding_mode_sort
  Z3::VeryLowLevel.Z3_mk_fpa_rounding_mode_sort(_ctx_pointer)
end

def mk_fpa_rtn
  Z3::VeryLowLevel.Z3_mk_fpa_rtn(_ctx_pointer)
end

def mk_fpa_rtp
  Z3::VeryLowLevel.Z3_mk_fpa_rtp(_ctx_pointer)
end

def mk_fpa_rtz
  Z3::VeryLowLevel.Z3_mk_fpa_rtz(_ctx_pointer)
end

def mk_fpa_sort_128
  Z3::VeryLowLevel.Z3_mk_fpa_sort_128(_ctx_pointer)
end

def mk_fpa_sort_16
  Z3::VeryLowLevel.Z3_mk_fpa_sort_16(_ctx_pointer)
end

def mk_fpa_sort_32
  Z3::VeryLowLevel.Z3_mk_fpa_sort_32(_ctx_pointer)
end

def mk_fpa_sort_64
  Z3::VeryLowLevel.Z3_mk_fpa_sort_64(_ctx_pointer)
end

def mk_fpa_sort_double
  Z3::VeryLowLevel.Z3_mk_fpa_sort_double(_ctx_pointer)
end

def mk_fpa_sort_half
  Z3::VeryLowLevel.Z3_mk_fpa_sort_half(_ctx_pointer)
end

def mk_fpa_sort_quadruple
  Z3::VeryLowLevel.Z3_mk_fpa_sort_quadruple(_ctx_pointer)
end

def mk_fpa_sort_single
  Z3::VeryLowLevel.Z3_mk_fpa_sort_single(_ctx_pointer)
end

def mk_fpa_sqrt(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_fpa_sqrt(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_fpa_sub(ast1, ast2, ast3)
  Z3::VeryLowLevel.Z3_mk_fpa_sub(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast)
end

def mk_fpa_to_fp_float(ast1, ast2, sort)
  Z3::VeryLowLevel.Z3_mk_fpa_to_fp_float(_ctx_pointer, ast1._ast, ast2._ast, sort._sort)
end

def mk_fpa_to_fp_real(ast1, ast2, sort)
  Z3::VeryLowLevel.Z3_mk_fpa_to_fp_real(_ctx_pointer, ast1._ast, ast2._ast, sort._sort)
end

def mk_fpa_to_fp_signed(ast1, ast2, sort)
  Z3::VeryLowLevel.Z3_mk_fpa_to_fp_signed(_ctx_pointer, ast1._ast, ast2._ast, sort._sort)
end

def mk_fpa_to_fp_unsigned(ast1, ast2, sort)
  Z3::VeryLowLevel.Z3_mk_fpa_to_fp_unsigned(_ctx_pointer, ast1._ast, ast2._ast, sort._sort)
end

def mk_fpa_to_ieee_bv(ast)
  Z3::VeryLowLevel.Z3_mk_fpa_to_ieee_bv(_ctx_pointer, ast._ast)
end

def mk_fpa_to_real(ast)
  Z3::VeryLowLevel.Z3_mk_fpa_to_real(_ctx_pointer, ast._ast)
end

def mk_fresh_const(str, sort)
  Z3::VeryLowLevel.Z3_mk_fresh_const(_ctx_pointer, str, sort._sort)
end

def mk_full_set(sort)
  Z3::VeryLowLevel.Z3_mk_full_set(_ctx_pointer, sort._sort)
end

def mk_ge(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_ge(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_gt(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_gt(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_iff(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_iff(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_implies(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_implies(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_int2real(ast)
  Z3::VeryLowLevel.Z3_mk_int2real(_ctx_pointer, ast._ast)
end

def mk_int_sort
  Z3::VeryLowLevel.Z3_mk_int_sort(_ctx_pointer)
end

def mk_interpolant(ast)
  Z3::VeryLowLevel.Z3_mk_interpolant(_ctx_pointer, ast._ast)
end

def mk_is_int(ast)
  Z3::VeryLowLevel.Z3_mk_is_int(_ctx_pointer, ast._ast)
end

def mk_ite(ast1, ast2, ast3)
  Z3::VeryLowLevel.Z3_mk_ite(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast)
end

def mk_le(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_le(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_lt(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_lt(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_mod(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_mod(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_not(ast)
  Z3::VeryLowLevel.Z3_mk_not(_ctx_pointer, ast._ast)
end

def mk_numeral(str, sort)
  Z3::VeryLowLevel.Z3_mk_numeral(_ctx_pointer, str, sort._sort)
end

def mk_optimize
  Z3::VeryLowLevel.Z3_mk_optimize(_ctx_pointer)
end

def mk_params
  Z3::VeryLowLevel.Z3_mk_params(_ctx_pointer)
end

def mk_power(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_power(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_probe(str)
  Z3::VeryLowLevel.Z3_mk_probe(_ctx_pointer, str)
end

def mk_real2int(ast)
  Z3::VeryLowLevel.Z3_mk_real2int(_ctx_pointer, ast._ast)
end

def mk_real_sort
  Z3::VeryLowLevel.Z3_mk_real_sort(_ctx_pointer)
end

def mk_rem(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_rem(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_select(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_select(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_set_add(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_set_add(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_set_complement(ast)
  Z3::VeryLowLevel.Z3_mk_set_complement(_ctx_pointer, ast._ast)
end

def mk_set_del(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_set_del(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_set_difference(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_set_difference(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_set_member(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_set_member(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_set_sort(sort)
  Z3::VeryLowLevel.Z3_mk_set_sort(_ctx_pointer, sort._sort)
end

def mk_set_subset(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_set_subset(_ctx_pointer, ast1._ast, ast2._ast)
end

def mk_simple_solver
  Z3::VeryLowLevel.Z3_mk_simple_solver(_ctx_pointer)
end

def mk_solver
  Z3::VeryLowLevel.Z3_mk_solver(_ctx_pointer)
end

def mk_solver_for_logic(symbol)
  Z3::VeryLowLevel.Z3_mk_solver_for_logic(_ctx_pointer, symbol)
end

def mk_store(ast1, ast2, ast3)
  Z3::VeryLowLevel.Z3_mk_store(_ctx_pointer, ast1._ast, ast2._ast, ast3._ast)
end

def mk_string_symbol(str)
  Z3::VeryLowLevel.Z3_mk_string_symbol(_ctx_pointer, str)
end

def mk_tactic(str)
  Z3::VeryLowLevel.Z3_mk_tactic(_ctx_pointer, str)
end

def mk_true
  Z3::VeryLowLevel.Z3_mk_true(_ctx_pointer)
end

def mk_unary_minus(ast)
  Z3::VeryLowLevel.Z3_mk_unary_minus(_ctx_pointer, ast._ast)
end

def mk_uninterpreted_sort(symbol)
  Z3::VeryLowLevel.Z3_mk_uninterpreted_sort(_ctx_pointer, symbol)
end

def mk_xor(ast1, ast2)
  Z3::VeryLowLevel.Z3_mk_xor(_ctx_pointer, ast1._ast, ast2._ast)
end

def model_dec_ref(model)
  Z3::VeryLowLevel.Z3_model_dec_ref(_ctx_pointer, model._model)
end

def model_get_num_consts(model)
  Z3::VeryLowLevel.Z3_model_get_num_consts(_ctx_pointer, model._model)
end

def model_get_num_funcs(model)
  Z3::VeryLowLevel.Z3_model_get_num_funcs(_ctx_pointer, model._model)
end

def model_get_num_sorts(model)
  Z3::VeryLowLevel.Z3_model_get_num_sorts(_ctx_pointer, model._model)
end

def model_inc_ref(model)
  Z3::VeryLowLevel.Z3_model_inc_ref(_ctx_pointer, model._model)
end

def model_to_string(model)
  Z3::VeryLowLevel.Z3_model_to_string(_ctx_pointer, model._model)
end

def optimize_check(optimize)
  Z3::VeryLowLevel.Z3_optimize_check(_ctx_pointer, optimize._optimize)
end

def optimize_dec_ref(optimize)
  Z3::VeryLowLevel.Z3_optimize_dec_ref(_ctx_pointer, optimize._optimize)
end

def optimize_get_help(optimize)
  Z3::VeryLowLevel.Z3_optimize_get_help(_ctx_pointer, optimize._optimize)
end

def optimize_get_model(optimize)
  Z3::VeryLowLevel.Z3_optimize_get_model(_ctx_pointer, optimize._optimize)
end

def optimize_get_param_descrs(optimize)
  Z3::VeryLowLevel.Z3_optimize_get_param_descrs(_ctx_pointer, optimize._optimize)
end

def optimize_get_reason_unknown(optimize)
  Z3::VeryLowLevel.Z3_optimize_get_reason_unknown(_ctx_pointer, optimize._optimize)
end

def optimize_get_statistics(optimize)
  Z3::VeryLowLevel.Z3_optimize_get_statistics(_ctx_pointer, optimize._optimize)
end

def optimize_inc_ref(optimize)
  Z3::VeryLowLevel.Z3_optimize_inc_ref(_ctx_pointer, optimize._optimize)
end

def optimize_pop(optimize)
  Z3::VeryLowLevel.Z3_optimize_pop(_ctx_pointer, optimize._optimize)
end

def optimize_push(optimize)
  Z3::VeryLowLevel.Z3_optimize_push(_ctx_pointer, optimize._optimize)
end

def optimize_to_string(optimize)
  Z3::VeryLowLevel.Z3_optimize_to_string(_ctx_pointer, optimize._optimize)
end

def params_dec_ref(params)
  Z3::VeryLowLevel.Z3_params_dec_ref(_ctx_pointer, params._params)
end

def params_inc_ref(params)
  Z3::VeryLowLevel.Z3_params_inc_ref(_ctx_pointer, params._params)
end

def params_to_string(params)
  Z3::VeryLowLevel.Z3_params_to_string(_ctx_pointer, params._params)
end

def pattern_to_ast(pattern)
  Z3::VeryLowLevel.Z3_pattern_to_ast(_ctx_pointer, pattern._pattern)
end

def pattern_to_string(pattern)
  Z3::VeryLowLevel.Z3_pattern_to_string(_ctx_pointer, pattern._pattern)
end

def probe_and(probe1, probe2)
  Z3::VeryLowLevel.Z3_probe_and(_ctx_pointer, probe1._probe, probe2._probe)
end

def probe_dec_ref(probe)
  Z3::VeryLowLevel.Z3_probe_dec_ref(_ctx_pointer, probe._probe)
end

def probe_eq(probe1, probe2)
  Z3::VeryLowLevel.Z3_probe_eq(_ctx_pointer, probe1._probe, probe2._probe)
end

def probe_ge(probe1, probe2)
  Z3::VeryLowLevel.Z3_probe_ge(_ctx_pointer, probe1._probe, probe2._probe)
end

def probe_get_descr(str)
  Z3::VeryLowLevel.Z3_probe_get_descr(_ctx_pointer, str)
end

def probe_gt(probe1, probe2)
  Z3::VeryLowLevel.Z3_probe_gt(_ctx_pointer, probe1._probe, probe2._probe)
end

def probe_inc_ref(probe)
  Z3::VeryLowLevel.Z3_probe_inc_ref(_ctx_pointer, probe._probe)
end

def probe_le(probe1, probe2)
  Z3::VeryLowLevel.Z3_probe_le(_ctx_pointer, probe1._probe, probe2._probe)
end

def probe_lt(probe1, probe2)
  Z3::VeryLowLevel.Z3_probe_lt(_ctx_pointer, probe1._probe, probe2._probe)
end

def probe_not(probe)
  Z3::VeryLowLevel.Z3_probe_not(_ctx_pointer, probe._probe)
end

def probe_or(probe1, probe2)
  Z3::VeryLowLevel.Z3_probe_or(_ctx_pointer, probe1._probe, probe2._probe)
end

def rcf_add(num1, num2)
  Z3::VeryLowLevel.Z3_rcf_add(_ctx_pointer, num1._rcf_num, num2._rcf_num)
end

def rcf_del(num)
  Z3::VeryLowLevel.Z3_rcf_del(_ctx_pointer, num._rcf_num)
end

def rcf_div(num1, num2)
  Z3::VeryLowLevel.Z3_rcf_div(_ctx_pointer, num1._rcf_num, num2._rcf_num)
end

def rcf_eq(num1, num2)
  Z3::VeryLowLevel.Z3_rcf_eq(_ctx_pointer, num1._rcf_num, num2._rcf_num)
end

def rcf_ge(num1, num2)
  Z3::VeryLowLevel.Z3_rcf_ge(_ctx_pointer, num1._rcf_num, num2._rcf_num)
end

def rcf_gt(num1, num2)
  Z3::VeryLowLevel.Z3_rcf_gt(_ctx_pointer, num1._rcf_num, num2._rcf_num)
end

def rcf_inv(num)
  Z3::VeryLowLevel.Z3_rcf_inv(_ctx_pointer, num._rcf_num)
end

def rcf_le(num1, num2)
  Z3::VeryLowLevel.Z3_rcf_le(_ctx_pointer, num1._rcf_num, num2._rcf_num)
end

def rcf_lt(num1, num2)
  Z3::VeryLowLevel.Z3_rcf_lt(_ctx_pointer, num1._rcf_num, num2._rcf_num)
end

def rcf_mk_e
  Z3::VeryLowLevel.Z3_rcf_mk_e(_ctx_pointer)
end

def rcf_mk_infinitesimal
  Z3::VeryLowLevel.Z3_rcf_mk_infinitesimal(_ctx_pointer)
end

def rcf_mk_pi
  Z3::VeryLowLevel.Z3_rcf_mk_pi(_ctx_pointer)
end

def rcf_mk_rational(str)
  Z3::VeryLowLevel.Z3_rcf_mk_rational(_ctx_pointer, str)
end

def rcf_mul(num1, num2)
  Z3::VeryLowLevel.Z3_rcf_mul(_ctx_pointer, num1._rcf_num, num2._rcf_num)
end

def rcf_neg(num)
  Z3::VeryLowLevel.Z3_rcf_neg(_ctx_pointer, num._rcf_num)
end

def rcf_neq(num1, num2)
  Z3::VeryLowLevel.Z3_rcf_neq(_ctx_pointer, num1._rcf_num, num2._rcf_num)
end

def rcf_sub(num1, num2)
  Z3::VeryLowLevel.Z3_rcf_sub(_ctx_pointer, num1._rcf_num, num2._rcf_num)
end

def reset_memory
  Z3::VeryLowLevel.Z3_reset_memory()
end

def simplify(ast)
  Z3::VeryLowLevel.Z3_simplify(_ctx_pointer, ast._ast)
end

def simplify_get_help
  Z3::VeryLowLevel.Z3_simplify_get_help(_ctx_pointer)
end

def simplify_get_param_descrs
  Z3::VeryLowLevel.Z3_simplify_get_param_descrs(_ctx_pointer)
end

def solver_assert(solver, ast1)
  Z3::VeryLowLevel.Z3_solver_assert(_ctx_pointer, solver._solver, ast1._ast)
end

def solver_assert_and_track(solver, ast1, ast2)
  Z3::VeryLowLevel.Z3_solver_assert_and_track(_ctx_pointer, solver._solver, ast1._ast, ast2._ast)
end

def solver_check(solver)
  Z3::VeryLowLevel.Z3_solver_check(_ctx_pointer, solver._solver)
end

def solver_dec_ref(solver)
  Z3::VeryLowLevel.Z3_solver_dec_ref(_ctx_pointer, solver._solver)
end

def solver_get_help(solver)
  Z3::VeryLowLevel.Z3_solver_get_help(_ctx_pointer, solver._solver)
end

def solver_get_model(solver)
  Z3::VeryLowLevel.Z3_solver_get_model(_ctx_pointer, solver._solver)
end

def solver_get_num_scopes(solver)
  Z3::VeryLowLevel.Z3_solver_get_num_scopes(_ctx_pointer, solver._solver)
end

def solver_get_param_descrs(solver)
  Z3::VeryLowLevel.Z3_solver_get_param_descrs(_ctx_pointer, solver._solver)
end

def solver_get_proof(solver)
  Z3::VeryLowLevel.Z3_solver_get_proof(_ctx_pointer, solver._solver)
end

def solver_get_reason_unknown(solver)
  Z3::VeryLowLevel.Z3_solver_get_reason_unknown(_ctx_pointer, solver._solver)
end

def solver_get_statistics(solver)
  Z3::VeryLowLevel.Z3_solver_get_statistics(_ctx_pointer, solver._solver)
end

def solver_inc_ref(solver)
  Z3::VeryLowLevel.Z3_solver_inc_ref(_ctx_pointer, solver._solver)
end

def solver_pop(solver, num)
  Z3::VeryLowLevel.Z3_solver_pop(_ctx_pointer, solver._solver, num)
end

def solver_push(solver)
  Z3::VeryLowLevel.Z3_solver_push(_ctx_pointer, solver._solver)
end

def solver_reset(solver)
  Z3::VeryLowLevel.Z3_solver_reset(_ctx_pointer, solver._solver)
end

def solver_to_string(solver)
  Z3::VeryLowLevel.Z3_solver_to_string(_ctx_pointer, solver._solver)
end

def sort_to_ast(sort)
  Z3::VeryLowLevel.Z3_sort_to_ast(_ctx_pointer, sort._sort)
end

def sort_to_string(sort)
  Z3::VeryLowLevel.Z3_sort_to_string(_ctx_pointer, sort._sort)
end

def tactic_fail
  Z3::VeryLowLevel.Z3_tactic_fail(_ctx_pointer)
end

def tactic_fail_if(probe)
  Z3::VeryLowLevel.Z3_tactic_fail_if(_ctx_pointer, probe._probe)
end

def tactic_fail_if_not_decided
  Z3::VeryLowLevel.Z3_tactic_fail_if_not_decided(_ctx_pointer)
end

def tactic_get_descr(str)
  Z3::VeryLowLevel.Z3_tactic_get_descr(_ctx_pointer, str)
end

def tactic_skip
  Z3::VeryLowLevel.Z3_tactic_skip(_ctx_pointer)
end

def to_func_decl(ast)
  Z3::VeryLowLevel.Z3_to_func_decl(_ctx_pointer, ast._ast)
end

def update_param_value(str1, str2)
  Z3::VeryLowLevel.Z3_update_param_value(_ctx_pointer, str1, str2)
end
