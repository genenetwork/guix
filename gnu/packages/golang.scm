;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2016 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2016 Matthew Jordan <matthewjordandevops@yandex.com>
;;; Copyright © 2016 Andy Wingo <wingo@igalia.com>
;;;
;;; This file is an addendum GNU Guix.
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

(define-module (gnu packages golang)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix utils)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages base)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pcre)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1))

;; According to https://golang.org/doc/install/gccgo, gccgo-4.8.2 includes a
;; complete go-1.1.2 implementation, gccgo-4.9 includes a complete go-1.2
;; implementation, and gccgo-5 a complete implementation of go-1.4.  Ultimately
;; we hope to build go-1.5+ with a bootstrap process using gccgo-5.  As of
;; go-1.5, go cannot be bootstrapped without go-1.4, so we need to use go-1.4 or
;; gccgo-5.  Mips is not officially supported, but it should work if it is
;; bootstrapped.

(define-public go-1.4
  (package
    (name "go")
    (version "1.4.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://storage.googleapis.com/golang/"
                                  name version ".src.tar.gz"))
              (sha256
               (base32
                "0na9yqilzpvq0bjndbibfp07wr796gf252y471cip10bbdqgqiwr"))))
    (build-system gnu-build-system)
    (outputs '("out"
               "doc"
               "tests"))
    (arguments
     `(#:modules ((ice-9 match)
                  (guix build gnu-build-system)
                  (guix build utils))
       #:tests? #f ; Tests are run by the all.bash script.
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (add-after 'patch-generated-file-shebangs 'chdir
           (lambda _
             (chdir "src")))
         (add-before 'build 'prebuild
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((gcclib (string-append (assoc-ref inputs "gcc:lib") "/lib"))
                    (ld (string-append (assoc-ref inputs "libc") "/lib"))
                    (loader (car (find-files ld "^ld-linux.+")))
                    (net-base (assoc-ref inputs "net-base"))
                    (tzdata-path
                     (string-append (assoc-ref inputs "tzdata") "/share/zoneinfo"))
                    (output (assoc-ref outputs "out")))

               ;; Removing net/ tests, which fail when attempting to access
               ;; network resources not present in the build container.
               (for-each delete-file
                         '("net/multicast_test.go" "net/parse_test.go"
                           "net/port_test.go"))

               ;; Add libgcc to the RUNPATH.
               (substitute* "cmd/go/build.go"
                 (("cgoldflags := \\[\\]string\\{\\}")
                  (string-append "cgoldflags := []string{"
                                 "\"-rpath=" gcclib "\"}"))
                 (("ldflags := buildLdflags")
                  (string-append
                   "ldflags := buildLdflags\n"
                   "ldflags = append(ldflags, \"-r\")\n"
                   "ldflags = append(ldflags, \"" gcclib "\")\n")))

               (substitute* "os/os_test.go"
                 (("/usr/bin") (getcwd))
                 (("/bin/pwd") (which "pwd")))

               ;; Disable failing tests: these tests attempt to access
               ;; commands or network resources which are neither available or
               ;; necessary for the build to succeed.
               (for-each
                (match-lambda
                  ((file regex)
                   (substitute* file
                     ((regex all before test_name)
                      (string-append before "Disabled" test_name)))))
                '(("net/net_test.go" "(.+)(TestShutdownUnix.+)")
                  ("net/dial_test.go" "(.+)(TestDialTimeout.+)")
                  ("os/os_test.go" "(.+)(TestHostname.+)")
                  ("time/format_test.go" "(.+)(TestParseInSydney.+)")
                  ("os/exec/exec_test.go" "(.+)(TestEcho.+)")
                  ("os/exec/exec_test.go" "(.+)(TestCommandRelativeName.+)")
                  ("os/exec/exec_test.go" "(.+)(TestCatStdin.+)")
                  ("os/exec/exec_test.go" "(.+)(TestCatGoodAndBadFile.+)")
                  ("os/exec/exec_test.go" "(.+)(TestExitStatus.+)")
                  ("os/exec/exec_test.go" "(.+)(TestPipes.+)")
                  ("os/exec/exec_test.go" "(.+)(TestStdinClose.+)")
                  ("syscall/syscall_unix_test.go" "(.+)(TestPassFD\\(.+)")
                  ("os/exec/exec_test.go" "(.+)(TestExtraFiles.+)")))

               (substitute* "net/lookup_unix.go"
                 (("/etc/protocols") (string-append net-base "/etc/protocols")))
               (substitute* "time/zoneinfo_unix.go"
                 (("/usr/share/zoneinfo/") tzdata-path))
               (substitute* (find-files "cmd" "asm.c")
                 (("/lib/ld-linux.*\\.so\\.[0-9]") loader))
               #t)))

         (replace 'build
           (lambda* (#:key inputs outputs #:allow-other-keys)
             ;; FIXME: Some of the .a files are not bit-reproducible.
             (let* ((output (assoc-ref outputs "out")))
               (setenv "CC" (which "gcc"))
               (setenv "GOOS" "linux")
               (setenv "GOROOT" (dirname (getcwd)))
               (setenv "GOROOT_FINAL" output)
               (setenv "CGO_ENABLED" "1")
               (zero? (system* "sh" "all.bash")))))

         (replace 'install
           (lambda* (#:key outputs inputs #:allow-other-keys)
             (let* ((output (assoc-ref outputs "out"))
                    (doc_out (assoc-ref outputs "doc"))
                    (bash (string-append (assoc-ref inputs "bash") "bin/bash"))
                    (docs (string-append doc_out "/share/doc/" ,name "-" ,version))
                    (tests (string-append
                            (assoc-ref outputs "tests") "/share/" ,name "-" ,version)))
               (mkdir-p tests)
               (copy-recursively "../test" (string-append tests "/test"))
               (delete-file-recursively "../test")
               (mkdir-p docs)
               (copy-recursively "../api" (string-append docs "/api"))
               (delete-file-recursively "../api")
               (copy-recursively "../doc" (string-append docs "/doc"))
               (delete-file-recursively "../doc")

               (for-each (lambda (file)
                           (let ((file (string-append "../" file)))
                             (install-file file docs)
                             (delete-file file)))
                         '("README" "CONTRIBUTORS" "AUTHORS" "PATENTS"
                           "LICENSE" "VERSION" "robots.txt"))
               (copy-recursively "../" output)
               #t))))))
    (inputs
     `(("tzdata" ,tzdata)
       ("pcre" ,pcre)
       ("gcc:lib" ,gcc "lib")))
    (native-inputs
     `(("pkg-config" ,%pkg-config)
       ("which" ,which)
       ("net-base" ,net-base)
       ("perl" ,perl)))

    (home-page "https://golang.org/")
    (synopsis "Compiler and libraries for Go, a statically-typed language")
    (description "Go, also commonly referred to as golang, is an imperative
programming language.  Designed primarily for systems programming, it is a
compiled, statically typed language in the tradition of C and C++, with
garbage collection, various safety features and in the style of communicating
sequential processes (CSP) concurrent programming features added.")
    (license license:bsd-3)))
