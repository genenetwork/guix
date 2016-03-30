;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013 Nikita Karetnikov <nikita@karetnikov.org>
;;; Copyright © 2013 Cyril Roelandt <tipecaml@gmail.com>
;;; Copyright © 2013, 2014, 2015, 2016 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2013, 2014 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2015 Mathieu Lirzin <mthl@openmailbox.org>
;;; Copyright © 2014, 2015 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2014 Eric Bavier <bavier@member.fsf.org>
;;; Copyright © 2015, 2016 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2015 Kyle Meyer <kyle@kyleam.com>
;;; Copyright © 2015 Ricardo Wurmus <rekado@elephly.net>
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

(define-module (gnu packages version-control)
  #:use-module ((guix licenses)
                #:select (asl2.0 bsd-2
                          gpl1+ gpl2 gpl2+ gpl3+ lgpl2.1
                          x11-style))
  #:use-module (guix utils)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system python)
  #:use-module (guix build-system trivial)
  #:use-module (guix build utils)
  #:use-module (gnu packages apr)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages asciidoc)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages cook)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages docbook)
  #:use-module (gnu packages ed)
  #:use-module (gnu packages file)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages groff)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages nano)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages web)
  #:use-module (gnu packages openstack)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages swig)
  #:use-module (gnu packages tcl)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1))

(define-public bazaar
  (package
    (name "bazaar")
    (version "2.7.0")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://launchpad.net/bzr/"
                          (version-major+minor version) "/" version
                          "/+download/bzr-" version ".tar.gz"))
      (sha256
       (base32
        "1cysix5k3wa6y7jjck3ckq3abls4gvz570s0v0hxv805nwki4i8d"))))
    (build-system python-build-system)
    (inputs
     ;; Note: 'tools/packaging/lp-upload-release' and 'tools/weavemerge.sh'
     ;; require Zsh.
     `(("gettext" ,gnu-gettext)))
    (arguments
     `(#:tests? #f ; no test target
       #:python ,python-2   ; Python 3 apparently not yet supported, see
                            ; https://answers.launchpad.net/bzr/+question/229048
       #:phases (alist-cons-after
                 'unpack 'fix-mandir
                 (lambda _
                   (substitute* "setup.py"
                     (("man/man1") "share/man/man1")))
                 %standard-phases)))
    (home-page "https://gnu.org/software/bazaar")
    (synopsis "Version control system supporting both distributed and centralized workflows")
    (description
     "GNU Bazaar is a version control system that allows you to record
changes to project files over time.  It supports both a distributed workflow
as well as the classic centralized workflow.")
    (license gpl2+)))

