
attach_function :Z3_algebraic_add, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_algebraic_div, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_algebraic_eq, [ctx_pointer, ast_pointer, ast_pointer], :bool
attach_function :Z3_algebraic_ge, [ctx_pointer, ast_pointer, ast_pointer], :bool
attach_function :Z3_algebraic_gt, [ctx_pointer, ast_pointer, ast_pointer], :bool
attach_function :Z3_algebraic_is_neg, [ctx_pointer, ast_pointer], :bool
attach_function :Z3_algebraic_is_pos, [ctx_pointer, ast_pointer], :bool
attach_function :Z3_algebraic_is_value, [ctx_pointer, ast_pointer], :bool
attach_function :Z3_algebraic_is_zero, [ctx_pointer, ast_pointer], :bool
attach_function :Z3_algebraic_le, [ctx_pointer, ast_pointer, ast_pointer], :bool
attach_function :Z3_algebraic_lt, [ctx_pointer, ast_pointer, ast_pointer], :bool
attach_function :Z3_algebraic_mul, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_algebraic_neq, [ctx_pointer, ast_pointer, ast_pointer], :bool
attach_function :Z3_algebraic_power, [ctx_pointer, ast_pointer, :uint], ast_pointer
attach_function :Z3_algebraic_root, [ctx_pointer, ast_pointer, :uint], ast_pointer
attach_function :Z3_algebraic_sign, [ctx_pointer, ast_pointer], :int
attach_function :Z3_algebraic_sub, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_ast_to_string, [ctx_pointer, ast_pointer], :string
attach_function :Z3_datatype_update_field, [ctx_pointer, func_decl_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_dec_ref, [ctx_pointer, ast_pointer], :void
attach_function :Z3_del_context, [ctx_pointer], :void
attach_function :Z3_disable_trace, [:string], :void
attach_function :Z3_enable_trace, [:string], :void
attach_function :Z3_finalize_memory, [], :void
attach_function :Z3_fpa_get_ebits, [ctx_pointer, sort_pointer], :uint
attach_function :Z3_fpa_get_numeral_exponent_string, [ctx_pointer, ast_pointer], :string
attach_function :Z3_fpa_get_numeral_significand_string, [ctx_pointer, ast_pointer], :string
attach_function :Z3_fpa_get_sbits, [ctx_pointer, sort_pointer], :uint
attach_function :Z3_get_algebraic_number_lower, [ctx_pointer, ast_pointer, :uint], ast_pointer
attach_function :Z3_get_algebraic_number_upper, [ctx_pointer, ast_pointer, :uint], ast_pointer
attach_function :Z3_get_array_sort_domain, [ctx_pointer, sort_pointer], sort_pointer
attach_function :Z3_get_array_sort_range, [ctx_pointer, sort_pointer], sort_pointer
attach_function :Z3_get_as_array_func_decl, [ctx_pointer, ast_pointer], func_decl_pointer
attach_function :Z3_get_ast_hash, [ctx_pointer, ast_pointer], :uint
attach_function :Z3_get_ast_id, [ctx_pointer, ast_pointer], :uint
attach_function :Z3_get_ast_kind, [ctx_pointer, ast_pointer], :uint
attach_function :Z3_get_bool_value, [ctx_pointer, ast_pointer], :int
attach_function :Z3_get_bv_sort_size, [ctx_pointer, sort_pointer], :uint
attach_function :Z3_get_datatype_sort_constructor, [ctx_pointer, sort_pointer, :uint], func_decl_pointer
attach_function :Z3_get_datatype_sort_num_constructors, [ctx_pointer, sort_pointer], :uint
attach_function :Z3_get_datatype_sort_recognizer, [ctx_pointer, sort_pointer, :uint], func_decl_pointer
attach_function :Z3_get_denominator, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_get_error_code, [ctx_pointer], :uint
attach_function :Z3_get_index_value, [ctx_pointer, ast_pointer], :uint
attach_function :Z3_get_num_probes, [ctx_pointer], :uint
attach_function :Z3_get_num_tactics, [ctx_pointer], :uint
attach_function :Z3_get_numeral_decimal_string, [ctx_pointer, ast_pointer, :uint], :string
attach_function :Z3_get_numeral_string, [ctx_pointer, ast_pointer], :string
attach_function :Z3_get_numerator, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_get_pattern_num_terms, [ctx_pointer, pattern_pointer], :uint
attach_function :Z3_get_probe_name, [ctx_pointer, :uint], :string
attach_function :Z3_get_quantifier_body, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_get_quantifier_bound_name, [ctx_pointer, ast_pointer, :uint], symbol_pointer
attach_function :Z3_get_quantifier_bound_sort, [ctx_pointer, ast_pointer, :uint], sort_pointer
attach_function :Z3_get_quantifier_no_pattern_ast, [ctx_pointer, ast_pointer, :uint], ast_pointer
attach_function :Z3_get_quantifier_num_bound, [ctx_pointer, ast_pointer], :uint
attach_function :Z3_get_quantifier_num_no_patterns, [ctx_pointer, ast_pointer], :uint
attach_function :Z3_get_quantifier_num_patterns, [ctx_pointer, ast_pointer], :uint
attach_function :Z3_get_quantifier_pattern_ast, [ctx_pointer, ast_pointer, :uint], pattern_pointer
attach_function :Z3_get_quantifier_weight, [ctx_pointer, ast_pointer], :uint
attach_function :Z3_get_relation_arity, [ctx_pointer, sort_pointer], :uint
attach_function :Z3_get_relation_column, [ctx_pointer, sort_pointer, :uint], sort_pointer
attach_function :Z3_get_smtlib_assumption, [ctx_pointer, :uint], ast_pointer
attach_function :Z3_get_smtlib_decl, [ctx_pointer, :uint], func_decl_pointer
attach_function :Z3_get_smtlib_error, [ctx_pointer], :string
attach_function :Z3_get_smtlib_formula, [ctx_pointer, :uint], ast_pointer
attach_function :Z3_get_smtlib_num_assumptions, [ctx_pointer], :uint
attach_function :Z3_get_smtlib_num_decls, [ctx_pointer], :uint
attach_function :Z3_get_smtlib_num_formulas, [ctx_pointer], :uint
attach_function :Z3_get_smtlib_num_sorts, [ctx_pointer], :uint
attach_function :Z3_get_smtlib_sort, [ctx_pointer, :uint], sort_pointer
attach_function :Z3_get_sort, [ctx_pointer, ast_pointer], sort_pointer
attach_function :Z3_get_sort_id, [ctx_pointer, sort_pointer], :uint
attach_function :Z3_get_sort_kind, [ctx_pointer, sort_pointer], :uint
attach_function :Z3_get_sort_name, [ctx_pointer, sort_pointer], symbol_pointer
attach_function :Z3_get_symbol_int, [ctx_pointer, symbol_pointer], :int
attach_function :Z3_get_symbol_kind, [ctx_pointer, symbol_pointer], :uint
attach_function :Z3_get_symbol_string, [ctx_pointer, symbol_pointer], :string
attach_function :Z3_get_tactic_name, [ctx_pointer, :uint], :string
attach_function :Z3_get_tuple_sort_field_decl, [ctx_pointer, sort_pointer, :uint], func_decl_pointer
attach_function :Z3_get_tuple_sort_mk_decl, [ctx_pointer, sort_pointer], func_decl_pointer
attach_function :Z3_get_tuple_sort_num_fields, [ctx_pointer, sort_pointer], :uint
attach_function :Z3_global_param_reset_all, [], :void
attach_function :Z3_global_param_set, [:string, :string], :void
attach_function :Z3_goal_dec_ref, [ctx_pointer, goal_pointer], :void
attach_function :Z3_goal_depth, [ctx_pointer, goal_pointer], :uint
attach_function :Z3_goal_inc_ref, [ctx_pointer, goal_pointer], :void
attach_function :Z3_goal_inconsistent, [ctx_pointer, goal_pointer], :bool
attach_function :Z3_goal_is_decided_sat, [ctx_pointer, goal_pointer], :bool
attach_function :Z3_goal_is_decided_unsat, [ctx_pointer, goal_pointer], :bool
attach_function :Z3_goal_num_exprs, [ctx_pointer, goal_pointer], :uint
attach_function :Z3_goal_precision, [ctx_pointer, goal_pointer], :uint
attach_function :Z3_goal_reset, [ctx_pointer, goal_pointer], :void
attach_function :Z3_goal_size, [ctx_pointer, goal_pointer], :uint
attach_function :Z3_goal_to_string, [ctx_pointer, goal_pointer], :string
attach_function :Z3_inc_ref, [ctx_pointer, ast_pointer], :void
attach_function :Z3_interpolation_profile, [ctx_pointer], :string
attach_function :Z3_interrupt, [ctx_pointer], :void
attach_function :Z3_is_algebraic_number, [ctx_pointer, ast_pointer], :bool
attach_function :Z3_is_app, [ctx_pointer, ast_pointer], :bool
attach_function :Z3_is_as_array, [ctx_pointer, ast_pointer], :bool
attach_function :Z3_is_eq_ast, [ctx_pointer, ast_pointer, ast_pointer], :bool
attach_function :Z3_is_eq_sort, [ctx_pointer, sort_pointer, sort_pointer], :bool
attach_function :Z3_is_numeral_ast, [ctx_pointer, ast_pointer], :bool
attach_function :Z3_is_quantifier_forall, [ctx_pointer, ast_pointer], :bool
attach_function :Z3_is_well_sorted, [ctx_pointer, ast_pointer], :bool
attach_function :Z3_mk_array_default, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_array_sort, [ctx_pointer, sort_pointer, sort_pointer], sort_pointer
attach_function :Z3_mk_bool_sort, [ctx_pointer], sort_pointer
attach_function :Z3_mk_bv_sort, [ctx_pointer, :uint], sort_pointer
attach_function :Z3_mk_bvadd, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvadd_no_underflow, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvand, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvashr, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvlshr, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvmul, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvmul_no_underflow, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvnand, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvneg, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvneg_no_overflow, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvnor, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvnot, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvor, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvredand, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvredor, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvsdiv, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvsdiv_no_overflow, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvsge, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvsgt, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvshl, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvsle, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvslt, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvsmod, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvsrem, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvsub, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvsub_no_overflow, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvudiv, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvuge, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvugt, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvule, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvult, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvurem, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvxnor, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_bvxor, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_concat, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_const, [ctx_pointer, symbol_pointer, sort_pointer], ast_pointer
attach_function :Z3_mk_div, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_empty_set, [ctx_pointer, sort_pointer], ast_pointer
attach_function :Z3_mk_eq, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_ext_rotate_left, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_ext_rotate_right, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_false, [ctx_pointer], ast_pointer
attach_function :Z3_mk_fixedpoint, [ctx_pointer], fixedpoint_pointer
attach_function :Z3_mk_fpa_abs, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_add, [ctx_pointer, ast_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_div, [ctx_pointer, ast_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_eq, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_fma, [ctx_pointer, ast_pointer, ast_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_fp, [ctx_pointer, ast_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_geq, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_gt, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_is_infinite, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_is_nan, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_is_negative, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_is_normal, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_is_positive, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_is_subnormal, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_is_zero, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_leq, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_lt, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_max, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_min, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_mul, [ctx_pointer, ast_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_nan, [ctx_pointer, sort_pointer], ast_pointer
attach_function :Z3_mk_fpa_neg, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_rem, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_rna, [ctx_pointer], ast_pointer
attach_function :Z3_mk_fpa_rne, [ctx_pointer], ast_pointer
attach_function :Z3_mk_fpa_round_nearest_ties_to_away, [ctx_pointer], ast_pointer
attach_function :Z3_mk_fpa_round_nearest_ties_to_even, [ctx_pointer], ast_pointer
attach_function :Z3_mk_fpa_round_to_integral, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_round_toward_negative, [ctx_pointer], ast_pointer
attach_function :Z3_mk_fpa_round_toward_positive, [ctx_pointer], ast_pointer
attach_function :Z3_mk_fpa_round_toward_zero, [ctx_pointer], ast_pointer
attach_function :Z3_mk_fpa_rounding_mode_sort, [ctx_pointer], sort_pointer
attach_function :Z3_mk_fpa_rtn, [ctx_pointer], ast_pointer
attach_function :Z3_mk_fpa_rtp, [ctx_pointer], ast_pointer
attach_function :Z3_mk_fpa_rtz, [ctx_pointer], ast_pointer
attach_function :Z3_mk_fpa_sort_128, [ctx_pointer], sort_pointer
attach_function :Z3_mk_fpa_sort_16, [ctx_pointer], sort_pointer
attach_function :Z3_mk_fpa_sort_32, [ctx_pointer], sort_pointer
attach_function :Z3_mk_fpa_sort_64, [ctx_pointer], sort_pointer
attach_function :Z3_mk_fpa_sort_double, [ctx_pointer], sort_pointer
attach_function :Z3_mk_fpa_sort_half, [ctx_pointer], sort_pointer
attach_function :Z3_mk_fpa_sort_quadruple, [ctx_pointer], sort_pointer
attach_function :Z3_mk_fpa_sort_single, [ctx_pointer], sort_pointer
attach_function :Z3_mk_fpa_sqrt, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_sub, [ctx_pointer, ast_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_to_fp_float, [ctx_pointer, ast_pointer, ast_pointer, sort_pointer], ast_pointer
attach_function :Z3_mk_fpa_to_fp_real, [ctx_pointer, ast_pointer, ast_pointer, sort_pointer], ast_pointer
attach_function :Z3_mk_fpa_to_fp_signed, [ctx_pointer, ast_pointer, ast_pointer, sort_pointer], ast_pointer
attach_function :Z3_mk_fpa_to_fp_unsigned, [ctx_pointer, ast_pointer, ast_pointer, sort_pointer], ast_pointer
attach_function :Z3_mk_fpa_to_ieee_bv, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fpa_to_real, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_fresh_const, [ctx_pointer, :string, sort_pointer], ast_pointer
attach_function :Z3_mk_full_set, [ctx_pointer, sort_pointer], ast_pointer
attach_function :Z3_mk_ge, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_gt, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_iff, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_implies, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_int2real, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_int_sort, [ctx_pointer], sort_pointer
attach_function :Z3_mk_interpolant, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_is_int, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_ite, [ctx_pointer, ast_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_le, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_lt, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_mod, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_not, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_numeral, [ctx_pointer, :string, sort_pointer], ast_pointer
attach_function :Z3_mk_optimize, [ctx_pointer], optimize_pointer
attach_function :Z3_mk_params, [ctx_pointer], params_pointer
attach_function :Z3_mk_power, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_probe, [ctx_pointer, :string], probe_pointer
attach_function :Z3_mk_real2int, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_real_sort, [ctx_pointer], sort_pointer
attach_function :Z3_mk_rem, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_select, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_set_add, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_set_complement, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_set_del, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_set_difference, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_set_member, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_set_sort, [ctx_pointer, sort_pointer], sort_pointer
attach_function :Z3_mk_set_subset, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_simple_solver, [ctx_pointer], solver_pointer
attach_function :Z3_mk_solver, [ctx_pointer], solver_pointer
attach_function :Z3_mk_solver_for_logic, [ctx_pointer, symbol_pointer], solver_pointer
attach_function :Z3_mk_store, [ctx_pointer, ast_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_string_symbol, [ctx_pointer, :string], symbol_pointer
attach_function :Z3_mk_tactic, [ctx_pointer, :string], tactic_pointer
attach_function :Z3_mk_true, [ctx_pointer], ast_pointer
attach_function :Z3_mk_unary_minus, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_mk_uninterpreted_sort, [ctx_pointer, symbol_pointer], sort_pointer
attach_function :Z3_mk_xor, [ctx_pointer, ast_pointer, ast_pointer], ast_pointer
attach_function :Z3_model_dec_ref, [ctx_pointer, model_pointer], :void
attach_function :Z3_model_get_num_consts, [ctx_pointer, model_pointer], :uint
attach_function :Z3_model_get_num_funcs, [ctx_pointer, model_pointer], :uint
attach_function :Z3_model_get_num_sorts, [ctx_pointer, model_pointer], :uint
attach_function :Z3_model_inc_ref, [ctx_pointer, model_pointer], :void
attach_function :Z3_model_to_string, [ctx_pointer, model_pointer], :string
attach_function :Z3_optimize_check, [ctx_pointer, optimize_pointer], :int
attach_function :Z3_optimize_dec_ref, [ctx_pointer, optimize_pointer], :void
attach_function :Z3_optimize_get_help, [ctx_pointer, optimize_pointer], :string
attach_function :Z3_optimize_get_model, [ctx_pointer, optimize_pointer], model_pointer
attach_function :Z3_optimize_get_param_descrs, [ctx_pointer, optimize_pointer], param_descrs_pointer
attach_function :Z3_optimize_get_reason_unknown, [ctx_pointer, optimize_pointer], :string
attach_function :Z3_optimize_get_statistics, [ctx_pointer, optimize_pointer], stats_pointer
attach_function :Z3_optimize_inc_ref, [ctx_pointer, optimize_pointer], :void
attach_function :Z3_optimize_pop, [ctx_pointer, optimize_pointer], :void
attach_function :Z3_optimize_push, [ctx_pointer, optimize_pointer], :void
attach_function :Z3_optimize_to_string, [ctx_pointer, optimize_pointer], :string
attach_function :Z3_params_dec_ref, [ctx_pointer, params_pointer], :void
attach_function :Z3_params_inc_ref, [ctx_pointer, params_pointer], :void
attach_function :Z3_params_to_string, [ctx_pointer, params_pointer], :string
attach_function :Z3_pattern_to_ast, [ctx_pointer, pattern_pointer], ast_pointer
attach_function :Z3_pattern_to_string, [ctx_pointer, pattern_pointer], :string
attach_function :Z3_probe_and, [ctx_pointer, probe_pointer, probe_pointer], probe_pointer
attach_function :Z3_probe_dec_ref, [ctx_pointer, probe_pointer], :void
attach_function :Z3_probe_eq, [ctx_pointer, probe_pointer, probe_pointer], probe_pointer
attach_function :Z3_probe_ge, [ctx_pointer, probe_pointer, probe_pointer], probe_pointer
attach_function :Z3_probe_get_descr, [ctx_pointer, :string], :string
attach_function :Z3_probe_gt, [ctx_pointer, probe_pointer, probe_pointer], probe_pointer
attach_function :Z3_probe_inc_ref, [ctx_pointer, probe_pointer], :void
attach_function :Z3_probe_le, [ctx_pointer, probe_pointer, probe_pointer], probe_pointer
attach_function :Z3_probe_lt, [ctx_pointer, probe_pointer, probe_pointer], probe_pointer
attach_function :Z3_probe_not, [ctx_pointer, probe_pointer], probe_pointer
attach_function :Z3_probe_or, [ctx_pointer, probe_pointer, probe_pointer], probe_pointer
attach_function :Z3_rcf_add, [ctx_pointer, rcf_num_pointer, rcf_num_pointer], rcf_num_pointer
attach_function :Z3_rcf_del, [ctx_pointer, rcf_num_pointer], :void
attach_function :Z3_rcf_div, [ctx_pointer, rcf_num_pointer, rcf_num_pointer], rcf_num_pointer
attach_function :Z3_rcf_eq, [ctx_pointer, rcf_num_pointer, rcf_num_pointer], :bool
attach_function :Z3_rcf_ge, [ctx_pointer, rcf_num_pointer, rcf_num_pointer], :bool
attach_function :Z3_rcf_gt, [ctx_pointer, rcf_num_pointer, rcf_num_pointer], :bool
attach_function :Z3_rcf_inv, [ctx_pointer, rcf_num_pointer], rcf_num_pointer
attach_function :Z3_rcf_le, [ctx_pointer, rcf_num_pointer, rcf_num_pointer], :bool
attach_function :Z3_rcf_lt, [ctx_pointer, rcf_num_pointer, rcf_num_pointer], :bool
attach_function :Z3_rcf_mk_e, [ctx_pointer], rcf_num_pointer
attach_function :Z3_rcf_mk_infinitesimal, [ctx_pointer], rcf_num_pointer
attach_function :Z3_rcf_mk_pi, [ctx_pointer], rcf_num_pointer
attach_function :Z3_rcf_mk_rational, [ctx_pointer, :string], rcf_num_pointer
attach_function :Z3_rcf_mul, [ctx_pointer, rcf_num_pointer, rcf_num_pointer], rcf_num_pointer
attach_function :Z3_rcf_neg, [ctx_pointer, rcf_num_pointer], rcf_num_pointer
attach_function :Z3_rcf_neq, [ctx_pointer, rcf_num_pointer, rcf_num_pointer], :bool
attach_function :Z3_rcf_sub, [ctx_pointer, rcf_num_pointer, rcf_num_pointer], rcf_num_pointer
attach_function :Z3_reset_memory, [], :void
attach_function :Z3_simplify, [ctx_pointer, ast_pointer], ast_pointer
attach_function :Z3_simplify_get_help, [ctx_pointer], :string
attach_function :Z3_simplify_get_param_descrs, [ctx_pointer], param_descrs_pointer
attach_function :Z3_solver_assert, [ctx_pointer, solver_pointer, ast_pointer], :void
attach_function :Z3_solver_assert_and_track, [ctx_pointer, solver_pointer, ast_pointer, ast_pointer], :void
attach_function :Z3_solver_check, [ctx_pointer, solver_pointer], :int
attach_function :Z3_solver_dec_ref, [ctx_pointer, solver_pointer], :void
attach_function :Z3_solver_get_help, [ctx_pointer, solver_pointer], :string
attach_function :Z3_solver_get_model, [ctx_pointer, solver_pointer], model_pointer
attach_function :Z3_solver_get_num_scopes, [ctx_pointer, solver_pointer], :uint
attach_function :Z3_solver_get_param_descrs, [ctx_pointer, solver_pointer], param_descrs_pointer
attach_function :Z3_solver_get_proof, [ctx_pointer, solver_pointer], ast_pointer
attach_function :Z3_solver_get_reason_unknown, [ctx_pointer, solver_pointer], :string
attach_function :Z3_solver_get_statistics, [ctx_pointer, solver_pointer], stats_pointer
attach_function :Z3_solver_inc_ref, [ctx_pointer, solver_pointer], :void
attach_function :Z3_solver_pop, [ctx_pointer, solver_pointer, :uint], :void
attach_function :Z3_solver_push, [ctx_pointer, solver_pointer], :void
attach_function :Z3_solver_reset, [ctx_pointer, solver_pointer], :void
attach_function :Z3_solver_to_string, [ctx_pointer, solver_pointer], :string
attach_function :Z3_sort_to_ast, [ctx_pointer, sort_pointer], ast_pointer
attach_function :Z3_sort_to_string, [ctx_pointer, sort_pointer], :string
attach_function :Z3_tactic_fail, [ctx_pointer], tactic_pointer
attach_function :Z3_tactic_fail_if, [ctx_pointer, probe_pointer], tactic_pointer
attach_function :Z3_tactic_fail_if_not_decided, [ctx_pointer], tactic_pointer
attach_function :Z3_tactic_get_descr, [ctx_pointer, :string], :string
attach_function :Z3_tactic_skip, [ctx_pointer], tactic_pointer
attach_function :Z3_to_func_decl, [ctx_pointer, ast_pointer], func_decl_pointer
attach_function :Z3_update_param_value, [ctx_pointer, :string, :string], :void
