;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013, 2014 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2014, 2015, 2016 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2015, 2016 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2016 Leo Famulari <leo@famulari.name>
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

(define-module (gnu packages ssh)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages groff)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages ncurses)
  #:autoload   (gnu packages protobuf) (protobuf)
  #:autoload   (gnu packages boost) (boost)
  #:use-module (gnu packages base)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system cmake))

(define-public libssh
  (package
    (name "libssh")
    (version "0.7.3")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://red.libssh.org/attachments/download/195/libssh-"
                    version ".tar.xz"))
              (sha256
               (base32
                "165g49i4kmm3bfsjm0n8hm21kadv79g9yjqyq09138jxanz4dvr6"))))
    (build-system cmake-build-system)
    (arguments
     '(#:configure-flags '("-DWITH_GCRYPT=ON")

       ;; TODO: Add 'CMockery' and '-DWITH_TESTING=ON' for the test suite.
       #:tests? #f))
    (inputs `(("zlib" ,zlib)
              ("libgcrypt" ,libgcrypt)))
    (synopsis "SSH client library")
    (description
     "libssh is a C library implementing the SSHv2 and SSHv1 protocol for
client and server implementations.  With libssh, you can remotely execute
programs, transfer files, and use a secure and transparent tunnel for your
remote applications.")
    (home-page "http://www.libssh.org")
    (license license:lgpl2.1+)))

(define libssh-0.6 ; kept private for use in guile-ssh
  (package (inherit libssh)
    (version "0.6.5")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://red.libssh.org/attachments/"
                                  "download/121/libssh-"
                                  version ".tar.xz"))
              (sha256
               (base32
                "0b6wyx6bwbb8jpn8x4rhlrdiqwqrwrs0mxjmrnqykm9kw1ijgm8g"))
              (patches (list
                        (search-patch "libssh-0.6.5-CVE-2016-0739.patch")))))))

(define-public libssh2
  (package
   (name "libssh2")
   (version "1.7.0")
   (source (origin
            (method url-fetch)
            (uri (string-append
                   "https://www.libssh2.org/download/libssh2-"
                   version ".tar.gz"))
            (sha256
             (base32
              "116mh112w48vv9k3f15ggp5kxw5sj4b88dzb5j69llsh7ba1ymp4"))))
   (build-system gnu-build-system)
   ;; The installed libssh2.pc file does not include paths to libgcrypt and
   ;; zlib libraries, so we need to propagate the inputs.
   (propagated-inputs `(("libgcrypt" ,libgcrypt)
                        ("zlib" ,zlib)))
   (arguments '(#:configure-flags `("--with-libgcrypt")))
   (synopsis "Client-side C library implementing the SSH2 protocol")
   (description
    "libssh2 is a library intended to allow software developers access to
the SSH-2 protocol in an easy-to-use self-contained package.  It can be built
into an application to perform many different tasks when communicating with
a server that supports the SSH-2 protocol.")
   (license license:bsd-3)
   (home-page "http://www.libssh2.org/")))

(define-public openssh
  (package
   (name "openssh")
   (version "7.2p2")
   (source (origin
            (method url-fetch)
            (uri (let ((tail (string-append name "-" version ".tar.gz")))
                   (list (string-append "http://openbsd.cs.fau.de/pub/OpenBSD/OpenSSH/portable/"
                                        tail)
                         (string-append "http://ftp.fr.openbsd.org/pub/OpenBSD/OpenSSH/portable/"
                                        tail)
                         (string-append "http://ftp2.fr.openbsd.org/pub/OpenBSD/OpenSSH/portable/"
                                        tail))))
            (sha256 (base32
                     "132lh9aanb0wkisji1d6cmsxi520m8nh7c7i9wi6m1s3l38q29x7"))))
   (build-system gnu-build-system)
   (inputs `(("groff" ,groff)
             ("openssl" ,openssl)
             ("zlib" ,zlib)))
   (arguments
    `(#:test-target "tests"
      #:phases
      (modify-phases %standard-phases
        (add-after 'configure 'reset-/var/empty
         (lambda* (#:key outputs #:allow-other-keys)
           (let ((out (assoc-ref outputs "out")))
             (substitute* "Makefile"
               (("PRIVSEP_PATH=/var/empty")
                (string-append "PRIVSEP_PATH=" out "/var/empty")))
             #t)))
        (add-before 'check 'patch-tests
         (lambda _
           ;; remove 't-exec' regress target which requires user 'sshd'
           (substitute* "regress/Makefile"
             (("^(REGRESS_TARGETS=.*) t-exec(.*)" all pre post)
              (string-append pre post)))
           #t))
        (replace 'install
         (lambda* (#:key outputs (make-flags '()) #:allow-other-keys)
           ;; install without host keys and system configuration files
           (and (zero? (apply system* "make" "install-nosysconf" make-flags))
                (begin
                  (install-file "contrib/ssh-copy-id"
                                (string-append (assoc-ref outputs "out")
                                               "/bin/"))
                  (chmod (string-append (assoc-ref outputs "out")
                                        "/bin/ssh-copy-id") #o555)
                  (install-file "contrib/ssh-copy-id.1"
                                (string-append (assoc-ref outputs "out")
                                               "/share/man/man1/"))
                  #t)))))))
   (synopsis "Client and server for the secure shell (ssh) protocol")
   (description
    "The SSH2 protocol implemented in OpenSSH is standardised by the
IETF secsh working group and is specified in several RFCs and drafts.
It is composed of three layered components:

The transport layer provides algorithm negotiation and a key exchange.
The key exchange includes server authentication and results in a
cryptographically secured connection: it provides integrity, confidentiality
and optional compression.

The user authentication layer uses the established connection and relies on
the services provided by the transport layer.  It provides several mechanisms
for user authentication.  These include traditional password authentication
as well as public-key or host-based authentication mechanisms.

The connection layer multiplexes many different concurrent channels over the
authenticated connection and allows tunneling of login sessions and
TCP-forwarding.  It provides a flow control service for these channels.
Additionally, various channel-specific options can be negotiated.")
   (license (license:non-copyleft "file://LICENSE"
                               "See LICENSE in the distribution."))
   (home-page "http://www.openssh.org/")))

(define-public guile-ssh
  (package
    (name "guile-ssh")
    (version "0.9.0")
    (source (origin
              ;; ftp://memory-heap.org/software/guile-ssh/guile-ssh-VERSION.tar.gz
              ;; exists, but the server appears to be too slow and unreliable.
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/artyom-poptsov/libguile-ssh.git")
                    (commit (string-append "v" version))))
              (file-name (string-append name "-" version "-checkout"))
              (sha256
               (base32
                "04zs1cykwdyj51ag62ymrkgsja9dbhbaaglkvbfbac0bkxl2ir6d"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (alist-cons-after
                 'unpack 'autoreconf
                 (lambda* (#:key inputs #:allow-other-keys)
                   (chmod "doc/version.texi" #o777) ;make it writable
                   (zero? (system* "autoreconf" "-vfi")))
                 (alist-cons-after
                  'install 'fix-libguile-ssh-file-name
                  (lambda* (#:key outputs #:allow-other-keys)
                    (let* ((out      (assoc-ref outputs "out"))
                           (libdir   (string-append out "/lib"))
                           (guiledir (string-append out
                                                    "/share/guile/site/2.0")))
                      (substitute* (find-files guiledir ".scm")
                        (("\"libguile-ssh\"")
                         (string-append "\"" libdir "/libguile-ssh\"")))

                      ;; Make sure it works.
                      (setenv "GUILE_LOAD_PATH" guiledir)
                      (setenv "GUILE_LOAD_COMPILED_PATH" guiledir)
                      (zero?
                       (system* "guile" "-c" "(use-modules (ssh session))"))))
                  %standard-phases))
       #:configure-flags (list (string-append "--with-guilesitedir="
                                              (assoc-ref %outputs "out")
                                              "/share/guile/site/2.0"))

       ;; Tests are not parallel-safe.
       #:parallel-tests? #f))
    (native-inputs `(("autoconf" ,autoconf)
                     ("automake" ,automake)
                     ("libtool" ,libtool)
                     ("texinfo" ,texinfo)
                     ("pkg-config" ,pkg-config)
                     ("which" ,which)))
    (inputs `(("guile" ,guile-2.0)
              ("libssh" ,libssh-0.6)
              ("libgcrypt" ,libgcrypt)))
    (synopsis "Guile bindings to libssh")
    (description
     "Guile-SSH is a library that provides access to the SSH protocol for
programs written in GNU Guile interpreter.  It is a wrapper to the underlying
libssh library.")
    (home-page "https://github.com/artyom-poptsov/libguile-ssh")
    (license license:gpl3+)))

(define-public corkscrew
  (package
    (name "corkscrew")
    (version "2.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://www.agroman.net/corkscrew/corkscrew-"
                           version ".tar.gz"))
       (sha256 (base32
                "1gmhas4va6gd70i2x2mpxpwpgww6413mji29mg282jms3jscn3qd"))))
    (build-system gnu-build-system)
    (arguments
     ;; Replace configure phase as the ./configure script does not link
     ;; CONFIG_SHELL and SHELL passed as parameters
     '(#:phases
       (alist-replace
        'configure
        (lambda* (#:key outputs inputs system build target
                        #:allow-other-keys #:rest args)
          (let* ((configure (assoc-ref %standard-phases 'configure))
                 (prefix (assoc-ref outputs "out"))
                 (bash   (which "bash"))
                 ;; Set --build and --host flags as the provided config.guess
                 ;; is not able to detect them
                 (flags `(,(string-append "--prefix=" prefix)
                          ,(string-append "--build=" build)
                          ,(string-append "--host=" (or target build)))))
            (setenv "CONFIG_SHELL" bash)
            (zero? (apply system* bash
                          (string-append "." "/configure")
                          flags))))
        %standard-phases)))
    (home-page "http://www.agroman.net/corkscrew")
    (synopsis "Tunneling SSH through HTTP proxies")
    (description
     "Corkscrew allows creating TCP tunnels through HTTP proxies.  WARNING:
At the moment only plain text authentication is supported, should you require
to use it with your HTTP proxy.  Digest based authentication may be supported
in future and NTLM based authentication is most likey never be supported.")
    (license license:gpl2+)))

(define-public mosh
  (package
    (name "mosh")
    (version "1.2.5")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://mosh.mit.edu/mosh-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "1qsb0y882yfgwnpy6f98pi5xqm6kykdsrxzvaal37hs7szjhky0s"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (alist-cons-after
                 'install 'wrap
                 (lambda* (#:key outputs #:allow-other-keys)
                   ;; Make sure 'mosh' can find 'mosh-client' and
                   ;; 'mosh-server'.
                   (let* ((out (assoc-ref outputs "out"))
                          (bin (string-append out "/bin")))
                     (wrap-program (string-append bin "/mosh")
                                   `("PATH" ":" prefix (,bin)))))
                 %standard-phases)))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("openssl" ,openssl)
       ("perl" ,perl)
       ("perl-io-tty" ,perl-io-tty)
       ("zlib" ,zlib)
       ("ncurses" ,ncurses)
       ("protobuf" ,protobuf)
       ("boost-headers" ,boost)))
    (home-page "http://mosh.mit.edu/")
    (synopsis "Remote shell tolerant to intermittent connectivity")
    (description
     "Remote terminal application that allows roaming, supports intermittent
connectivity, and provides intelligent local echo and line editing of user
keystrokes.  Mosh is a replacement for SSH.  It's more robust and responsive,
especially over Wi-Fi, cellular, and long-distance links.")
    (license license:gpl3+)))

(define-public dropbear
  (package
    (name "dropbear")
    (version "2016.72")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://matt.ucc.asn.au/" name "/releases/"
                    name "-" version ".tar.bz2"))
              (sha256
               (base32
                "10fnlaf6rm537v3rml1gnd58d42plv2q5cp7svbrysap69npc8wk"))))
    (build-system gnu-build-system)
    (arguments  `(#:tests? #f)) ; There is no "make check" or anything similar
    (inputs `(("zlib" ,zlib)))
    (synopsis "Small SSH server and client")
    (description "Dropbear is a relatively small SSH server and
client.  It runs on a variety of POSIX-based platforms.  Dropbear is
particularly useful for embedded systems, such as wireless routers.")
    (home-page "https://matt.ucc.asn.au/dropbear/dropbear.html")
    (license (license:x11-style "" "See file LICENSE."))))
