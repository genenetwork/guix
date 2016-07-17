;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2015 Sou Bunnbu <iyzsong@gmail.com>
;;; Copyright © 2016 Mark H Weaver <mhw@netris.org>
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

(define-module (gnu packages lxqt)
  #:use-module (guix download)
  #:use-module ((guix licenses) #:select (lgpl2.1+))
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix build-system cmake)
  #:use-module (gnu packages)
  #:use-module (gnu packages kde-frameworks)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages qt))

(define-public libqtxdg
  (package
    (name "libqtxdg")
    (version "1.2.0")
    (source
     (origin
       (method url-fetch)
       (uri
         (string-append "https://github.com/lxde/libqtxdg/releases/"
                        "download/" version "/" name "-" version ".tar.xz"))
       (sha256
        (base32
         "1ncqs0lcll5nx69hxfg33m3jfkryjqrjhr2kdci0b8pyaqdv1jc8"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f ; test fails with message "Exception"
       #:configure-flags '("-DBUILD_TESTS=ON")))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (propagated-inputs
     `(("qtbase" ,qtbase))) ; according to Qt5Xdg.pc
    (home-page "https://github.com/lxde/libqtxdg")
    (synopsis "Qt implementation of freedesktop.org xdg specifications")
    (description "Libqtxdg implements the freedesktop.org xdg specifications
in Qt.")
    (license lgpl2.1+)))

(define-public liblxqt
  (package
    (name "liblxqt")
    (version "0.9.0")
    (source
     (origin
       (method url-fetch)
       (uri
         (string-append "https://github.com/lxde/" name
                        "/archive/" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "0mbl3qc0yfgfsndqrw8vg8k5irsy0pg2wrad8nwv0aphphd4n7rg"))
       (patches (search-patches "liblxqt-include.patch"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f))
    (native-inputs `(("pkg-config" ,pkg-config)))
    (inputs
     `(("kwindowsystem" ,kwindowsystem)
       ("libqtxdg" ,libqtxdg)
       ("qtbase" ,qtbase)
       ("qttools" ,qttools)
       ("qtx11extras" ,qtx11extras)))
    (home-page "http://lxqt.org/")
    (synopsis "Core utility library for all LXQt components")
    (description "liblxqt provides the basic libraries shared by the
components of the LXQt desktop environment.")
    (license lgpl2.1+)))


(define-public lxqt-common
  (package
    (name "lxqt-common")
    (version "0.9.1")
    (source
     (origin
       (method url-fetch)
       (uri
         (string-append "https://github.com/lxde/" name
                        "/archive/" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1vd3zarvl44l3y6wn7kgxcd2f1bygsmk5bcfqwa3568cq3b57aw0"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f ; no check target
       #:phases
        (modify-phases %standard-phases
          (add-before 'configure 'fix-installation-paths
           (lambda _
             ;; The variable LXQT_ETC_XDG_DIR is set in
             ;; liblxqt-0.9.0/share/cmake/lxqt/lxqt-config.cmake
             ;; to the Qt5 installation directory, followed by "/etc/xdg".
             ;; We need to have it point to the current installation
             ;; directory instead.
             (substitute* '("config/CMakeLists.txt"
                            "menu/CMakeLists.txt")
               (("\\$\\{LXQT_ETC_XDG_DIR\\}")
                "${CMAKE_INSTALL_PREFIX}/etc/xdg")
               ;; In the same file, LXQT_SHARE_DIR is set to the installation
               ;; directory of liblxqt, followed by "/share/lxqt".
               (("\\$\\{LXQT_SHARE_DIR\\}")
                "${CMAKE_INSTALL_PREFIX}/share/lxqt"))
             ;; Replace absolute directories.
             (substitute* "autostart/CMakeLists.txt"
               (("/etc/xdg")
                "${CMAKE_INSTALL_PREFIX}/etc/xdg"))
             (substitute* "xsession/CMakeLists.txt"
               (("/usr/share")
                "${CMAKE_INSTALL_PREFIX}/share")))))))
    (inputs
     `(("kwindowsystem" ,kwindowsystem)
       ("liblxqt" ,liblxqt)
       ("libqtxdg" ,libqtxdg)
       ("qtbase" ,qtbase)
       ("qttools" ,qttools)
       ("qtx11extras" ,qtx11extras)))
    (home-page "http://lxqt.org/")
    (synopsis "Common files for LXQt")
    (description "lxqt-common provides the desktop integration files
(themes, icons, configuration files etc.) for the LXQt
desktop environment.")
    (license lgpl2.1+)))

(define-public lxqt-session
  (package
    (name "lxqt-session")
    (version "0.9.0")
    (source
     (origin
       (method url-fetch)
       (uri
         (string-append "https://github.com/lxde/" name
                        "/archive/" version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1sdwcfrfqkg7ibrsncs1skdap9n8wm4rg6n9d0fgdz2q4d45h75a"))))
    (build-system cmake-build-system)
    (native-inputs `(("pkg-config" ,pkg-config)))
    (inputs
     `(("kwindowsystem" ,kwindowsystem)
       ("liblxqt" ,liblxqt)
       ("libqtxdg" ,libqtxdg)
       ("qtbase" ,qtbase)
       ("qttools" ,qttools)
       ("qtx11extras" ,qtx11extras)))
    (arguments
     `(#:tests? #f ; no check target
       #:phases
        (modify-phases %standard-phases
          (add-before 'configure 'fix-installation-paths
           (lambda _
             ;; The variable LXQT_TRANSLATIONS_DIR is set in
             ;; liblxqt-0.9.0/share/cmake/lxqt/lxqt-config.cmake
             ;; to the liblxqt installation directory, followed by
             ;; "/share/lxqt/translations".
             ;; We need to have it point to the current installation
             ;; directory instead.
             (substitute* '("lxqt-session/CMakeLists.txt"
                            "lxqt-config-session/CMakeLists.txt")
               (("\\$\\{LXQT_TRANSLATIONS_DIR\\}")
                "${CMAKE_INSTALL_PREFIX}/share/lxqt/translations")))))))
    (home-page "http://lxqt.org/")
    (synopsis "Session manager for LXQt")
    (description "lxqt-session provides the standard session manager
for the LXQt desktop environment.")
    (license lgpl2.1+)))
