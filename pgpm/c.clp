(defrule c-target
  (logical ?ref <- (source-path (ref ?target)))
  (logical (source-file (ref ?ref) (mimetype "text/x-c")))
  =>
  (assert (requires ?target c-compiler)))