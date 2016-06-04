;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014, 2015 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2016 Efraim Flashner <efraim@flashner.co.il>
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

(define-module (gnu packages pciutils)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages base))

(define-public pciutils
  (package
    (name "pciutils")
    (version "3.5.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://kernel.org/software/utils/pciutils/pciutils-"
                    version ".tar.xz"))
              (sha256
               (base32
                "0byl2f897w5lhs4bvr6p7qwcz9bllj2zyfv7nywbcbsnb9ha9wrb"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases
       (modify-phases %standard-phases
         (replace 'configure
           (lambda* (#:key outputs #:allow-other-keys)
             ;; There's no 'configure' script, just a raw makefile.
             (substitute* "Makefile"
               (("^PREFIX=.*$")
                (string-append "PREFIX := " (assoc-ref outputs "out")
                               "\n"))
               (("^MANDIR:=.*$")
                 ;; By default the thing tries to automatically
                 ;; determine whether to use $prefix/man or
                 ;; $prefix/share/man, and wrongly so.
                (string-append "MANDIR := " (assoc-ref outputs "out")
                               "/share/man\n"))
               (("^SHARED=.*$")
                ;; Build libpciutils.so.
                "SHARED := yes\n")
               (("^ZLIB=.*$")
                ;; Ask for zlib support.
                "ZLIB := yes\n"))))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             ;; Install the commands, library, and .pc files.
             (zero? (system* "make" "install" "install-lib")))))

       ;; Make sure programs have an RPATH so they can find libpciutils.so.
       #:make-flags (list (string-append "LDFLAGS=-Wl,-rpath="
                                         (assoc-ref %outputs "out") "/lib"))

       ;; No test suite.
       #:tests? #f))
    (native-inputs
     `(("which" ,which)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("kmod" ,kmod)
       ("zlib" ,zlib)))
    (home-page "http://mj.ucw.cz/sw/pciutils/")
    (synopsis "Programs for inspecting and manipulating PCI devices")
    (description
     "The PCI Utilities are a collection of programs for inspecting and
manipulating configuration of PCI devices, all based on a common portable
library libpci which offers access to the PCI configuration space on a variety
of operating systems.  This includes the 'lspci' and 'setpci' commands.")
    (license license:gpl2+)))
