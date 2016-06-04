;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Federico Beffa <beffa@fbengineering.ch>
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

(define-module (guix build-system emacs)
  #:use-module (guix store)
  #:use-module (guix utils)
  #:use-module (guix packages)
  #:use-module (guix derivations)
  #:use-module (guix search-paths)
  #:use-module (guix build-system)
  #:use-module (guix build-system gnu)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-26)
  #:export (%emacs-build-system-modules
            emacs-build
            emacs-build-system))

;; Commentary:
;;
;; Standard build procedure for Emacs packages.  This is implemented as an
;; extension of 'gnu-build-system'.
;;
;; Code:

(define %emacs-build-system-modules
  ;; Build-side modules imported by default.
  `((guix build emacs-build-system)
    (guix build emacs-utils)
    ,@%gnu-build-system-modules))

(define (default-emacs)
  "Return the default Emacs package."
  ;; Lazily resolve the binding to avoid a circular dependency.
  (let ((emacs-mod (resolve-interface '(gnu packages emacs))))
    (module-ref emacs-mod 'emacs-minimal)))

(define* (lower name
                #:key source inputs native-inputs outputs system target
                (emacs (default-emacs))
                #:allow-other-keys
                #:rest arguments)
  "Return a bag for NAME."
  (define private-keywords
    '(#:target #:emacs #:inputs #:native-inputs))

  (and (not target)                               ;XXX: no cross-compilation
       (bag
         (name name)
         (system system)
         (host-inputs `(,@(if source
                              `(("source" ,source))
                              '())
                        ,@inputs

                        ;; Keep the standard inputs of 'gnu-build-system'.
                        ,@(standard-packages)))
         (build-inputs `(("emacs" ,emacs)
                         ,@native-inputs))
         (outputs outputs)
         (build emacs-build)
         (arguments (strip-keyword-arguments private-keywords arguments)))))

(define* (emacs-build store name inputs
                      #:key source
                      (tests? #t)
                      (test-target "test")
                      (configure-flags ''())
                      (phases '(@ (guix build emacs-build-system)
                                  %standard-phases))
                      (outputs '("out"))
                      (search-paths '())
                      (system (%current-system))
                      (guile #f)
                      (imported-modules %emacs-build-system-modules)
                      (modules '((guix build emacs-build-system)
                                 (guix build utils)
                                 (guix build emacs-utils))))
  "Build SOURCE using EMACS, and with INPUTS."
  (define builder
    `(begin
       (use-modules ,@modules)
       (emacs-build #:name ,name
                    #:source ,(match (assoc-ref inputs "source")
                                (((? derivation? source))
                                 (derivation->output-path source))
                                ((source)
                                 source)
                                (source
                                 source))
                    #:configure-flags ,configure-flags
                    #:system ,system
                    #:test-target ,test-target
                    #:tests? ,tests?
                    #:phases ,phases
                    #:outputs %outputs
                    #:search-paths ',(map search-path-specification->sexp
                                          search-paths)
                    #:inputs %build-inputs)))

  (define guile-for-build
    (match guile
      ((? package?)
       (package-derivation store guile system #:graft? #f))
      (#f                                         ; the default
       (let* ((distro (resolve-interface '(gnu packages commencement)))
              (guile  (module-ref distro 'guile-final)))
         (package-derivation store guile system #:graft? #f)))))

  (build-expression->derivation store name builder
                                #:inputs inputs
                                #:system system
                                #:modules imported-modules
                                #:outputs outputs
                                #:guile-for-build guile-for-build))

(define emacs-build-system
  (build-system
    (name 'emacs)
    (description "The build system for Emacs packages")
    (lower lower)))

;;; emacs.scm ends here
