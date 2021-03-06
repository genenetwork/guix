;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014, 2015 David Thompson <davet@gnu.org>
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

(define-module (gnu packages fish)
  #:use-module (guix licenses)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages python)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu))

(define-public fish
  (package
    (name "fish")
    (version "2.3.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://fishshell.com/files/"
                                  version "/fish-" version ".tar.gz"))
              (sha256
               (base32
                "0r46p64lg6da3v6chsa4gisvl04kd3rpy60yih8r870kbp9wm2ij"))
              (modules '((guix build utils)))
              ;; Don't try to install /etc/fish/config.fish.
              (snippet
               '(substitute* "Makefile.in"
                  ((".*INSTALL.*sysconfdir.*fish.*") "")))))
    (build-system gnu-build-system)
    (native-inputs
     `(("doxygen" ,doxygen)))
    (inputs
     `(("ncurses" ,ncurses)
       ("python" ,python-wrapper)))   ;for fish_config and manpage completions
    (arguments
     '(#:tests? #f ; no check target
       #:configure-flags '("--sysconfdir=/etc")))
    (synopsis "The friendly interactive shell")
    (description
     "Fish (friendly interactive shell) is a shell focused on interactive use,
discoverability, and friendliness.  Fish has very user-friendly and powerful
tab-completion, including descriptions of every completion, completion of
strings with wildcards, and many completions for specific commands.  It also
has extensive and discoverable help.  A special help command gives access to
all the fish documentation in your web browser.  Other features include smart
terminal handling based on terminfo, an easy to search history, and syntax
highlighting.")
    (home-page "https://fishshell.com/")
    (license gpl2)))
