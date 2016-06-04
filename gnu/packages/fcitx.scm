;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Sou Bunnbu <iyzsong@gmail.com>
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

(define-module (gnu packages fcitx)
  #:use-module ((guix licenses) #:select (gpl2+))
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system cmake)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages enchant)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages icu4c)
  #:use-module (gnu packages iso-codes)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg))

(define-public fcitx
  (package
    (name "fcitx")
    (version "4.2.8.6")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://download.fcitx-im.org/fcitx/"
                                  name "-" version "_dict.tar.xz"))
              (sha256
               (base32
                "15ymd42kg920ri0f8fymq3i68g8k1kgpmdlnk9jf5fvnz6g4w0wi"))))
    (build-system cmake-build-system)
    (outputs '("out" "gtk2" "gtk3"))
    (arguments
     `(#:configure-flags
       (list "-DENABLE_TEST=ON"
             (string-append "-DXKB_RULES_XML_FILE="
                            (assoc-ref %build-inputs "xkeyboard-config")
                            "/share/X11/xkb/rules/evdev.xml")
             "-DENABLE_GTK2_IM_MODULE=ON"
             "-DENABLE_GTK3_IM_MODULE=ON"
             (string-append "-DGTK2_IM_MODULEDIR="
                            (assoc-ref %outputs "gtk2")
                            "/lib/gtk-2.0/2.10.0/immodules")
             (string-append "-DGTK3_IM_MODULEDIR="
                            (assoc-ref %outputs "gtk3")
                            "/lib/gtk-3.0/3.0.0/immodules")
             ;; XXX: Enable GObject Introspection and Qt4 support.
             "-DENABLE_GIR=OFF"
             "-DENABLE_QT=OFF"
             "-DENABLE_QT_IM_MODULE=OFF")))
    (native-inputs
     `(("doxygen"    ,doxygen)
       ("glib:bin"   ,glib "bin")    ; for glib-genmarshal
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("dbus"             ,dbus)
       ("enchant"          ,enchant)
       ("gettext"          ,gnu-gettext)
       ("gtk2"             ,gtk+-2)
       ("gtk3"             ,gtk+)
       ("icu4c"            ,icu4c)
       ("iso-codes"        ,iso-codes)
       ("libxkbfile"       ,libxkbfile)
       ("libxml2"          ,libxml2)
       ("xkeyboard-config" ,xkeyboard-config)))
    (home-page "http://fcitx-im.org")
    (synopsis "Input method framework")
    (description
     "Fcitx is an input method framework with extension support.  It has
Pinyin, Quwei and some table-based (Wubi, Cangjie, Erbi, etc.) input methods
built-in.")
    (license gpl2+)))
