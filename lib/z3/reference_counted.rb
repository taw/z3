module Z3
  # Z3 objects other than ASTs are reference counted, even when the context is not
  # (Z3_mk_context vs Z3_mk_context_rc only changes how ASTs are managed).
  #
  # Every wrapper must claim the object it holds, and release it once the wrapper
  # is garbage collected. Without the release the native object stays alive at a
  # nonzero refcount until the process exits.
  module ReferenceCounted
    # Must not close over the wrapper, or the wrapper would never become
    # unreachable, the finalizer would never run, and the object would leak anyway
    def self.finalizer(kind, pointer)
      proc { LowLevel.dec_ref_pointer(kind, pointer) }
    end

    private

    # `kind` is the Z3 API prefix, so :solver means Z3_solver_inc_ref / Z3_solver_dec_ref
    def inc_ref!(kind, pointer)
      LowLevel.inc_ref_pointer(kind, pointer)
      ObjectSpace.define_finalizer(self, ReferenceCounted.finalizer(kind, pointer))
    end
  end
end