(define-public git
  ;; Keep in sync with 'git-manpages'!
  (package
   (name "git")
   (version "2.7.3")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://kernel.org/software/scm/git/git-"
                                version ".tar.xz"))
            (sha256
             (base32
              "1di96q86fq3pdn5d5v4fw9vf58gha5i9b3r880mxlh275n8ngi49"))))
   (build-system gnu-build-system)
   (native-inputs
    `(("native-perl" ,perl)
      ("gettext" ,gnu-gettext)))
   (inputs
    `(("curl" ,curl)
      ("expat" ,expat)
      ("openssl" ,openssl)
      ("perl" ,perl)
      ("python" ,python-2) ; CAVEAT: incompatible with python-3 according to INSTALL
      ("zlib" ,zlib)

      ;; For 'git-svn'.
      ("subversion" ,subversion)

      ;; For 'git-send-email'
      ("perl-authen-sasl" ,perl-authen-sasl)
      ("perl-net-smtp-ssl" ,perl-net-smtp-ssl)
      ("perl-io-socket-ssl" ,perl-io-socket-ssl)

      ;; For 'git gui', 'gitk', and 'git citool'.
      ("tcl" ,tcl)
      ("tk" ,tk)))
   (outputs '("out"                               ; the core
              "send-email"                        ; for git-send-email
              "svn"                               ; git-svn
              "gui"))                             ; gitk, git gui
   (arguments
    `(#:make-flags `("V=1"                        ;more verbose compilation

                     ;; By default 'make install' creates hard links for
                     ;; things in 'libexec/git-core', which leads to huge
                     ;; nars; see <http://bugs.gnu.org/21949>.
                     "NO_INSTALL_HARDLINKS=indeed")
      #:test-target "test"
      #:tests? #f ; FIXME: Many tests are failing

      ;; The explicit --with-tcltk forces the build system to hardcode the
      ;; absolute file name to 'wish'.
      #:configure-flags (list (string-append "--with-tcltk="
                                             (assoc-ref %build-inputs "tk")
                                             "/bin/wish8.6")) ; XXX

      #:modules ((srfi srfi-1)
                 ,@%gnu-build-system-modules)
      #:phases
       (alist-cons-after
        'configure 'patch-makefile-shebangs
        (lambda _
          (substitute* "Makefile"
            (("/bin/sh") (which "sh"))
            (("/usr/bin/perl") (which "perl"))
            (("/usr/bin/python") (which "python"))))
        (alist-cons-after
         'install 'install-shell-completion
         (lambda* (#:key outputs #:allow-other-keys)
           (let* ((out         (assoc-ref outputs "out"))
                  (completions (string-append out "/etc/bash_completion.d")))
             ;; TODO: Install the tcsh and zsh completions in the right place.
             (mkdir-p completions)
             (copy-file "contrib/completion/git-completion.bash"
                        (string-append completions "/git"))
             #t))
         (alist-cons-after
          'install 'split
          (lambda* (#:key inputs outputs #:allow-other-keys)
            ;; Split the binaries to the various outputs.
            (let* ((out      (assoc-ref outputs "out"))
                   (se       (assoc-ref outputs "send-email"))
                   (svn      (assoc-ref outputs "svn"))
                   (gui      (assoc-ref outputs "gui"))
                   (gitk     (string-append out "/bin/gitk"))
                   (gitk*    (string-append gui "/bin/gitk"))
                   (git-gui  (string-append out "/libexec/git-core/git-gui"))
                   (git-gui* (string-append gui "/libexec/git-core/git-gui"))
                   (git-cit  (string-append out "/libexec/git-core/git-citool"))
                   (git-cit* (string-append gui "/libexec/git-core/git-citool"))
                   (git-se   (string-append out "/libexec/git-core/git-send-email"))
                   (git-se*  (string-append se  "/libexec/git-core/git-send-email"))
                   (git-svn  (string-append out "/libexec/git-core/git-svn"))
                   (git-svn* (string-append svn "/libexec/git-core/git-svn"))
                   (git-sm   (string-append out
                                            "/libexec/git-core/git-submodule")))
              (mkdir-p (string-append gui "/bin"))
              (mkdir-p (string-append gui "/libexec/git-core"))
              (mkdir-p (string-append se  "/libexec/git-core"))
              (mkdir-p (string-append svn "/libexec/git-core"))

              (for-each (lambda (old new)
                          (copy-file old new)
                          (delete-file old)
                          (chmod new #o555))
                        (list gitk git-gui git-cit git-se git-svn)
                        (list gitk* git-gui* git-cit* git-se* git-svn*))

              ;; Tell 'git-svn' where Subversion is.
              (wrap-program git-svn*
                `("PATH" ":" prefix
                  (,(string-append (assoc-ref inputs "subversion")
                                   "/bin")))
                `("PERL5LIB" ":" prefix
                  (,(string-append (assoc-ref inputs "subversion")
                                   "/lib/perl5/site_perl")))

                ;; XXX: The .so for SVN/Core.pm lacks a RUNPATH, so
                ;; help it find 'libsvn_client-1.so'.
                `("LD_LIBRARY_PATH" ":" prefix
                  (,(string-append (assoc-ref inputs "subversion")
                                   "/lib"))))

              ;; Tell 'git-send-email' where perl modules are.
              (wrap-program git-se*
                `("PERL5LIB" ":" prefix
                  ,(map (lambda (o) (string-append o "/lib/perl5/site_perl"))
                        (list
                         ,@(transitive-input-references
                            'inputs
                            (map (lambda (l)
                                   (assoc l (inputs)))
                                 '("perl-authen-sasl"
                                   "perl-net-smtp-ssl"
                                   "perl-io-socket-ssl")))))))

              ;; Tell 'git-submodule' where Perl is.
              (wrap-program git-sm
                `("PATH" ":" prefix
                  (,(string-append (assoc-ref inputs "perl")
                                   "/bin"))))

              ;; Tell 'git' to look for core programs in the user's profile.
              ;; This allows user to install other outputs of this package and
              ;; have them transparently taken into account.  There's a
              ;; 'GIT_EXEC_PATH' environment variable, but it's supposed to
              ;; specify a single directory, not a search path.
              (wrap-program (string-append out "/bin/git")
                `("PATH" ":" prefix
                  ("$HOME/.guix-profile/libexec/git-core")))))
          %standard-phases)))))

   (native-search-paths
    ;; For HTTPS access, Git needs a single-file certificate bundle, specified
    ;; with $GIT_SSL_CAINFO.
    ;; FIXME: This variable designates a single file; it is not a search path.
    (list (search-path-specification
           (variable "GIT_SSL_CAINFO")
           (files '("etc/ssl/certs/ca-certificates.crt")))))

   (synopsis "Distributed version control system")
   (description
    "Git is a free distributed version control system designed to handle
everything from small to very large projects with speed and efficiency.")
   (license gpl2)
   (home-page "http://git-scm.com/")))

(define-public git-manpages
  ;; Keep in sync with 'git'!

  ;; Granted, we could build the man pages from the 'git' package itself,
  ;; which contains the real source.  However, it would add a dependency on a
  ;; full XML tool chain, and building it actually takes ages.  So we use this
  ;; lazy approach.
  (package
    (name "git-manpages")
    (version (package-version git))
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://kernel.org/software/scm/git/git-manpages-"
                    version ".tar.xz"))
              (sha256
               (base32
                "0va9j0q9h44jqih38h4cmhvbmjppqq7zbiq70220m7hsqqkq824z"))))
    (build-system trivial-build-system)
    (arguments
     '(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))

         (let* ((xz  (assoc-ref %build-inputs "xz"))
                (tar (assoc-ref %build-inputs "tar"))
                (out (assoc-ref %outputs "out"))
                (man (string-append out "/share/man")))
           (setenv "PATH" (string-append tar "/bin:" xz "/bin"))

           (mkdir-p man)
           (with-directory-excursion man
             (zero? (system* "tar" "xvf"
                             (assoc-ref %build-inputs "source"))))))))

    (native-inputs `(("tar" ,tar)
                     ("xz" ,xz)))
    (home-page (package-home-page git))
    (license (package-license git))
    (synopsis "Man pages of the Git version control system")
    (description
     "This package provides the man pages of the Git version control system.
This is the documentation displayed when using the '--help' option of a 'git'
command.")))

(define-public libgit2
  (package
    (name "libgit2")
    (version "0.24.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/libgit2/libgit2/"
                                  "archive/v" version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1c5jx0pcpz83x7s36jimfz5bj0vy7vwpchq9p4sgdqxy8gwr6rhw"))))
    (build-system cmake-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-hardcoded-paths
           (lambda _
             (substitute* "tests/repo/init.c"
               (("#!/bin/sh") (string-append "#!" (which "sh"))))
             (substitute* "tests/clar/fs.h"
               (("/bin/cp") (which "cp"))
               (("/bin/rm") (which "rm")))
             #t))
         ;; Run checks more verbosely.
         (replace 'check
           (lambda _ (zero? (system* "./libgit2_clar" "-v" "-Q")))))))
    (inputs
     `(("libssh2" ,libssh2)
       ("libcurl" ,curl)
       ("python" ,python-wrapper)
       ("openssl" ,openssl)))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (home-page "http://libgit2.github.com/")
    (synopsis "Library providing Git core methods")
    (description
     "Libgit2 is a portable, pure C implementation of the Git core methods
provided as a re-entrant linkable library with a solid API, allowing you to
write native speed custom Git applications in any language with bindings.")
    ;; GPLv2 with linking exception
    (license gpl2)))

(define-public cgit
  (package
    (name "cgit")
    (version "0.12")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://git.zx2c4.com/cgit/snapshot/cgit-"
                    version ".tar.xz"))
              (sha256
               (base32
                "1dx54hgfyabmg9nm5qp6d01f54nlbqbbdwhwl0llb9imjf237qif"))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f ; XXX: fail to build the in-source git.
       #:test-target "test"
       #:make-flags '("CC=gcc" "SHELL_PATH=sh")
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'unpack-git
           (lambda* (#:key inputs #:allow-other-keys)
             ;; Unpack the source of git into the 'git' directory.
             (zero? (system*
                     "tar" "--strip-components=1" "-C" "git" "-xf"
                     (assoc-ref inputs "git:src")))))
         (delete 'configure) ; no configure script
         (add-after 'build 'build-man
           (lambda* (#:key make-flags #:allow-other-keys)
             (zero? (apply system* `("make" ,@make-flags "doc-man")))))
         (replace 'install
           (lambda* (#:key make-flags outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (and (zero? (apply system*
                                  `("make" ,@make-flags
                                    ,(string-append "prefix=" out)
                                    ,(string-append
                                      "CGIT_SCRIPT_PATH=" out "/share/cgit")
                                    "install" "install-man")))
                    ;; Move the platform-dependent 'cgit.cgi' into lib
                    ;; to get it stripped.
                    (rename-file (string-append out "/share/cgit/cgit.cgi")
                                 (string-append out "/lib/cgit/cgit.cgi"))
                    #t)))))))
    (native-inputs
     ;; For building manpage.
     `(("asciidoc" ,asciidoc)
       ("docbook-xml" ,docbook-xml)
       ("docbook-xsl" ,docbook-xsl)
       ("xmllint" ,libxml2)
       ("xsltprot" ,libxslt)))
    (inputs
     `(("git:src" ,(package-source git))
       ("openssl" ,openssl)
       ("zlib" ,zlib)))
    (home-page "https://git.zx2c4.com/cgit/")
    (synopsis "Web frontend for git repositories")
    (description
     "CGit is an attempt to create a fast web interface for the Git SCM, using
a built-in cache to decrease server I/O pressure.")
    (license gpl2)))

(define-public shflags
  (package
    (name "shflags")
    (version "1.2.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/kward/shflags/archive/v"
                                  version ".tar.gz"))
              (sha256
               (base32
                "0zxw12haylaq60a335xlqcs4afw2zrgwqymmpw0m21r51w6irdmr"))))
    (build-system trivial-build-system)
    (native-inputs `(("tar" ,tar)
                     ("gzip" ,gzip)))
    (arguments
     `(#:modules ((guix build utils))
       #:builder (begin
                   (use-modules (guix build utils))
                   (let* ((source (assoc-ref %build-inputs "source"))
                          (tar    (assoc-ref %build-inputs "tar"))
                          (gzip   (assoc-ref %build-inputs "gzip"))
                          (output (assoc-ref %outputs "out"))
                          (srcdir (string-append output "/src")))
                     (begin
                       (setenv "PATH" (string-append gzip "/bin"))
                       (system* (string-append tar "/bin/tar") "xzf"
                                source)
                       (chdir ,(string-append name "-" version))
                       (mkdir-p srcdir)
                       (copy-file "src/shflags"
                                  (string-append srcdir "/shflags"))
                       #t)))))
    (home-page "https://github.com/kward/shflags")
    (synopsis "Command-line flags library for shell scripts")
    (description
     "Shell Flags (shFlags) is a library written to greatly simplify the
handling of command-line flags in Bourne based Unix shell scripts (bash, dash,
ksh, sh, zsh).  Most shell scripts use getopt for flags processing, but the
different versions of getopt on various OSes make writing portable shell
scripts difficult.  shFlags instead provides an API that doesn't change across
shell and OS versions so the script writer can be confident that the script
will work.")
    (license lgpl2.1)))

(define-public git-flow
  (package
    (name "git-flow")
    ;; This version has not be officially released yet, so we build it
    ;; directly from the git repository.
    (version "0.4.2-pre")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/nvie/gitflow/")
                    (commit "15aab26")))
              (sha256
               (base32
                "01fs97q76fdfnvmrh2cyjhywcs3pykf1dg58sy0frflnsdzs6prx"))))
    (build-system gnu-build-system)
    (inputs `(("shflags" ,shflags)))
    (arguments
     '(#:tests? #f                    ; no tests
       #:make-flags (list (string-append "prefix="
                                         (assoc-ref %outputs "out")))
       #:phases (alist-cons-after
                 'unpack 'reset-shFlags-link
                 (lambda* (#:key inputs #:allow-other-keys)
                   ;; The link points to a file in the shFlags submodule.
                   ;; Redirect it to point to our system shFlags.
                   (let ((shflags (assoc-ref inputs "shflags")))
                     (begin
                       (delete-file "gitflow-shFlags")
                       (symlink (string-append shflags "/src/shflags")
                                "gitflow-shFlags"))))
                 (alist-delete
                  'configure
                  (alist-delete 'build %standard-phases)))))
    (home-page "http://nvie.com/posts/a-successful-git-branching-model/")
    (synopsis "Git extensions for Vincent Driessen's branching model")
    (description
     "Vincent Driessen's branching model is a git branching and release
management strategy that helps developers keep track of features, hotfixes,
and releases in bigger software projects.  The git-flow library of git
subcommands helps automate some parts of the flow to make working with it a
lot easier.")
    (license bsd-2)))

(define-public git-test-sequence
  (let ((commit "48e5a2f"))
    (package
      (name "git-test-sequence")
      (version (string-append "20140312." commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      ;; There are many other scripts in this directory; we
                      ;; are interested in just one for this package.
                      (url "https://github.com/dustin/bindir")
                      (commit commit)))
                (sha256
                 (base32
                  "1dcq0y16yznbv4k9h8gg90kv1gkn8r8dbvl4m2rpfd7q5nqhn617"))))
      (build-system trivial-build-system)
      (arguments
       `(#:modules ((guix build utils))
         #:builder (begin
                     (use-modules (guix build utils))
                     (let* ((source (assoc-ref %build-inputs "source"))
                            (output (assoc-ref %outputs "out"))
                            (bindir (string-append output "/bin"))
                            (script "git-test-sequence"))
                       (install-file (string-append source "/" script)
                                     bindir)
                       #t))))
      (home-page "http://dustin.sallings.org/2010/03/28/git-test-sequence.html")
      (synopsis "Run a command over a sequence of commits")
      (description
       "git-test-sequence is similar to an automated git bisect except it’s
linear.  It will test every change between two points in the DAG.  It will
also walk each side of a merge and test those changes individually.")
      (license (x11-style "file://LICENSE")))))

(define-public gitolite
  (package
    (name "gitolite")
    (version "3.6.5")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/sitaramc/gitolite/archive/v"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "0xpqg04gyr4dhdhxx5lbk61lwwd5ml32530bigg2qy663icngwqm"))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f ; no tests
       #:phases (modify-phases %standard-phases
                  (delete 'configure)
                  (delete 'build)
                  (add-before 'install 'patch-scripts
                    (lambda* (#:key inputs #:allow-other-keys)
                      (let ((perl (string-append (assoc-ref inputs "perl")
                                                 "/bin/perl")))
                        ;; This seems to take care of every shell script that
                        ;; invokes Perl.
                        (substitute* (find-files "." ".*")
                          ((" perl -")
                           (string-append " " perl " -"))))))
                  (replace 'install
                    (lambda* (#:key outputs #:allow-other-keys)
                      (let* ((output (assoc-ref outputs "out"))
                             (sharedir (string-append output "/share/gitolite"))
                             (bindir (string-append output "/bin")))
                        (mkdir-p sharedir)
                        (mkdir-p bindir)
                        (system* "./install" "-to" sharedir)
                        ;; Create symlinks for executable scripts in /bin.
                        (for-each (lambda (script)
                                    (symlink (string-append sharedir "/" script)
                                             (string-append bindir "/" script)))
                                  '("gitolite" "gitolite-shell"))
                        #t))))))
    (inputs
     `(("perl" ,perl)))
    ;; git and openssh are propagated because trying to patch the source via
    ;; regexp matching is too brittle and prone to false positives.
    (propagated-inputs
     `(("git" ,git)
       ("openssh" ,openssh)))
    (home-page "http://gitolite.com")
    (synopsis "Git access control layer")
    (description
     "Gitolite is an access control layer on top of Git, providing fine access
control to Git repositories.")
    (license gpl2)))

(define-public mercurial
  (package
    (name "mercurial")
    (version "3.7.2")
    (source (origin
             (method url-fetch)
             (uri (string-append "https://www.mercurial-scm.org/"
                                 "release/mercurial-" version ".tar.gz"))
             (sha256
              (base32
               "0ykdvj7k4yxiwbfk0gnrq2flmdlf2cracsvqn3vr7nxhda6l7aav"))))
    (build-system python-build-system)
    (arguments
     `(;; Restrict to Python 2, as Python 3 would require
       ;; the argument --c2to3.
       #:python ,python-2
       ;; FIXME: Disabled tests because they require the nose unit
       ;; testing framework: https://nose.readthedocs.org/en/latest/ .
       #:tests? #f))
    (home-page "https://www.mercurial-scm.org/")
    (synopsis "Decentralized version control system")
    (description
     "Mercurial is a free, distributed source control management tool.
It efficiently handles projects of any size
and offers an easy and intuitive interface.")
    (license gpl2+)))

(define-public neon
  (package
    (name "neon")
    (version "0.30.1")
    (source (origin
             (method url-fetch)
             (uri (string-append "http://www.webdav.org/neon/neon-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "1pawhk02x728xn396a1kcivy9gqm94srmgad6ymr9l0qvk02dih0"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("perl" ,perl)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("libxml2" ,libxml2)
       ("openssl" ,openssl)
       ("zlib" ,zlib)))
    (arguments
     `(;; FIXME: Add tests once reverse address lookup is fixed in glibc, see
       ;; https://sourceware.org/bugzilla/show_bug.cgi?id=16475
       #:tests? #f
       #:configure-flags '("--enable-shared"
                           ;; requires libgnutils-config, deprecated
                           ;; in gnutls 2.8.
                           ; "--with-ssl=gnutls")))
                           "--with-ssl=openssl")))
    (home-page "http://www.webdav.org/neon/")
    (synopsis "HTTP and WebDAV client library")
    (description "Neon is an HTTP and WebDAV client library, with a
C interface.  Features:
High-level wrappers for common HTTP and WebDAV operations (GET, MOVE,
DELETE, etc.);
low-level interface to the HTTP request/response engine, allowing the use
of arbitrary HTTP methods, headers, etc.;
authentication support including Basic and Digest support, along with
GSSAPI-based Negotiate on Unix, and SSPI-based Negotiate/NTLM on Win32;
SSL/TLS support using OpenSSL or GnuTLS, exposing an abstraction layer for
verifying server certificates, handling client certificates, and examining
certificate properties, smartcard-based client certificates are also
supported via a PKCS#11 wrapper interface;
abstract interface to parsing XML using libxml2 or expat, and wrappers for
simplifying handling XML HTTP response bodies;
WebDAV metadata support, wrappers for PROPFIND and PROPPATCH to simplify
property manipulation.")
    (license gpl2+))) ; for documentation and tests; source under lgpl2.0+

(define-public subversion
  (package
    (name "subversion")
    (version "1.8.15")
    (source (origin
             (method url-fetch)
             (uri (string-append "http://archive.apache.org/dist/subversion/"
                                 "subversion-" version ".tar.bz2"))
             (sha256
              (base32
               "0b68rjy1sjd66nqcswrm1bhda3vk2ngkgs6drcanmzbcd3vs366g"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (alist-cons-after
                 'configure 'patch-libtool-wrapper-ls
                 (lambda* (#:key inputs #:allow-other-keys)
                   ;; This substitution allows tests svnauthz_tests and
                   ;; svnlook_tests to pass.  These tests execute svnauthz and
                   ;; svnlook through their libtool wrapper scripts from svn
                   ;; hooks, whose empty environments cause "ls: command not
                   ;; found" errors.  It would be nice if this fix ultimately
                   ;; made its way into libtool.
                   (let ((coreutils (assoc-ref inputs "coreutils")))
                     (substitute* "libtool"
                       (("\\\\`ls") (string-append "\\`" coreutils "/bin/ls")))))
                 (alist-cons-after
                  'install 'install-perl-bindings
                  (lambda* (#:key outputs #:allow-other-keys)
                    ;; Follow the instructions from
                    ;; 'subversion/bindings/swig/INSTALL'.
                    (let ((out (assoc-ref outputs "out")))
                      (and (zero? (system* "make" "swig-pl-lib"))
                           ;; FIXME: Test failures.
                           ;; (zero? (system* "make" "check-swig-pl"))
                           (zero? (system* "make" "install-swig-pl-lib"))

                           ;; Set the right installation prefix.
                           (with-directory-excursion
                               "subversion/bindings/swig/perl/native"
                             (and (zero?
                                   (system* "perl" "Makefile.PL"
                                            (string-append "PREFIX=" out)))
                                  (zero?
                                   (system* "make" "install"
                                            (string-append "OTHERLDFLAGS="
                                                           "-Wl,-rpath="
                                                           out "/lib"))))))))
                  %standard-phases))))
    (native-inputs
      `(("pkg-config" ,pkg-config)
        ;; For the Perl bindings.
        ("swig" ,swig)))
    (inputs
      `(("apr" ,apr)
        ("apr-util" ,apr-util)
        ("serf" ,serf)
        ("perl" ,perl)
        ("python" ,python-2) ; incompatible with Python 3 (print syntax)
        ("sqlite" ,sqlite)
        ("zlib" ,zlib)))
    (home-page "http://subversion.apache.org/")
    (synopsis "Revision control system")
    (description
     "Subversion exists to be universally recognized and adopted as a
centralized version control system characterized by its
reliability as a safe haven for valuable data; the simplicity of its model and
usage; and its ability to support the needs of a wide variety of users and
projects, from individuals to large-scale enterprise operations.")
    (license asl2.0)))

(define-public rcs
  (package
    (name "rcs")
    (version "5.9.4")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnu/rcs/rcs-"
                                 version ".tar.xz"))
             (sha256
              (base32
               "1zsx7bb0rgvvvisiy4zlixf56ay8wbd9qqqcp1a1g0m1gl6mlg86"))))
    (build-system gnu-build-system)
    (native-inputs `(("ed" ,ed)))
    (home-page "http://www.gnu.org/software/rcs/")
    (synopsis "Per-file local revision control system")
    (description
     "RCS is the original Revision Control System.  It works on a
file-by-file basis, in contrast to subsequent version control systems such as
CVS, Subversion, and Git.  This can make it suitable for system
administration files, for example, which are often inherently local to one
machine.")
    (license gpl3+)))

(define-public cvs
  (package
    (name "cvs")
    (version "1.12.13")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "http://ftp.gnu.org/non-gnu/cvs/source/feature/"
                   version "/cvs-" version ".tar.bz2"))
             (sha256
              (base32
               "0pjir8cwn0087mxszzbsi1gyfc6373vif96cw4q3m1x6p49kd1bq"))))
    (build-system gnu-build-system)
    (arguments
     ;; XXX: The test suite looks flawed, and the package is obsolete anyway.
     '(#:tests? #f
       #:configure-flags (list "--with-external-zlib")))
    (inputs `(("zlib" ,zlib)
              ("nano" ,nano)))                    ; the default editor
    (home-page "http://cvs.nongnu.org")
    (synopsis "Historical centralized version control system")
    (description
     "CVS is a version control system, an important component of Source
Configuration Management (SCM).  Using it, you can record the history of
sources files, and documents.  It fills a similar role to the free software
RCS, PRCS, and Aegis packages.")
    (license gpl1+)))

(define-public cvs-fast-export
  (package
    (name "cvs-fast-export")
    (version "1.33")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://www.catb.org/~esr/"
                                  name "/" name "-" version ".tar.gz"))
              (sha256
               (base32
                "1c3s4nacbwlaaccx1fr7hf72kxxrzy49y2rdz5hhqbk8r29vm8w1"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases (modify-phases %standard-phases (delete 'configure))
       #:make-flags
       (list "CC=gcc" (string-append "prefix?=" (assoc-ref %outputs "out")))))
    (inputs `(("git" ,git)))
    (native-inputs `(("asciidoc"    ,asciidoc)
                     ("docbook-xml" ,docbook-xml)
                     ("docbook-xsl" ,docbook-xsl)
                     ("xmllint"     ,libxml2)
                     ("xsltproc"    ,libxslt)
                     ;; These are needed for the tests.
                     ("cvs"    ,cvs)
                     ("python" ,python-2)
                     ("rcs"    ,rcs)))
    (home-page "http://www.catb.org/esr/cvs-fast-export/")
    (synopsis "Export an RCS or CVS history as a fast-import stream")
    (description "This program analyzes a collection of RCS files in a CVS
repository (or outside of one) and, when possible, emits an equivalent history
in the form of a fast-import stream.  Not all possible histories can be
rendered this way; the program tries to emit useful warnings when it can't.

The program can also produce a visualization of the resulting commit directed
acyclic graph (DAG) in the input format of @uref{http://www.graphviz.org,
Graphviz}.  The package also includes @command{cvssync}, a tool for mirroring
masters from remote CVS hosts.")
    (license gpl2+)))

(define-public vc-dwim
  (package
    (name "vc-dwim")
    (version "1.7")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnu/vc-dwim/vc-dwim-"
                                 version ".tar.xz"))
             (sha256
              (base32
               "094pjwshvazlgagc254in2xvrp93vhcj0kb5ms17qs7sch99x9z2"))))
    (build-system gnu-build-system)
    (inputs `(("perl" ,perl)
              ("inetutils" ,inetutils)     ; for `hostname', used in the tests
              ("emacs" ,emacs-no-x)))      ; for `ctags'
    (home-page "http://www.gnu.org/software/vc-dwim/")
    (synopsis "Version-control-agnostic ChangeLog diff and commit tool")
    (description
     "The vc-dwim package contains two tools, \"vc-dwim\" and \"vc-chlog\".
vc-dwim is a tool that simplifies the task of maintaining a ChangeLog and
using version control at the same time, for example by printing a reminder
when a file change has been described in the ChangeLog but the file has not
been added to the VC.  vc-chlog scans changed files and generates
standards-compliant ChangeLog entries based on the changes that it detects.")
    (license gpl3+)))

(define-public diffstat
  (package
    (name "diffstat")
    (version "1.58")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "ftp://invisible-island.net/diffstat/diffstat-"
                    version ".tgz"))
              (sha256
               (base32
                "14rpf5c05ff30f6vn6pn6pzy0k4g4is5im656ahsxff3k58i7mgs"))))
    (build-system gnu-build-system)
    (home-page "http://invisible-island.net/diffstat/")
    (synopsis "Make histograms from the output of 'diff'")
    (description
     "Diffstat reads the output of 'diff' and displays a histogram of the
insertions, deletions, and modifications per-file.  It is useful for reviewing
large, complex patch files.")
    (license (x11-style "file://COPYING"))))

(define-public cssc
  (package
    (name "cssc")
    (version "1.3.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnu/" name "/CSSC-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "0bkw6fjh20ppvn54smv05461lm1vcwvn02avx941c4acafmkl1cm"))
              (patches (list (search-patch "cssc-gets-undeclared.patch")
                             (search-patch "cssc-missing-include.patch")))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases (alist-cons-before
                 'check 'precheck
                 (lambda _
                   (begin
                     (substitute* "tests/common/test-common"
                       (("/bin/pwd") (which "pwd")))

                     (substitute* "tests/prt/all-512.sh"
                       (("/bin/sh") (which "sh")))

                     ;; XXX: This test has no hope of passing until there is a "nogroup"
                     ;; entry (or at least some group to which the guix builder does
                     ;; not belong) in the /etc/group file of the build environment.
                     ;; Currently we do not have such a group.  Disable this test for now.
                     (substitute* "tests/Makefile"
                       (("test-delta ") ""))))
                 %standard-phases)))
    ;; These are needed for the tests
    (native-inputs `(("git" ,git)
                     ("cvs" ,cvs)))
    (home-page "http://www.gnu.org/software/cssc/")
    (synopsis "File-based version control like SCCS")
    (description  "GNU CSSC provides a replacement for the legacy Unix source
code control system SCCS.  This allows old code still under that system to be
accessed and migrated on modern systems.")
    (license gpl3+)))

;; This package can unfortunately work only in -TEST mode, since Aegis
;; requires that it is installed setuid root.
(define-public aegis
  (package
    (name "aegis")
    (version "4.24")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/aegis/aegis-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "18s86ssarfmc4l17gbpzybca29m5wa37cbaimdji8czlcry3mcjl"))
            (patches (list (search-patch "aegis-perl-tempdir1.patch")
                           (search-patch "aegis-perl-tempdir2.patch")
                           (search-patch "aegis-test-fixup-1.patch")
                           (search-patch "aegis-test-fixup-2.patch")
                           (search-patch "aegis-constness-error.patch")))))
    (build-system gnu-build-system)
    (inputs
     `(("e2fsprogs" ,e2fsprogs)
       ("curl" ,curl)
       ("file" ,file)
       ("libxml2" ,libxml2)
       ("zlib" ,zlib)
       ("gettext" ,gnu-gettext)))
    (native-inputs
     `(("bison" ,bison)
       ("groff" ,groff)
       ("perl" ,perl)
       ;; Various tests require the following:
       ("cvs" ,cvs)
       ("flex" ,flex)
       ("cook" ,cook)
       ("subversion" ,subversion)
       ("rcs" ,rcs)
       ("ed" ,ed)))
    (arguments
     `(#:configure-flags (list "--with-no-aegis-configured"
                               "--sharedstatedir=/var/com/aegis")
       #:parallel-build? #f ; There are some nasty racy rules in the Makefile.
       #:phases
        (alist-cons-before
         'configure 'pre-conf
         (lambda _
             (substitute* (append '("configure"
                                    "etc/check-tar-gz.sh"
                                    "etc/patches.sh"
                                    "etc/test.sh"
                                    "script/aexver.in"
                                    "script/aebisect.in"
                                    "script/aeintegratq.in"
                                    "script/tkaegis.in"
                                    "script/test_funcs.in"
                                    "web/eg_oss_templ.sh"
                                    "web/webiface.html"
                                    "libaegis/getpw_cache.cc")
                                  (find-files "test" "\\.sh"))
               (("/bin/sh") (which "sh")))
             (setenv "SH" (which "sh")))
         (alist-replace
          'check
          (lambda _
            (let ((home (string-append (getcwd) "/my-new-home")))
              ;; Some tests need to write to $HOME.
              (mkdir home)
              (setenv "HOME" home)

              ;; This test assumes that  flex has been symlinked to "lex".
              (substitute* "test/00/t0011a.sh"
                (("type lex")  "type flex"))

              ;; The author decided to call the check rule "sure".
              (zero? (system* "make" "sure"))))
         %standard-phases))))
    (home-page "http://aegis.sourceforge.net")
    (synopsis "Project change supervisor")
    (description "Aegis is a project change supervisor, and performs some of
the Software Configuration Management needed in a CASE environment.  Aegis
provides a framework within which a team of developers may work on many
changes to a program independently, and Aegis coordinates integrating these
changes back into the master source of the program, with as little disruption
as possible.  Resolution of contention for source files, a major headache for
any project with more than one developer, is one of Aegis's major functions.")
    (license gpl3+)))

(define-public tig
  (package
    (name "tig")
    (version "2.1.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://jonas.nitro.dk/tig/releases/tig-"
                    version ".tar.gz"))
              (sha256
               (base32
                "0bw5wivswwh7vx897q8xc2cqgkqhdzk8gh6fnav2kf34sngigiah"))))
    (build-system gnu-build-system)
    (inputs
     `(("ncurses" ,ncurses)))
    (arguments
     `(#:tests? #f)) ; tests require access to /dev/tty
     ;;`(#:test-target "test"))
    (home-page "http://jonas.nitro.dk/tig/")
    (synopsis "Ncurses-based text user interface for Git")
    (description
     "Tig is an ncurses text user interface for Git, primarily intended as
a history browser.  It can also stage hunks for commit, or colorize the
output of the 'git' command.")
    (license gpl2+)))

(define-public findnewest
  (package
    (name "findnewest")
    (version "0.3")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/0-wiz-0/findnewest/archive/findnewest-"
                    version ".tar.gz"))
              (sha256
               (base32
                "1ydis4y0amkgfr4y60sn076f1l41ya2kn89kfd9fqf44f9ccgb5r"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (modify-phases %standard-phases
                  (add-before 'configure 'bootstrap
                    (lambda _
                      (zero? (system* "autoreconf" "-vfi")))))))
    (native-inputs `(("autoconf" ,autoconf)
                     ("automake" ,automake)))
    (home-page "https://github.com/0-wiz-0/findnewest/releases")
    (synopsis "Print the modification time of the latest file")
    (description
     "Recursively find the newest file in a file tree and print its
modification time.")
    (license bsd-2)))

(define-public myrepos
  (package
    (name "myrepos")
    (version "1.20160123")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/joeyh/myrepos/archive/"
             version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1723cg5haplz2w9dwdzp6ds1ip33cx3awmj4wnb0h4yq171v5lqk"))))
    (build-system gnu-build-system)
    (inputs
     `(("perl" ,perl)))
    (arguments
     `(#:test-target "test"
       #:phases (alist-delete 'configure %standard-phases)
       #:make-flags (list (string-append "PREFIX=" %output))))
    (home-page "http://myrepos.branchable.com/")
    (synopsis "Multiple repository management tool")
    (description
     "Myrepos provides the @code{mr} command, which maps an operation (e.g.,
fetching updates) over a collection of version control repositories.  It
supports a large number of version control systems: Git, Subversion,
Mercurial, Bazaar, Darcs, CVS, Fossil, and Veracity.")
    (license gpl2+)))

(define-public git-annex-remote-hubic
  (package
    (name "git-annex-remote-hubic")
    (version "0.3.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/Schnouki/" name "/archive/v"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "196g3jkaybjx11nbr51n0cjps3wjzb145ab76y717diqvvxp5v4r"))))
    (build-system python-build-system)
    (native-inputs
     `(("python-setuptools" ,python-setuptools)
       ;; for the tests
       ("python-six" ,python-six)))
    (propagated-inputs
     `(("python-dateutil" ,python-dateutil-2)
       ("python-futures" ,python-futures)
       ("python-rauth" ,python-rauth)
       ("python-swiftclient" ,python-swiftclient)))
    (home-page "https://github.com/Schnouki/git-annex-remote-hubic/")
    (synopsis "Use hubic as a git-annex remote")
    (description
     "This package allows you to use your hubic account as a \"special
repository\" with git-annex.")
    (license gpl3+)))
