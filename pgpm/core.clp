 (deftemplate description
      (slot ref (type FACT-ADDRESS))
      (slot value (type STRING)))

 (deftemplate version
      (slot ref (type FACT-ADDRESS))
      (slot value (type STRING)))

 (deftemplate source-path
      (slot ref (type FACT-ADDRESS))
      (slot value))

 (deftemplate source-file
       (slot ref (type FACT-ADDRESS))
       (slot mimetype)
       (slot value (type STRING)))

 (defrule source-file-mimetype
     ?ref <- (source-path (value ?root))
     ?f <- (source-file (ref ?ref) (value ?path) (mimetype nil))
    =>
     (modify ?f (mimetype (file-mimetype (str-cat ?root "/" ?path)))))

 (defrule source-path-available
      ?sp <- (source-path (value ?path&~nil))
    =>
      (assert-files ?sp ?path))
