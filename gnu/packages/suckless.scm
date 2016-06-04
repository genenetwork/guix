;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013 Cyril Roelandt <tipecaml@gmail.com>
;;; Copyright © 2015 Amirouche Boubekki <amirouche@hypermove.net>
;;; Copyright © 2016 Al McElrath <hello@yrns.org>
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

(define-module (gnu packages suckless)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system glib-or-gtk)
  #:use-module (gnu packages)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages webkit)
  #:use-module (gnu packages fontutils))

(define-public dwm
  (package
    (name "dwm")
    (version "6.0")
    (source (origin
             (method url-fetch)
             (uri (string-append "http://dl.suckless.org/dwm/dwm-"
                                 version ".tar.gz"))
             (sha256
              (base32 "0mpbivy9j80l1jqq4bd4g4z8s5c54fxrjj44avmfwncjwqylifdj"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f
       #:phases
       (alist-replace
        'configure
        (lambda _
         (substitute* "Makefile" (("\\$\\{CC\\}") "gcc"))
         #t)
        (alist-replace
         'install
         (lambda* (#:key outputs #:allow-other-keys)
          (let ((out (assoc-ref outputs "out")))
           (zero?
            (system* "make" "install"
                     (string-append "DESTDIR=" out) "PREFIX="))))
         %standard-phases))))
    (inputs
     `(("libx11" ,libx11)
       ("libxinerama" ,libxinerama)))
    (home-page "http://dwm.suckless.org/")
    (synopsis "Dynamic window manager")
    (description
     "dwm is a dynamic window manager for X.  It manages windows in tiled,
monocle and floating layouts.  All of the layouts can be applied dynamically,
optimising the environment for the application in use and the task performed.

In tiled layout windows are managed in a master and stacking area.  The master
area contains the window which currently needs most attention, whereas the
stacking area contains all other windows.  In monocle layout all windows are
maximised to the screen size.  In floating layout windows can be resized and
moved freely.  Dialog windows are always managed floating, regardless of the
layout applied.

Windows are grouped by tags.  Each window can be tagged with one or multiple
tags.  Selecting certain tags displays all windows with these tags.

Each screen contains a small status bar which displays all available tags, the
layout, the number of visible windows, the title of the focused window, and the
text read from the root window name property, if the screen is focused.  A
floating window is indicated with an empty square and a maximised floating
window is indicated with a filled square before the windows title.  The selected
tags are indicated with a different color.  The tags of the focused window are
indicated with a filled square in the top left corner.  The tags which are
applied to one or more windows are indicated with an empty square in the top
left corner.

dwm draws a small customizable border around windows to indicate the focus
state.")
    (license license:x11)))

(define-public dmenu
  (package
    (name "dmenu")
    (version "4.5")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://dl.suckless.org/tools/dmenu-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "0l58jpxrr80fmyw5pgw5alm5qry49aw6y049745wl991v2cdcb08"))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f ; no tests
       #:make-flags (list "CC=gcc"
                          (string-append "PREFIX=" %output))
       #:phases
       (alist-delete 'configure %standard-phases)))
    (inputs
     `(("libx11" ,libx11)
       ("libxinerama" ,libxinerama)))
    (home-page "http://tools.suckless.org/dmenu/")
    (synopsis "Dynamic menu")
    (description
     "A dynamic menu for X, originally designed for dwm.  It manages large
numbers of user-defined menu items efficiently.")
    (license license:x11)))

(define-public slock
  (package
    (name "slock")
    (version "1.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://dl.suckless.org/tools/slock-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "1crkyr4vblhciy6vnbjwwjnlkm9yg2hzq16v6hzxm20ai67na0il"))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f ; no tests
       #:make-flags (list "CC=gcc"
                          (string-append "PREFIX=" %output))
       #:phases (alist-delete 'configure %standard-phases)))
    (inputs
     `(("libx11" ,libx11)
       ("libxext" ,libxext)
       ("libxinerama" ,libxinerama)))
    (home-page "http://tools.suckless.org/slock/")
    (synopsis "Simple X session lock")
    (description
     "Simple X session lock with trivial feedback on password entry.")
    (license license:x11)))

(define-public st
  (package
    (name "st")
    (version "0.5")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://dl.suckless.org/st/st-"
                           version ".tar.gz"))
       (sha256
        (base32
         "0knxpzaa86pprng6hak8hx8bw22yw22rpz1ffxjpcvqlz3xdv05f"))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f ; no tests
       #:make-flags (list "CC=gcc"
                          (string-append "PREFIX=" %output))
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (add-after 'unpack 'inhibit-terminfo-install
                    (lambda _
                      (substitute* "Makefile"
                        (("\t@tic -s st.info") ""))
                      #t)))))
    (inputs
     `(("libx11" ,libx11)
       ("libxft" ,libxft)
       ("libxcomposite" ,libxcomposite)
       ("compositeproto" ,compositeproto)
       ("libxext" ,libxext)
       ("xextproto" ,xextproto)
       ("libxrender" ,libxrender)
       ("fontconfig" ,fontconfig)
       ("freetype" ,freetype)
       ("font-liberation" ,font-liberation)))
    (native-inputs `(("pkg-config" ,pkg-config)))
    (home-page "http://st.suckless.org/")
    (synopsis "Simple terminal emulator")
    (description
     "St implements a simple and lightweight terminal emulator.  It
implements 256 colors, most VT10X escape sequences, utf8, X11 copy/paste,
antialiased fonts (using fontconfig), fallback fonts, resizing, and line
drawing.")
    (license license:x11)))

(define-public surf
  (package
    (name "surf")
    (version "0.7")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://dl.suckless.org/surf/surf-"
                           version ".tar.gz"))
       (sha256
        (base32
         "0jj93izd8fizxfa6ln9w1h9bwki81sz5dhskh5x1rl34zd38aq4m"))))
    (build-system glib-or-gtk-build-system)
    (arguments
     '(#:tests? #f ; no tests
       #:make-flags (list "CC=gcc"
                          (string-append "PREFIX=" %output))
       #:phases
       (modify-phases %standard-phases
         (delete 'configure))))
    (inputs
     `(("glib-networking" ,glib-networking)
       ("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
       ("webkitgtk" ,webkitgtk/gtk+-2)))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (home-page "http://surf.suckless.org/")
    (synopsis "Simple web browser")
    (description
     "Surf is a simple web browser based on WebKit/GTK+.  It is able to
display websites and follow links.  It supports the XEmbed protocol which
makes it possible to embed it in another application.  Furthermore, one can
point surf to another URI by setting its XProperties.")
    (license license:x11)))
