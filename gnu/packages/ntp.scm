;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014 John Darrington <jmd@gnu.org>
;;; Copyright © 2014, 2015 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2015 Taylan Ulrich Bayırlı/Kammer <taylanbayirli@gmail.com>
;;; Copyright © 2015 Ludovic Courtès <ludo@gnu.org>
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

(define-module (gnu packages ntp)
  #:use-module (gnu packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages libevent)
  #:use-module ((guix licenses) #:prefix l:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (srfi srfi-1))

(define-public ntp
  (package
   (name "ntp")
   (version "4.2.8p8")
   (source (origin
	    (method url-fetch)
	    (uri (list (string-append
                         "http://archive.ntp.org/ntp4/ntp-"
                         (version-major+minor version)
                         "/ntp-" version ".tar.gz")
                       (string-append
                         "https://www.eecis.udel.edu/~ntp/ntp_spool/ntp4/ntp-"
                         (version-major+minor version)
                         "/ntp-" version ".tar.gz")))
	    (sha256
	     (base32
              "1vlpgd0dk2wkpmmf869sfxi8f46sfnmjgk51vl8n6vj5y2sx1cra"))
            (modules '((guix build utils)))
            (snippet
             '(begin
                ;; Remove the bundled copy of libevent, but we must keep
                ;; sntp/libevent/build-aux since configure.ac contains
                ;; AC_CONFIG_AUX_DIR([sntp/libevent/build-aux])
                (rename-file "sntp/libevent/build-aux"
                             "sntp/libevent:build-aux")
                (delete-file-recursively "sntp/libevent")
                (mkdir "sntp/libevent")
                (rename-file "sntp/libevent:build-aux"
                             "sntp/libevent/build-aux")
                #t))))
   (native-inputs `(("which" ,which)
                    ("pkg-config" ,pkg-config)))
   (inputs
    `(("openssl" ,openssl)
      ("libevent" ,libevent)
      ;; Build with POSIX capabilities support on GNU/Linux.  This allows 'ntpd'
      ;; to run as non-root (when invoked with '-u'.)
      ,@(if (string-suffix? "-linux"
                            (or (%current-target-system) (%current-system)))
            `(("libcap" ,libcap))
            '())))
   (arguments
    `(#:phases
      (modify-phases %standard-phases
        (add-after 'unpack 'disable-network-test
                   (lambda _
                     (substitute* "tests/libntp/Makefile.in"
                       (("test-decodenetnum\\$\\(EXEEXT\\) ") ""))
                     #t)))))
   (build-system gnu-build-system)
   (synopsis "Real time clock synchronization system")
   (description "NTP is a system designed to synchronize the clocks of
computers over a network.")
   (license (l:x11-style
             "http://www.eecis.udel.edu/~mills/ntp/html/copyright.html"
             "A non-copyleft free licence from the University of Delaware"))
   (home-page "http://www.ntp.org")))

(define-public openntpd
  (package
    (name "openntpd")
    (version "6.0p1")
    (source (origin
              (method url-fetch)
              ;; XXX Use mirror://openbsd
              (uri (string-append
                    "http://ftp.openbsd.org/pub/OpenBSD/OpenNTPD/openntpd-"
                    version ".tar.gz"))
              (sha256
               (base32
                "1s3plmxmybwpfrimq6sc54wxnn6ca7rb2g5k2bdjm4c88w4q1axi"))))
    (build-system gnu-build-system)
    (home-page "http://www.openntpd.org/")
    (synopsis "NTP client and server by the OpenBSD Project")
    (description "OpenNTPD is the OpenBSD Project's implementation of a client
and server for the Network Time Protocol.  Its design goals include being
secure, easy to configure, and accurate enough for most purposes, so it's more
minimalist than ntpd.")
    ;; A few of the source files are under bsd-3.
    (license (list l:isc l:bsd-3))))

(define-public tlsdate
  (package
    (name "tlsdate")
    (version "0.0.13")
    (home-page "https://github.com/ioerror/tlsdate")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (commit (string-append "tlsdate-" version))
                    (url home-page)))
              (sha256
               (base32
                "0w3v63qmbhpqlxjsvf4k3zp90k6mdzi8cdpgshan9iphy1f44xgl"))
              (file-name (string-append name "-" version "-checkout"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (modify-phases %standard-phases
                  (add-after 'unpack 'autogen
                    (lambda _
                      ;; The ancestor of 'SOURCE_DATE_EPOCH'; it contains the
                      ;; date that is recorded in binaries.  It must be a
                      ;; "recent date" since it is used to detect bogus dates
                      ;; received from servers.
                      (setenv "COMPILE_DATE" (number->string 1450563040))
                      (zero? (system* "sh" "autogen.sh")))))))
    (inputs `(("openssl" ,openssl)
              ("libevent" ,libevent)))
    (native-inputs `(("pkg-config" ,pkg-config)
                     ("autoconf" ,autoconf)
                     ("automake" ,automake)
                     ("libtool" ,libtool)))
    (synopsis "Extract remote time from TLS handshakes")
    (description
     "@command{tlsdate} sets the local clock by securely connecting with TLS
to remote servers and extracting the remote time out of the secure handshake.
Unlike ntpdate, @command{tlsdate} uses TCP, for instance connecting to a
remote HTTPS or TLS enabled service, and provides some protection against
adversaries that try to feed you malicious time information.")
    (license l:bsd-3)))
