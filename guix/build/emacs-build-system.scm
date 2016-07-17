;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Federico Beffa <beffa@fbengineering.ch>
;;; Copyright © 2016 David Thompson <davet@gnu.org>
;;; Copyright © 2016 Alex Kost <alezost@gmail.com>
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

(define-module (guix build emacs-build-system)
  #:use-module ((guix build gnu-build-system) #:prefix gnu:)
  #:use-module (guix build utils)
  #:use-module (guix build emacs-utils)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-11)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 match)
  #:export (%standard-phases
            emacs-build))

;; Commentary:
;;
;; Builder-side code of the build procedure for ELPA Emacs packages.
;;
;; Code:

;; Directory suffix where we install ELPA packages.  We avoid ".../elpa" as
;; Emacs expects to find the ELPA repository 'archive-contents' file and the
;; archive signature.
(define %install-suffix "/share/emacs/site-lisp/guix.d")

(define gnu:unpack (assoc-ref gnu:%standard-phases 'unpack))

(define (store-file->elisp-source-file file)
  "Convert FILE, a store file name for an Emacs Lisp source file, into a file
name that has been stripped of the hash and version number."
  (let-values (((name version)
                (package-name->name+version
                 (strip-store-file-name file))))
    (string-append name ".el")))

(define* (unpack #:key source #:allow-other-keys)
  "Unpack SOURCE into the build directory.  SOURCE may be a compressed
archive, a directory, or an Emacs Lisp file."
  (if (string-suffix? ".el" source)
      (begin
        (mkdir "source")
        (chdir "source")
        (copy-file source (store-file->elisp-source-file source))
        #t)
      (gnu:unpack #:source source)))

(define* (build #:key outputs inputs #:allow-other-keys)
  "Compile .el files."
  (let* ((emacs (string-append (assoc-ref inputs "emacs") "/bin/emacs"))
         (out (assoc-ref outputs "out"))
         (elpa-name-ver (store-directory->elpa-name-version out))
         (el-dir (string-append out %install-suffix "/" elpa-name-ver))
         (deps-dirs (emacs-inputs-directories inputs)))
    (setenv "SHELL" "sh")
    (parameterize ((%emacs emacs))
      (emacs-byte-compile-directory el-dir
                                    (emacs-inputs-el-directories deps-dirs)))))

(define* (patch-el-files #:key outputs #:allow-other-keys)
  "Substitute the absolute \"/bin/\" directory with the right location in the
store in '.el' files."
  (let* ((out (assoc-ref outputs "out"))
         (elpa-name-ver (store-directory->elpa-name-version out))
         (el-dir (string-append out %install-suffix "/" elpa-name-ver))
         (substitute-cmd (lambda ()
                           (substitute* (find-files "." "\\.el$")
                             (("\"/bin/([^.].*)\"" _ cmd)
                              (string-append "\"" (which cmd) "\""))))))
    (with-directory-excursion el-dir
      ;; Some old '.el' files (e.g., tex-buf.el in AUCTeX) are still encoded
      ;; with the "ISO-8859-1" locale.
      (unless (false-if-exception (substitute-cmd))
        (with-fluids ((%default-port-encoding "ISO-8859-1"))
          (substitute-cmd))))
    #t))

(define* (install #:key outputs #:allow-other-keys)
  "Install the package contents."
  (let* ((out (assoc-ref outputs "out"))
         (elpa-name-ver (store-directory->elpa-name-version out))
         (src-dir (getcwd))
         (tgt-dir (string-append out %install-suffix "/" elpa-name-ver)))
    (copy-recursively src-dir tgt-dir)
    #t))

(define* (move-doc #:key outputs #:allow-other-keys)
  "Move info files from the ELPA package directory to the info directory."
  (let* ((out (assoc-ref outputs "out"))
         (elpa-name-ver (store-directory->elpa-name-version out))
         (el-dir (string-append out %install-suffix "/" elpa-name-ver))
         (name-ver (strip-store-file-name out))
         (info-dir (string-append out "/share/info/"))
         (info-files (find-files el-dir "\\.info$")))
    (unless (null? info-files)
      (mkdir-p info-dir)
      (with-directory-excursion el-dir
        (when (file-exists? "dir") (delete-file "dir"))
        (for-each (lambda (f)
                    (copy-file f (string-append info-dir "/" (basename f)))
                    (delete-file f))
                  info-files)))
    #t))

(define* (make-autoloads #:key outputs inputs #:allow-other-keys)
  "Generate the autoloads file."
  (let* ((emacs (string-append (assoc-ref inputs "emacs") "/bin/emacs"))
         (out (assoc-ref outputs "out"))
         (elpa-name-ver (store-directory->elpa-name-version out))
         (elpa-name (package-name->name+version elpa-name-ver))
         (el-dir (string-append out %install-suffix "/" elpa-name-ver)))
    (parameterize ((%emacs emacs))
      (emacs-generate-autoloads elpa-name el-dir))
    #t))

(define (emacs-package? name)
  "Check if NAME correspond to the name of an Emacs package."
  (string-prefix? "emacs-" name))

(define (emacs-inputs inputs)
  "Retrieve the list of Emacs packages from INPUTS."
  (filter (match-lambda
            ((label . directory)
             (emacs-package? ((compose package-name->name+version
                                       strip-store-file-name)
                              directory)))
            (_ #f))
          inputs))

(define (emacs-inputs-directories inputs)
  "Extract the list of Emacs package directories from INPUTS."
  (let ((inputs (emacs-inputs inputs)))
    (match inputs
      (((names . directories) ...) directories))))

(define (emacs-inputs-el-directories dirs)
  "Build the list of Emacs Lisp directories from the Emacs package directory
DIRS."
  (append-map (lambda (d)
                (list (string-append d "/share/emacs/site-lisp")
                      (string-append d %install-suffix "/"
                                     (store-directory->elpa-name-version d))))
              dirs))

(define (package-name-version->elpa-name-version name-ver)
  "Convert the Guix package NAME-VER to the corresponding ELPA name-version
format.  Essnetially drop the prefix used in Guix."
  (if (emacs-package? name-ver)  ; checks for "emacs-" prefix
      (string-drop name-ver (string-length "emacs-"))
      name-ver))

(define (store-directory->elpa-name-version store-dir)
  "Given a store directory STORE-DIR return the part of the basename after the
second hyphen.  This corresponds to 'name-version' as used in ELPA packages."
  ((compose package-name-version->elpa-name-version
            strip-store-file-name)
   store-dir))

(define %standard-phases
  (modify-phases gnu:%standard-phases
    (replace 'unpack unpack)
    (delete 'configure)
    (delete 'check)
    (delete 'install)
    (replace 'build build)
    (add-before 'build 'install install)
    (add-after 'install 'make-autoloads make-autoloads)
    (add-after 'make-autoloads 'patch-el-files patch-el-files)
    (add-after 'make-autoloads 'move-doc move-doc)))

(define* (emacs-build #:key inputs (phases %standard-phases)
                      #:allow-other-keys #:rest args)
  "Build the given Emacs package, applying all of PHASES in order."
  (apply gnu:gnu-build
         #:inputs inputs #:phases phases
         args))

;;; emacs-build-system.scm ends here
