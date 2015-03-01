;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013, 2015 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2014 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2014, 2015 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2015 Paul van der Walt <paul@denknerd.org>
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

(define-module (gnu packages pdf)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system cmake)
  #:use-module (gnu packages)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages backup)
  #:use-module (gnu packages lesstif)
  #:use-module (gnu packages image)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages openssl)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages perl)
  #:use-module (srfi srfi-1))

(define-public poppler
  (package
   (name "poppler")
   (version "0.28.1")
   (source (origin
            (method url-fetch)
            (uri (string-append "http://poppler.freedesktop.org/poppler-"
                                version ".tar.xz"))
            (sha256 (base32
                     "01pxjdbhvpxf00ncf8d9wxc8gkcqcxz59lwrpa151ah988inxkrc"))))
   (build-system gnu-build-system)
   ;; FIXME: more dependencies could  be added
   ;;  cairo output:       no (requires cairo >= 1.10.0)
   ;;  qt4 wrapper:        no
   ;;    introspection:    no
   ;;  use gtk-doc:        no
   ;;  use libcurl:        no
   (inputs `(("fontconfig" ,fontconfig)
             ("freetype" ,freetype)
             ("libjpeg-8" ,libjpeg-8)
             ("libpng" ,libpng)
             ("libtiff" ,libtiff)
             ("lcms" ,lcms)
             ("openjpeg-1" ,openjpeg-1)
             ("zlib" ,zlib)

             ;; To build poppler-glib (as needed by Evince), we need Cairo and
             ;; GLib.  But of course, that Cairo must not depend on Poppler.
             ("cairo" ,(package (inherit cairo)
                         (inputs (alist-delete "poppler"
                                               (package-inputs cairo)))))
             ("glib" ,glib)))
   (native-inputs
      `(("pkg-config" ,pkg-config)
        ("glib" ,glib "bin")))                    ; glib-mkenums, etc.
   (arguments
    `(#:tests? #f ; no test data provided with the tarball
      #:configure-flags
      '("--enable-libopenjpeg"
        "--enable-xpdf-headers" ; to install header files
        "--enable-zlib")
      #:phases
      (alist-cons-before
       'configure 'setenv
       (lambda _
         (setenv "CPATH"
                 (string-append (assoc-ref %build-inputs "openjpeg-1")
                                "/include/openjpeg-1.5"
                                ":" (or (getenv "CPATH") ""))))
        %standard-phases)))
   (synopsis "PDF rendering library")
   (description
    "Poppler is a PDF rendering library based on the xpdf-3.0 code base.")
   (license license:gpl2+)
   (home-page "http://poppler.freedesktop.org/")))

(define-public xpdf
  (package
   (name "xpdf")
   (version "3.04")
   (source (origin
            (method url-fetch)
            (uri (string-append "ftp://ftp.foolabs.com/pub/xpdf/xpdf-"
                                version ".tar.gz"))
            (sha256 (base32
                     "1rbp54mr3z2x3a3a1qmz8byzygzi223vckfam9ib5g1sfds0qf8i"))))
   (build-system gnu-build-system)
   (inputs `(("freetype" ,freetype)
             ("gs-fonts" ,gs-fonts)
             ("lesstif" ,lesstif)
             ("libpaper" ,libpaper)
             ("libx11" ,libx11)
             ("libxext" ,libxext)
             ("libxp" ,libxp)
             ("libxpm" ,libxpm)
             ("libxt" ,libxt)
             ("libpng" ,libpng)
             ("zlib" ,zlib)))
   (arguments
    `(#:tests? #f ; there is no check target
      #:parallel-build? #f            ; build fails randomly on 8-way machines
      #:phases
       (alist-replace
        'install
        (lambda* (#:key outputs inputs #:allow-other-keys #:rest args)
         (let* ((install (assoc-ref %standard-phases 'install))
                (out (assoc-ref outputs "out"))
                (xpdfrc (string-append out "/etc/xpdfrc"))
                (gs-fonts (assoc-ref inputs "gs-fonts")))
               (apply install args)
               (substitute* xpdfrc
                (("/usr/local/share/ghostscript/fonts")
                 (string-append gs-fonts "/share/fonts/type1/ghostscript"))
                (("#fontFile") "fontFile"))))
        %standard-phases)))
   (synopsis "Viewer for PDF files based on the Motif toolkit")
   (description
    "Xpdf is a viewer for Portable Document Format (PDF) files")
   (license license:gpl3) ; or gpl2, but not gpl2+
   (home-page "http://www.foolabs.com/xpdf/")))

(define-public zathura-pdf-poppler
  (package
    (name "zathura-pdf-poppler")
    (version "0.2.5")
    (source (origin
              (method url-fetch)
              (uri
               (string-append "https://pwmt.org/projects/zathura-pdf-poppler/download/zathura-pdf-poppler-"
                              version ".tar.gz"))
              (sha256
               (base32
                "1b0chsds8iwjm4g629p6a67nb6wgra65pw2vvngd7g35dmcjgcv0"))))
    (native-inputs `(("pkg-config" ,pkg-config)))
    (propagated-inputs `(("girara" ,girara)))
    (inputs
     `(("poppler" ,poppler)
       ("gtk+" ,gtk+)
       ("zathura" ,zathura)
       ("cairo" ,cairo)))
    (build-system gnu-build-system)
    (arguments
     `(#:make-flags
       `(,(string-append "DESTDIR=" (assoc-ref %outputs "out"))
          "PLUGINDIR=/lib/zathura" "CC=gcc")
       #:tests? #f ; Package does not include tests.
       #:phases
       (alist-delete 'configure %standard-phases)))
    (home-page "https://pwmt.org/projects/zathura-pdf-poppler/")
    (synopsis "PDF support for zathura (poppler backend)")
    (description "The zathura-pdf-poppler plugin adds PDF support to zathura
by using the poppler rendering engine.")
    (license license:zlib)))

(define-public zathura
  (package
    (name "zathura")
    (version "0.3.2")
    (source (origin
              (method url-fetch)
              (uri
               (string-append "https://pwmt.org/projects/zathura/download/zathura-"
                              version ".tar.gz"))
              (sha256
               (base32
                "1qk5s7cyqp4l673yhma5igk9g24p5jyqyy81fdk7q7xjqlym19px"))
              (patches
               (list
                (search-patch "zathura-plugindir-environment-variable.patch")))))
    (native-inputs `(("pkg-config" ,pkg-config)
                     ("gettext" ,gnu-gettext)))
    (inputs `(("girara" ,girara)
              ("sqlite" ,sqlite)
              ("gtk+" ,gtk+)))
    (native-search-paths
     (list (search-path-specification
            (variable "ZATHURA_PLUGIN_PATH")
            (files '("lib/zathura")))))
    (build-system gnu-build-system)
    (arguments
     `(#:make-flags
       `(,(string-append "PREFIX=" (assoc-ref %outputs "out"))
         "CC=gcc" "COLOR=0")
       #:tests? #f ; Tests fail: "Gtk cannot open display".
       #:test-target "test"
       #:phases
       (alist-delete 'configure %standard-phases)))
    (home-page "https://pwmt.org/projects/zathura/")
    (synopsis "Lightweight keyboard-driven PDF viewer")
    (description "Zathura is a customizable document viewer.  It provides a
minimalistic interface and an interface that mainly focuses on keyboard
interaction.")
    (license license:zlib)))

(define-public podofo
  (package
    (name "podofo")
    (version "0.9.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/podofo/podofo-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "1n12lbq9x15vqn7dc0hsccp56l5jdff1xrhvlfqlbklxx0qiw9pc"))))
    (build-system cmake-build-system)
    (inputs                                      ; TODO: Add cppunit for tests
     `(("lua" ,lua-5.1)
       ("libpng" ,libpng)
       ("openssl" ,openssl)
       ("fontconfig" ,fontconfig)
       ("libtiff" ,libtiff)
       ("libjpeg" ,libjpeg-8)
       ("freetype" ,freetype)
       ("zlib" ,zlib)))
    (arguments
     `(#:configure-flags '("-DPODOFO_BUILD_SHARED=ON"
                           "-DPODOFO_BUILD_STATIC=ON")))
    (home-page "http://podofo.sourceforge.net")
    (synopsis "Tools to work with the PDF file format")
    (description
     "PoDoFo is a C++ library and set of command-line tools to work with the
PDF file format.  It can parse PDF files and load them into memory, and makes
it easy to modify them and write the changes to disk.  It is primarily useful
for applications that wish to do lower level manipulation of PDF, such as
extracting content or merging files.")
    (license license:lgpl2.0+)))

(define-public mupdf
  (package
    (name "mupdf")
    (version "1.6")
    (source
      (origin
        (method url-fetch)
        (uri (string-append "http://mupdf.com/downloads/archive/"
                            name "-" version "-source.tar.gz"))
        (sha256
          (base32 "0qx51rj6alzcagcixm59rvdpm54w6syrwr4184v439jh14ryw4wq"))
        (patches
          (list (search-patch "mupdf-buildsystem-fix.patch")))
        (modules '((guix build utils)))
        (snippet
          '(begin
            ;; Don't build the bundled-in third party libraries.
            (delete-file-recursively "thirdparty")

            ;; Make the scripts for finding openjpeg build details executable.
            (chmod "ojp2_cppflags.sh" #o0755)
            (chmod "ojp2_ldflags.sh" #o0755)))))

    (build-system gnu-build-system)
    (inputs
      `(("curl" ,curl)
        ("freetype" ,freetype)
        ("jbig2dec" ,jbig2dec)
        ("libjpeg" ,libjpeg)
        ("libx11" ,libx11)
        ("libxext" ,libxext)
        ("openjpeg" ,openjpeg-2.0)
        ("openssl" ,openssl)
        ("zlib" ,zlib)))
    (native-inputs
      `(("pkg-config" ,pkg-config)))
    (arguments
      ;; Trying to run `$ make check' results in a no rule fault.
      '(#:tests? #f

        #:modules ((guix build gnu-build-system)
                     (guix build utils)
                     (srfi srfi-1))
        #:phases (alist-replace
                   'build
                   (lambda _ (zero? (system* "make" "XCFLAGS=-fpic")))
                   (alist-replace
                     'install
                     (lambda* (#:key outputs #:allow-other-keys)
                       (let ((out (assoc-ref outputs "out")))
                         (zero? (system* "make" (string-append "prefix=" out)
                                         "install"))))
                     (alist-delete 'configure %standard-phases)))))
    (home-page "http://mupdf.com")
    (synopsis "Lightweight PDF viewer and toolkit")
    (description
      "MuPDF is a C library that implements a PDF and XPS parsing and
rendering engine.  It is used primarily to render pages into bitmaps,
but also provides support for other operations such as searching and
listing the table of contents and hyperlinks.

The library ships with a rudimentary X11 viewer, and a set of command
line tools for batch rendering (pdfdraw), examining the file structure
(pdfshow), and rewriting files (pdfclean).")
    (license license:agpl3+)))

(define-public qpdf
  (package
   (name "qpdf")
   (version "5.1.2")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://sourceforge/qpdf/qpdf-"
                                version ".tar.gz"))
            (sha256 (base32
                     "1zbvhrp0zjzbi6q2bnbxbg6399r47pq5gw3kspzph81j19fqvpg9"))))
   (build-system gnu-build-system)
   (arguments
      '(#:phases (alist-cons-before
                  'configure 'patch-paths
                  (lambda _
                    (substitute* "make/libtool.mk"
                      (("SHELL=/bin/bash")
                       (string-append "SHELL=" (which "bash"))))
                    (substitute* (append
                                  '("qtest/bin/qtest-driver")
                                  (find-files "." "\\.test"))
                      (("/usr/bin/env") (which "env"))))
                  %standard-phases)))
   (native-inputs
    `(("pkg-config" ,pkg-config)))
   (propagated-inputs
    `(("pcre" ,pcre)))
   (inputs
    `(("zlib" ,zlib)
      ("perl" ,perl)))
   (synopsis "Command-line tools and library for transforming PDF files")
   (description
    "QPDF is a command-line program that does structural, content-preserving
transformations on PDF files.  It could have been called something like
pdf-to-pdf.  It includes support for merging and splitting PDFs and to
manipulate the list of pages in a PDF file.  It is not a PDF viewer or a
program capable of converting PDF into other formats.")
   (license license:clarified-artistic)
   (home-page "http://qpdf.sourceforge.net/")))

(define-public xournal
  (package
    (name "xournal")
    (version "0.4.8")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://sourceforge/xournal/xournal-"
                           version ".tar.gz"))
       (sha256
        (base32
         "0c7gjcqhygiyp0ypaipdaxgkbivg6q45vhsj8v5jsi9nh6iqff13"))))
    (build-system gnu-build-system)
    (inputs
     `(("gtk" ,gtk+-2)
       ("pango" ,pango)
       ("poppler" ,poppler)
       ("glib" ,glib)
       ("libgnomecanvas" ,libgnomecanvas)))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (home-page "http://xournal.sourceforge.net/")
    (synopsis "Notetaking using a stylus")
    (description
     "Xournal is an application for notetaking, sketching, keeping a journal
using a stylus.")
    (license license:gpl2+)))
