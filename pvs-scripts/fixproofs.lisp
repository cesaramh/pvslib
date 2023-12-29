(defun nofix-yet (s-expr)
  s-expr)

;; (step NAME ..) --> (step "name" ..) 
(defun fix-name (s-expr) 
  (if (symbolp (cadr s-expr)) 
      (cons (car s-expr)
	    (cons (string (cadr s-expr))
		  (cddr s-expr)))
    s-expr))

;; (step NAME1 .. NAMEN) --> (step "name1" .. "namen")
(defun fix-names (s-expr &key but)
  (cons (car s-expr)
	(mapcar #'(lambda (s) (if (and (symbolp s) (not (member s but))) (string s) s))
		(cdr s-expr))))

;; (step NAME | (NAME1 .. NAMEN)) --> (step "name1" .. "namen") 
(defun fix-name-or-names (s-expr)
  (cons (car s-expr)
	(let ((rest (if (listp (cadr s-expr)) (cadr s-expr) (cdr s-expr))))
	  (mapcar #'(lambda (s) (if (symbolp s) (string s) s))
		  rest))))

;; (step FNUM NAME1 .. NAMEN) --> (step fnum "name1" .. "namen")
(defun fix-fnum-names (s-expr)
  (cons (car s-expr)
	(cons (cadr s-expr)
	      (mapcar #'(lambda (s) (if (symbolp s) (string s) s))
		      (cddr s-expr)))))

;; (step NAME NAME ..) --> (step "name" "name" ..) 
(defun fix-name-name (s-expr) 
  (cons (car s-expr)
	(cons (if (symbolp (cadr s-expr)) (string (cadr s-expr)) (cadr s-expr))
	      (cons (if (symbolp (caddr s-expr)) (string (caddr s-expr)) (caddr s-expr))
		    (cdddr s-expr)))))

(defun my-equal (s1 s2)
  (and (symbolp s1)
       (string-equal s1 s2)))

(defun process (s-expr)
  (if (listp s-expr)
      (cond ((member (car s-expr) '("lemma" "use" "rewrite" "expand" "induct" "label") :test #'my-equal)
	     (fix-name s-expr))
	    ((member (car s-expr) '("expand*" "case") :test #'my-equal)
	     (fix-names s-expr))
	    ((my-equal (car s-expr) "hide")
	     (fix-names s-expr :but '(+ - *)))
	    ((my-equal (car s-expr) "typepred") 
	     (fix-name-or-names s-expr))
	    ((member (car s-expr) '("inst-cp" "inst") :test #'my-equal) 
	     (fix-fnum-names s-expr))
	    ((my-equal (car s-expr) "generalize") 
	     (fix-name-name s-expr))
	    (t (mapcar #'process s-expr)))
    s-expr))

(defun main (name)
  (let* ((in-name name)
	 (out-name (format nil "~a.new" in-name)))
    (with-open-file
     (in-file (merge-pathnames in-name) :direction :input)
     (with-open-file
      (out-file (merge-pathnames out-name) :direction :output
		:if-exists :supersede)
      (let ((s-expr (read in-file)))
	(format out-file "~s" (process s-expr)))))))
  

;; Missing
;;(MEASURE-INDUCT/$ MEASURE VARS &OPTIONAL (FNUM 1) ORDER SKOLEM-TYPEPREDS?)
;;(SKOLEM FNUM CONSTANTS &OPTIONAL SKOLEM-TYPEPREDS? DONT-SIMPLIFY?)
