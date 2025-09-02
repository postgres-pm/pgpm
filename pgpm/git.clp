(deftemplate git-repository
  (slot ref (type FACT-ADDRESS))
  (slot value (type STRING)))
(deftemplate github-repository
  (slot ref (type FACT-ADDRESS))
  (slot value (type STRING)))
(defrule github-repository-inference
  (github-repository (ref ?f) (value ?name))
  =>
  (assert (git-repository (ref ?f) (value (str-cat "https://github.com/" ?name)))))
(deftemplate git-repository-head
  (slot ref (type FACT-ADDRESS))
  (slot value (type STRING)))
(deftemplate git-repository-tag
  (slot ref (type FACT-ADDRESS))
  (slot value (type STRING)))
(deftemplate git-repository-instance
  (slot ref (type FACT-ADDRESS))
  (slot repository (type FACT-ADDRESS))
  (slot reference (type STRING)))
(defrule git-heads
   ?r <- (git-repository (ref ?f) (value ?url))
   (not (git-repository-head (ref ?r)))
   =>
    (git-fetch-heads ?r ?url))
(defrule git-tags
   (git-repository-head (ref ?r) (value ?head))
   (test (eq (str-index "refs/tags/" ?head) 1))
   =>
   (assert (git-repository-tag (ref ?r) (value (sub-string (+ 1 (str-length "refs/tags/")) (str-length ?head) ?head)))))
(defrule git-tag-versions
   ?r <- (git-repository (ref ?o))
   (git-repository-tag (ref ?r) (value ?tag))
   (test (eq (str-index "v" ?tag) 1))
   (test (not (str-index "^{}" ?tag)))
   =>
   (bind ?v (assert (version (ref ?o) (value (sub-string 2 (str-length ?tag) ?tag)))))
   (assert (git-repository-instance (repository ?r) (ref ?v) (reference ?tag))))
(defrule git-repository-instance-cloning
  ?source-path <- (source-path (ref ?obj) (value nil))
  ?repo <- (git-repository  (value ?url))
  ?i <- (git-repository-instance (repository ?repo) (ref ?obj) (reference ?ref))
=>
 (git-clone-repository ?source-path ?url ?ref))