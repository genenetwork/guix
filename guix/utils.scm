;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012, 2013, 2014, 2015, 2016 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2013, 2014, 2015 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2014 Eric Bavier <bavier@member.fsf.org>
;;; Copyright © 2014 Ian Denhardt <ian@zenhack.net>
;;; Copyright © 2016 Mathieu Lirzin <mthl@gnu.org>
;;; Copyright © 2015 David Thompson <davet@gnu.org>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (guix utils)
  #:use-module (guix config)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-11)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-39)
  #:use-module (srfi srfi-60)
  #:use-module (rnrs bytevectors)
  #:use-module (rnrs io ports)
  #:use-module ((rnrs bytevectors) #:select (bytevector-u8-set!))
  #:use-module ((guix build utils) #:select (dump-port))
  #:use-module ((guix build syscalls) #:select (errno mkdtemp!))
  #:use-module (ice-9 vlist)
  #:use-module (ice-9 format)
  #:autoload   (ice-9 popen)  (open-pipe*)
  #:autoload   (ice-9 rdelim) (read-line)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 match)
  #:use-module (ice-9 format)
  #:use-module (system foreign)
  #:export (bytevector->base16-string
            base16-string->bytevector

            compile-time-value
            fcntl-flock
            memoize
            strip-keyword-arguments
            default-keyword-arguments
            substitute-keyword-arguments
            ensure-keyword-arguments

            <location>
            location
            location?
            location-file
            location-line
            location-column
            source-properties->location

            nix-system->gnu-triplet
            gnu-triplet->nix-system
            %current-system
            %current-target-system
            package-name->name+version
            version-compare
            version>?
            version>=?
            version-prefix
            version-major+minor
            guile-version>?
            string-replace-substring
            arguments-from-environment-variable
            file-extension
            file-sans-extension
            switch-symlinks
            call-with-temporary-output-file
            call-with-temporary-directory
            with-atomic-file-output
            fold2
            fold-tree
            fold-tree-leaves
            split
            cache-directory
            readlink*

            filtered-port
            compressed-port
            decompressed-port
            call-with-decompressed-port
            compressed-output-port
            call-with-compressed-output-port
            canonical-newline-port))


;;;
;;; Compile-time computations.
;;;

