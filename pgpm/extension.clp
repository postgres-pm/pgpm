(deftemplate extension
  (slot name (type STRING)))
(deftemplate extension-versions
   (slot name (type STRING))
   (slot ref)
   (multislot version-refs)
   (multislot versions))
(defrule serve-extension-versions
   ?ext <- (extension (name ?name))
   ?f <- (extension-versions (name ?name))
=>
  (bind ?versions (create$))
  (bind ?version-refs (create$))
  (do-for-all-facts ((?e extension) (?v version)) (eq ?e:name ?name)
     (bind ?versions (create$ ?versions ?v:value))
     (bind ?version-refs (create$ ?version-refs ?v)))
  (modify ?f (ref ?ext) (version-refs ?version-refs) (versions ?versions)))