(define-syntax compile-time-value
  (syntax-rules ()
    "Evaluate the given expression at compile time.  The expression must
evaluate to a simple datum."
    ((_ exp)
     (let-syntax ((v (lambda (s)
                       (let ((val exp))
                         (syntax-case s ()
                           (_ #`'#,(datum->syntax s val)))))))
       v))))


;;;
;;; Base 16.
;;;

(define (bytevector->base16-string bv)
  "Return the hexadecimal representation of BV's contents."
  (define len
    (bytevector-length bv))

  (let-syntax ((base16-chars (lambda (s)
                               (syntax-case s ()
                                 (_
                                  (let ((v (list->vector
                                            (unfold (cut > <> 255)
                                                    (lambda (n)
                                                      (format #f "~2,'0x" n))
                                                    1+
                                                    0))))
                                    v))))))
    (define chars base16-chars)
    (let loop ((i len)
               (r '()))
      (if (zero? i)
          (string-concatenate r)
          (let ((i (- i 1)))
            (loop i
                  (cons (vector-ref chars (bytevector-u8-ref bv i)) r)))))))

(define base16-string->bytevector
  (let ((chars->value (fold (lambda (i r)
                              (vhash-consv (string-ref (number->string i 16)
                                                       0)
                                           i r))
                            vlist-null
                            (iota 16))))
    (lambda (s)
      "Return the bytevector whose hexadecimal representation is string S."
      (define bv
        (make-bytevector (quotient (string-length s) 2) 0))

      (string-fold (lambda (chr i)
                     (let ((j (quotient i 2))
                           (v (and=> (vhash-assv chr chars->value) cdr)))
                       (if v
                           (if (zero? (logand i 1))
                               (bytevector-u8-set! bv j
                                                   (arithmetic-shift v 4))
                               (let ((w (bytevector-u8-ref bv j)))
                                 (bytevector-u8-set! bv j (logior v w))))
                           (error "invalid hexadecimal character" chr)))
                     (+ i 1))
                   0
                   s)
      bv)))



;;;
;;; Filtering & pipes.
;;;

(define (filtered-port command input)
  "Return an input port where data drained from INPUT is filtered through
COMMAND (a list).  In addition, return a list of PIDs that the caller must
wait.  When INPUT is a file port, it must be unbuffered; otherwise, any
buffered data is lost."
  (let loop ((input input)
             (pids  '()))
    (if (file-port? input)
        (match (pipe)
          ((in . out)
           (match (primitive-fork)
             (0
              (dynamic-wind
                (const #f)
                (lambda ()
                  (close-port in)
                  (close-port (current-input-port))
                  (dup2 (fileno input) 0)
                  (close-port (current-output-port))
                  (dup2 (fileno out) 1)
                  (catch 'system-error
                    (lambda ()
                      (apply execl (car command) command))
                    (lambda args
                      (format (current-error-port)
                              "filtered-port: failed to execute '~{~a ~}': ~a~%"
                              command (strerror (system-error-errno args))))))
                (lambda ()
                  (primitive-_exit 1))))
             (child
              (close-port out)
              (values in (cons child pids))))))

        ;; INPUT is not a file port, so fork just for the sake of tunneling it
        ;; through a file port.
        (match (pipe)
          ((in . out)
           (match (primitive-fork)
             (0
              (dynamic-wind
                (const #t)
                (lambda ()
                  (close-port in)
                  (dump-port input out))
                (lambda ()
                  (false-if-exception (close out))
                  (primitive-_exit 0))))
             (child
              (close-port out)
              (loop in (cons child pids)))))))))

(define (decompressed-port compression input)
  "Return an input port where INPUT is decompressed according to COMPRESSION,
a symbol such as 'xz."
  (match compression
    ((or #f 'none) (values input '()))
    ('bzip2        (filtered-port `(,%bzip2 "-dc") input))
    ('xz           (filtered-port `(,%xz "-dc") input))
    ('gzip         (filtered-port `(,%gzip "-dc") input))
    (else          (error "unsupported compression scheme" compression))))

(define (compressed-port compression input)
  "Return an input port where INPUT is decompressed according to COMPRESSION,
a symbol such as 'xz."
  (match compression
    ((or #f 'none) (values input '()))
    ('bzip2        (filtered-port `(,%bzip2 "-c") input))
    ('xz           (filtered-port `(,%xz "-c") input))
    ('gzip         (filtered-port `(,%gzip "-c") input))
    (else          (error "unsupported compression scheme" compression))))

(define (call-with-decompressed-port compression port proc)
  "Call PROC with a wrapper around PORT, a file port, that decompresses data
read from PORT according to COMPRESSION, a symbol such as 'xz."
  (let-values (((decompressed pids)
                (decompressed-port compression port)))
    (dynamic-wind
      (const #f)
      (lambda ()
        (proc decompressed))
      (lambda ()
        (close-port decompressed)
        (unless (every (compose zero? cdr waitpid) pids)
          (error "decompressed-port failure" pids))))))

(define (filtered-output-port command output)
  "Return an output port.  Data written to that port is filtered through
COMMAND and written to OUTPUT, an output file port.  In addition, return a
list of PIDs to wait for.  OUTPUT must be unbuffered; otherwise, any buffered
data is lost."
  (match (pipe)
    ((in . out)
     (match (primitive-fork)
       (0
        (dynamic-wind
          (const #f)
          (lambda ()
            (close-port out)
            (close-port (current-input-port))
            (dup2 (fileno in) 0)
            (close-port (current-output-port))
            (dup2 (fileno output) 1)
            (catch 'system-error
              (lambda ()
                (apply execl (car command) command))
              (lambda args
                (format (current-error-port)
                        "filtered-output-port: failed to execute '~{~a ~}': ~a~%"
                        command (strerror (system-error-errno args))))))
          (lambda ()
            (primitive-_exit 1))))
       (child
        (close-port in)
        (values out (list child)))))))

(define* (compressed-output-port compression output
                                 #:key (options '()))
  "Return an output port whose input is compressed according to COMPRESSION,
a symbol such as 'xz, and then written to OUTPUT.  In addition return a list
of PIDs to wait for.  OPTIONS is a list of strings passed to the compression
program--e.g., '(\"--fast\")."
  (match compression
    ((or #f 'none) (values output '()))
    ('bzip2        (filtered-output-port `(,%bzip2 "-c" ,@options) output))
    ('xz           (filtered-output-port `(,%xz "-c" ,@options) output))
    ('gzip         (filtered-output-port `(,%gzip "-c" ,@options) output))
    (else          (error "unsupported compression scheme" compression))))

(define* (call-with-compressed-output-port compression port proc
                                           #:key (options '()))
  "Call PROC with a wrapper around PORT, a file port, that compresses data
that goes to PORT according to COMPRESSION, a symbol such as 'xz.  OPTIONS is
a list of command-line arguments passed to the compression program."
  (let-values (((compressed pids)
                (compressed-output-port compression port
                                        #:options options)))
    (dynamic-wind
      (const #f)
      (lambda ()
        (proc compressed))
      (lambda ()
        (close-port compressed)
        (unless (every (compose zero? cdr waitpid) pids)
          (error "compressed-output-port failure" pids))))))


;;;
;;; Advisory file locking.
;;;

(define %struct-flock
  ;; 'struct flock' from <fcntl.h>.
  (list short                                     ; l_type
        short                                     ; l_whence
        size_t                                    ; l_start
        size_t                                    ; l_len
        int))                                     ; l_pid

(define F_SETLKW
  ;; On Linux-based systems, this is usually 7, but not always
  ;; (exceptions include SPARC.)  On GNU/Hurd, it's 9.
  (compile-time-value
   (cond ((string-contains %host-type "sparc") 9) ; sparc-*-linux-gnu
         ((string-contains %host-type "linux") 7) ; *-linux-gnu
         (else 9))))                              ; *-gnu*

(define F_SETLK
  ;; Likewise: GNU/Hurd and SPARC use 8, while the others typically use 6.
  (compile-time-value
   (cond ((string-contains %host-type "sparc") 8) ; sparc-*-linux-gnu
         ((string-contains %host-type "linux") 6) ; *-linux-gnu
         (else 8))))                              ; *-gnu*

(define F_xxLCK
  ;; The F_RDLCK, F_WRLCK, and F_UNLCK constants.
  (compile-time-value
   (cond ((string-contains %host-type "sparc") #(1 2 3))    ; sparc-*-linux-gnu
         ((string-contains %host-type "hppa")  #(1 2 3))    ; hppa-*-linux-gnu
         ((string-contains %host-type "linux") #(0 1 2))    ; *-linux-gnu
         (else                                 #(1 2 3))))) ; *-gnu*

(define fcntl-flock
  (let* ((ptr  (dynamic-func "fcntl" (dynamic-link)))
         (proc (pointer->procedure int ptr `(,int ,int *))))
    (lambda* (fd-or-port operation #:key (wait? #t))
      "Perform locking OPERATION on the file beneath FD-OR-PORT.  OPERATION
must be a symbol, one of 'read-lock, 'write-lock, or 'unlock.  When WAIT? is
true, block until the lock is acquired; otherwise, thrown an 'flock-error'
exception if it's already taken."
      (define (operation->int op)
        (case op
          ((read-lock)  (vector-ref F_xxLCK 0))
          ((write-lock) (vector-ref F_xxLCK 1))
          ((unlock)     (vector-ref F_xxLCK 2))
          (else         (error "invalid fcntl-flock operation" op))))

      (define fd
        (if (port? fd-or-port)
            (fileno fd-or-port)
            fd-or-port))

      ;; XXX: 'fcntl' is a vararg function, but here we happily use the
      ;; standard ABI; crossing fingers.
      (let ((err (proc fd
                       (if wait?
                           F_SETLKW               ; lock & wait
                           F_SETLK)               ; non-blocking attempt
                       (make-c-struct %struct-flock
                                      (list (operation->int operation)
                                            SEEK_SET
                                            0 0   ; whole file
                                            0)))))
        (or (zero? err)

            ;; Presumably we got EAGAIN or so.
            (throw 'flock-error (errno)))))))


;;;
;;; Miscellaneous.
;;;

(define (memoize proc)
  "Return a memoizing version of PROC."
  (let ((cache (make-hash-table)))
    (lambda args
      (let ((results (hash-ref cache args)))
        (if results
            (apply values results)
            (let ((results (call-with-values (lambda ()
                                               (apply proc args))
                             list)))
              (hash-set! cache args results)
              (apply values results)))))))

(define (strip-keyword-arguments keywords args)
  "Remove all of the keyword arguments listed in KEYWORDS from ARGS."
  (let loop ((args   args)
             (result '()))
    (match args
      (()
       (reverse result))
      (((? keyword? kw) arg . rest)
       (loop rest
             (if (memq kw keywords)
                 result
                 (cons* arg kw result))))
      ((head . tail)
       (loop tail (cons head result))))))

(define (default-keyword-arguments args defaults)
  "Return ARGS augmented with any keyword/value from DEFAULTS for
keywords not already present in ARGS."
  (let loop ((defaults defaults)
             (args     args))
    (match defaults
      ((kw value rest ...)
       (loop rest
             (if (assoc-ref kw args)
                 args
                 (cons* kw value args))))
      (()
       args))))

(define-syntax substitute-keyword-arguments
  (syntax-rules ()
    "Return a new list of arguments where the value for keyword arg KW is
replaced by EXP.  EXP is evaluated in a context where VAR is boud to the
previous value of the keyword argument."
    ((_ original-args ((kw var) exp) ...)
     (let loop ((args    original-args)
                (before '()))
       (match args
         ((kw var rest (... ...))
          (loop rest (cons* exp kw before)))
         ...
         ((x rest (... ...))
          (loop rest (cons x before)))
         (()
          (reverse before)))))))

(define (delkw kw lst)
  "Remove KW and its associated value from LST, a keyword/value list such
as '(#:foo 1 #:bar 2)."
  (let loop ((lst    lst)
             (result '()))
    (match lst
      (()
       (reverse result))
      ((kw? value rest ...)
       (if (eq? kw? kw)
           (append (reverse result) rest)
           (loop rest (cons* value kw? result)))))))

(define (ensure-keyword-arguments args kw/values)
  "Force the keywords arguments KW/VALUES in the keyword argument list ARGS.
For instance:

  (ensure-keyword-arguments '(#:foo 2) '(#:foo 2))
  => (#:foo 2)

  (ensure-keyword-arguments '(#:foo 2) '(#:bar 3))
  => (#:foo 2 #:bar 3)

  (ensure-keyword-arguments '(#:foo 2) '(#:bar 3 #:foo 42))
  => (#:foo 42 #:bar 3)
"
  (let loop ((args      args)
             (kw/values kw/values)
             (result    '()))
    (match args
      (()
       (append (reverse result) kw/values))
      ((kw value rest ...)
       (match (memq kw kw/values)
         ((_ value . _)
          (loop rest (delkw kw kw/values) (cons* value kw result)))
         (#f
          (loop rest kw/values (cons* value kw result))))))))

(define* (nix-system->gnu-triplet
          #:optional (system (%current-system)) (vendor "unknown"))
  "Return a guess of the GNU triplet corresponding to Nix system
identifier SYSTEM."
  (match system
    ("armhf-linux"
     (string-append "arm-" vendor "-linux-gnueabihf"))
    (_
     (let* ((dash (string-index system #\-))
            (arch (substring system 0 dash))
            (os   (substring system (+ 1 dash))))
       (string-append arch
                      "-" vendor "-"
                      (if (string=? os "linux")
                          "linux-gnu"
                          os))))))

(define (gnu-triplet->nix-system triplet)
  "Return the Nix system type corresponding to TRIPLET, a GNU triplet as
returned by `config.guess'."
  (let ((triplet (cond ((string-match "^i[345]86-(.*)$" triplet)
                        =>
                        (lambda (m)
                          (string-append "i686-" (match:substring m 1))))
                       (else triplet))))
    (cond ((string-match "^arm[^-]*-([^-]+-)?linux-gnueabihf" triplet)
           "armhf-linux")
          ((string-match "^([^-]+)-([^-]+-)?linux-gnu.*" triplet)
           =>
           (lambda (m)
             ;; Nix omits `-gnu' for GNU/Linux.
             (string-append (match:substring m 1) "-linux")))
          ((string-match "^([^-]+)-([^-]+-)?([[:alpha:]]+)([0-9]+\\.?)*$" triplet)
           =>
           (lambda (m)
             ;; Nix strip the version number from names such as `gnu0.3',
             ;; `darwin10.2.0', etc., and always strips the vendor part.
             (string-append (match:substring m 1) "-"
                            (match:substring m 3))))
          (else triplet))))

(define %current-system
  ;; System type as expected by Nix, usually ARCHITECTURE-KERNEL.
  ;; By default, this is equal to (gnu-triplet->nix-system %host-type).
  (make-parameter %system))

(define %current-target-system
  ;; Either #f or a GNU triplet representing the target system we are
  ;; cross-building to.
  (make-parameter #f))

(define (package-name->name+version spec)
  "Given SPEC, a package name like \"foo@0.9.1b\", return two values: \"foo\"
and \"0.9.1b\".  When the version part is unavailable, SPEC and #f are
returned.  Both parts must not contain any '@'."
  (match (string-rindex spec #\@)
    (#f  (values spec #f))
    (idx (values (substring spec 0 idx)
                 (substring spec (1+ idx))))))

(define version-compare
  (let ((strverscmp
         (let ((sym (or (dynamic-func "strverscmp" (dynamic-link))
                        (error "could not find `strverscmp' (from GNU libc)"))))
           (pointer->procedure int sym (list '* '*)))))
    (lambda (a b)
      "Return '> when A denotes a newer version than B,
'< when A denotes a older version than B,
or '= when they denote equal versions."
      (let ((result (strverscmp (string->pointer a) (string->pointer b))))
        (cond ((positive? result) '>)
              ((negative? result) '<)
              (else '=))))))

(define (version-prefix version-string num-parts)
  "Truncate version-string to the first num-parts components of the version.
For example, (version-prefix \"2.1.47.4.23\" 3) returns \"2.1.47\""
  (string-join (take (string-split version-string #\.) num-parts) "."))


(define (version-major+minor version-string)
  "Return \"<major>.<minor>\", where major and minor are the major and
minor version numbers from version-string."
  (version-prefix version-string 2))

(define (version>? a b)
  "Return #t when A denotes a version strictly newer than B."
  (eq? '> (version-compare a b)))

(define (version>=? a b)
  "Return #t when A denotes a version newer or equal to B."
  (case (version-compare a b)
    ((> =) #t)
    (else #f)))

(define (guile-version>? str)
  "Return #t if the running Guile version is greater than STR."
  ;; Note: Using (version>? (version) "2.0.5") or similar doesn't work,
  ;; because the result of (version) can have a prefix, like "2.0.5-deb1".
  (version>? (string-append (major-version) "."
                            (minor-version) "."
                            (micro-version))
             str))

(define (file-extension file)
  "Return the extension of FILE or #f if there is none."
  (let ((dot (string-rindex file #\.)))
    (and dot (substring file (+ 1 dot) (string-length file)))))

(define (file-sans-extension file)
  "Return the substring of FILE without its extension, if any."
  (let ((dot (string-rindex file #\.)))
    (if dot
        (substring file 0 dot)
        file)))

(define (switch-symlinks link target)
  "Atomically switch LINK, a symbolic link, to point to TARGET.  Works
both when LINK already exists and when it does not."
  (let ((pivot (string-append link ".new")))
    (symlink target pivot)
    (rename-file pivot link)))

(define* (string-replace-substring str substr replacement
                                   #:optional
                                   (start 0)
                                   (end (string-length str)))
  "Replace all occurrences of SUBSTR in the START--END range of STR by
REPLACEMENT."
  (match (string-length substr)
    (0
     (error "string-replace-substring: empty substring"))
    (substr-length
     (let loop ((start  start)
                (pieces (list (substring str 0 start))))
       (match (string-contains str substr start end)
         (#f
          (string-concatenate-reverse
           (cons (substring str start) pieces)))
         (index
          (loop (+ index substr-length)
                (cons* replacement
                       (substring str start index)
                       pieces))))))))

(define (arguments-from-environment-variable variable)
  "Retrieve value of environment variable denoted by string VARIABLE in the
form of a list of strings (`char-set:graphic' tokens) suitable for consumption
by `args-fold', if VARIABLE is defined, otherwise return an empty list."
  (let ((env (getenv variable)))
    (if env
        (string-tokenize env char-set:graphic)
        '())))

(define (call-with-temporary-output-file proc)
  "Call PROC with a name of a temporary file and open output port to that
file; close the file and delete it when leaving the dynamic extent of this
call."
  (let* ((directory (or (getenv "TMPDIR") "/tmp"))
         (template  (string-append directory "/guix-file.XXXXXX"))
         (out       (mkstemp! template)))
    (dynamic-wind
      (lambda ()
        #t)
      (lambda ()
        (proc template out))
      (lambda ()
        (false-if-exception (close out))
        (false-if-exception (delete-file template))))))

(define (call-with-temporary-directory proc)
  "Call PROC with a name of a temporary directory; close the directory and
delete it when leaving the dynamic extent of this call."
  (let* ((directory (or (getenv "TMPDIR") "/tmp"))
         (template  (string-append directory "/guix-directory.XXXXXX"))
         (tmp-dir   (mkdtemp! template)))
    (dynamic-wind
      (const #t)
      (lambda ()
        (proc tmp-dir))
      (lambda ()
        (false-if-exception (rmdir tmp-dir))))))

(define (with-atomic-file-output file proc)
  "Call PROC with an output port for the file that is going to replace FILE.
Upon success, FILE is atomically replaced by what has been written to the
output port, and PROC's result is returned."
  (let* ((template (string-append file ".XXXXXX"))
         (out      (mkstemp! template)))
    (with-throw-handler #t
      (lambda ()
        (let ((result (proc out)))
          (close out)
          (rename-file template file)
          result))
      (lambda (key . args)
        (false-if-exception (delete-file template))))))

(define fold2
  (case-lambda
    ((proc seed1 seed2 lst)
     "Like `fold', but with a single list and two seeds."
     (let loop ((result1 seed1)
                (result2 seed2)
                (lst     lst))
       (if (null? lst)
           (values result1 result2)
           (call-with-values
               (lambda () (proc (car lst) result1 result2))
             (lambda (result1 result2)
               (loop result1 result2 (cdr lst)))))))
    ((proc seed1 seed2 lst1 lst2)
     "Like `fold', but with a two lists and two seeds."
     (let loop ((result1 seed1)
                (result2 seed2)
                (lst1    lst1)
                (lst2    lst2))
       (if (or (null? lst1) (null? lst2))
           (values result1 result2)
           (call-with-values
               (lambda () (proc (car lst1) (car lst2) result1 result2))
             (lambda (result1 result2)
               (fold2 proc result1 result2 (cdr lst1) (cdr lst2)))))))))

(define (fold-tree proc init children roots)
  "Call (PROC NODE RESULT) for each node in the tree that is reachable from
ROOTS, using INIT as the initial value of RESULT.  The order in which nodes
are traversed is not specified, however, each node is visited only once, based
on an eq? check.  Children of a node to be visited are generated by
calling (CHILDREN NODE), the result of which should be a list of nodes that
are connected to NODE in the tree, or '() or #f if NODE is a leaf node."
  (let loop ((result init)
             (seen vlist-null)
             (lst roots))
    (match lst
      (() result)
      ((head . tail)
       (if (not (vhash-assq head seen))
           (loop (proc head result)
                 (vhash-consq head #t seen)
                 (match (children head)
                   ((or () #f) tail)
                   (children (append tail children))))
           (loop result seen tail))))))

(define (fold-tree-leaves proc init children roots)
  "Like fold-tree, but call (PROC NODE RESULT) only for leaf nodes."
  (fold-tree
   (lambda (node result)
     (match (children node)
       ((or () #f) (proc node result))
       (else result)))
   init children roots))

(define (split lst e)
  "Return two values, a list containing the elements of the list LST that
appear before the first occurence of the object E and a list containing the
elements after E."
  (define (same? x)
    (equal? e x))

  (let loop ((rest lst)
             (acc '()))
    (match rest
      (()
       (values lst '()))
      (((? same?) . tail)
       (values (reverse acc) tail))
      ((head . tail)
       (loop tail (cons head acc))))))

(define (cache-directory)
  "Return the cache directory for Guix, by default ~/.cache/guix."
  (or (getenv "XDG_CONFIG_HOME")
      (and=> (getenv "HOME")
             (cut string-append <> "/.cache/guix"))))

(define (readlink* file)
  "Call 'readlink' until the result is not a symlink."
  (define %max-symlink-depth 50)

  (let loop ((file  file)
             (depth 0))
    (define (absolute target)
      (if (absolute-file-name? target)
          target
          (string-append (dirname file) "/" target)))

    (if (>= depth %max-symlink-depth)
        file
        (call-with-values
            (lambda ()
              (catch 'system-error
                (lambda ()
                  (values #t (readlink file)))
                (lambda args
                  (let ((errno (system-error-errno args)))
                    (if (or (= errno EINVAL))
                        (values #f file)
                        (apply throw args))))))
          (lambda (success? target)
            (if success?
                (loop (absolute target) (+ depth 1))
                file))))))

(define (canonical-newline-port port)
  "Return an input port that wraps PORT such that all newlines consist
  of a single carriage return."
  (define (get-position)
    (if (port-has-port-position? port) (port-position port) #f))
  (define (set-position! position)
    (if (port-has-set-port-position!? port)
        (set-port-position! position port)
        #f))
  (define (close) (close-port port))
  (define (read! bv start n)
    (let loop ((count 0)
               (byte (get-u8 port)))
      (cond ((eof-object? byte) count)
            ((= count (- n 1))
             (bytevector-u8-set! bv (+ start count) byte)
             n)
            ;; XXX: consume all LFs even if not followed by CR.
            ((eqv? byte (char->integer #\return)) (loop count (get-u8 port)))
            (else
             (bytevector-u8-set! bv (+ start count) byte)
             (loop (+ count 1) (get-u8 port))))))
  (make-custom-binary-input-port "canonical-newline-port"
                                 read!
                                 get-position
                                 set-position!
                                 close))

;;;
;;; Source location.
;;;

;; A source location.
(define-record-type <location>
  (make-location file line column)
  location?
  (file          location-file)                   ; file name
  (line          location-line)                   ; 1-indexed line
  (column        location-column))                ; 0-indexed column

(define location
  (memoize
   (lambda (file line column)
     "Return the <location> object for the given FILE, LINE, and COLUMN."
     (and line column file
          (make-location file line column)))))

(define (source-properties->location loc)
  "Return a location object based on the info in LOC, an alist as returned
by Guile's `source-properties', `frame-source', `current-source-location',
etc."
  (let ((file (assq-ref loc 'filename))
        (line (assq-ref loc 'line))
        (col  (assq-ref loc 'column)))
    ;; In accordance with the GCS, start line and column numbers at 1.  Note
    ;; that unlike LINE and `port-column', COL is actually 1-indexed here...
    (location file (and line (+ line 1)) col)))
