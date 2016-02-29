
;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014, 2015, 2016 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2015, 2016 Ben Woodcroft <donttrustben@gmail.com>
;;; Copyright © 2015 Pjotr Prins <pjotr.guix@thebird.nl>
;;; Copyright © 2015 Andreas Enge <andreas@enge.fr>
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

(define-module (gnu packages bioinformatics)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system perl)
  #:use-module (guix build-system python)
  #:use-module (guix build-system r)
  #:use-module (guix build-system ruby)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages algebra)
  #:use-module (gnu packages base)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cpio)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages doxygen)
  #:use-module (gnu packages file)
  #:use-module (gnu packages gawk)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages java)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages machine-learning)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages mpi)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages pcre)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages popt)
  #:use-module (gnu packages protobuf)
  #:use-module (gnu packages python)
  #:use-module (gnu packages ruby)
  #:use-module (gnu packages statistics)
  #:use-module (gnu packages tbb)
  #:use-module (gnu packages textutils)
  #:use-module (gnu packages time)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages vim)
  #:use-module (gnu packages web)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages zip)
  #:use-module (srfi srfi-1))

(define-public aragorn
  (package
    (name "aragorn")
    (version "1.2.36")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://mbio-serv2.mbioekol.lu.se/ARAGORN/Downloads/aragorn"
                    version ".tgz"))
              (sha256
               (base32
                "1dg7jlz1qpqy88igjxd6ncs11ccsirb36qv1z01a0np4i4jh61mb"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ; there are no tests
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'build
                  (lambda _
                    (zero? (system* "gcc"
                                    "-O3"
                                    "-ffast-math"
                                    "-finline-functions"
                                    "-o"
                                    "aragorn"
                                    (string-append "aragorn" ,version ".c")))))
         (replace 'install
                  (lambda* (#:key outputs #:allow-other-keys)
                    (let* ((out (assoc-ref outputs "out"))
                           (bin (string-append out "/bin"))
                           (man (string-append out "/share/man/man1")))
                      (mkdir-p bin)
                      (copy-file "aragorn"
                                 (string-append bin "/aragorn"))
                      (mkdir-p man)
                      (copy-file "aragorn.1"
                                 (string-append man "/aragorn.1")))
                    #t)))))
    (home-page "http://mbio-serv2.mbioekol.lu.se/ARAGORN")
    (synopsis "Detect tRNA, mtRNA and tmRNA genes in nucleotide sequences")
    (description
     "Aragorn identifies transfer RNA, mitochondrial RNA and
transfer-messenger RNA from nucleotide sequences, based on homology to known
tRNA consensus sequences and RNA structure.  It also outputs the secondary
structure of the predicted RNA.")
    (license license:gpl2)))

(define-public bamtools
  (package
    (name "bamtools")
    (version "2.3.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/pezmaster31/bamtools/archive/v"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1brry29bw2xr2l9pqn240rkqwayg85b8qq78zk2zs6nlspk4d018"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f ;no "check" target
       #:phases
       (modify-phases %standard-phases
         (add-before
          'configure 'set-ldflags
          (lambda* (#:key outputs #:allow-other-keys)
            (setenv "LDFLAGS"
                    (string-append
                     "-Wl,-rpath="
                     (assoc-ref outputs "out") "/lib/bamtools")))))))
    (inputs `(("zlib" ,zlib)))
    (home-page "https://github.com/pezmaster31/bamtools")
    (synopsis "C++ API and command-line toolkit for working with BAM data")
    (description
     "BamTools provides both a C++ API and a command-line toolkit for handling
BAM files.")
    (license license:expat)))

(define-public bedops
  (package
    (name "bedops")
    (version "2.4.14")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/bedops/bedops/archive/v"
                                  version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1kqbac547wyqma81cyky9n7mkgikjpsfd3nnmcm6hpqwanqgh10v"))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f
       #:make-flags (list (string-append "BINDIR=" %output "/bin"))
       #:phases
       (alist-cons-after
         'unpack 'unpack-tarballs
         (lambda _
           ;; FIXME: Bedops includes tarballs of minimally patched upstream
           ;; libraries jansson, zlib, and bzip2.  We cannot just use stock
           ;; libraries because at least one of the libraries (zlib) is
           ;; patched to add a C++ function definition (deflateInit2cpp).
           ;; Until the Bedops developers offer a way to link against system
           ;; libraries we have to build the in-tree copies of these three
           ;; libraries.

           ;; See upstream discussion:
           ;; https://github.com/bedops/bedops/issues/124

           ;; Unpack the tarballs to benefit from shebang patching.
           (with-directory-excursion "third-party"
             (and (zero? (system* "tar" "xvf" "jansson-2.6.tar.bz2"))
                  (zero? (system* "tar" "xvf" "zlib-1.2.7.tar.bz2"))
                  (zero? (system* "tar" "xvf" "bzip2-1.0.6.tar.bz2"))))
           ;; Disable unpacking of tarballs in Makefile.
           (substitute* "system.mk/Makefile.linux"
             (("^\tbzcat .*") "\t@echo \"not unpacking\"\n")
             (("\\./configure") "CONFIG_SHELL=bash ./configure"))
           (substitute* "third-party/zlib-1.2.7/Makefile.in"
             (("^SHELL=.*$") "SHELL=bash\n")))
         (alist-delete 'configure %standard-phases))))
    (home-page "https://github.com/bedops/bedops")
    (synopsis "Tools for high-performance genomic feature operations")
    (description
     "BEDOPS is a suite of tools to address common questions raised in genomic
studies---mostly with regard to overlap and proximity relationships between
data sets.  It aims to be scalable and flexible, facilitating the efficient
and accurate analysis and management of large-scale genomic data.

BEDOPS provides tools that perform highly efficient and scalable Boolean and
other set operations, statistical calculations, archiving, conversion and
other management of genomic data of arbitrary scale.  Tasks can be easily
split by chromosome for distributing whole-genome analyses across a
computational cluster.")
    (license license:gpl2+)))

(define-public bedtools
  (package
    (name "bedtools")
    (version "2.25.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/arq5x/bedtools2/archive/v"
                                  version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1ywcy3yfwzhl905b51l0ffjia55h75vv3mw5xkvib04pp6pj548m"))))
    (build-system gnu-build-system)
    (native-inputs `(("python" ,python-2)))
    (inputs `(("samtools" ,samtools)
              ("zlib" ,zlib)))
    (arguments
     '(#:test-target "test"
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((bin (string-append (assoc-ref outputs "out") "/bin/")))
               (for-each (lambda (file)
                           (install-file file bin))
                         (find-files "bin" ".*")))
             #t)))))
    (home-page "https://github.com/arq5x/bedtools2")
    (synopsis "Tools for genome analysis and arithmetic")
    (description
     "Collectively, the bedtools utilities are a swiss-army knife of tools for
a wide-range of genomics analysis tasks.  The most widely-used tools enable
genome arithmetic: that is, set theory on the genome.  For example, bedtools
allows one to intersect, merge, count, complement, and shuffle genomic
intervals from multiple files in widely-used genomic file formats such as BAM,
BED, GFF/GTF, VCF.")
    (license license:gpl2)))

(define-public python2-pybedtools
  (package
    (name "python2-pybedtools")
    (version "0.6.9")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://pypi.python.org/packages/source/p/pybedtools/pybedtools-"
                    version ".tar.gz"))
              (sha256
               (base32
                "1ldzdxw1p4y3g2ignmggsdypvqkcwqwzhdha4rbgpih048z5p4an"))))
    (build-system python-build-system)
    (arguments `(#:python ,python-2)) ; no Python 3 support
    (inputs
     `(("python-cython" ,python2-cython)
       ("python-matplotlib" ,python2-matplotlib)))
    (propagated-inputs
     `(("bedtools" ,bedtools)
       ("samtools" ,samtools)))
    (native-inputs
     `(("python-pyyaml" ,python2-pyyaml)
       ("python-nose" ,python2-nose)
       ("python-setuptools" ,python2-setuptools)))
    (home-page "https://pythonhosted.org/pybedtools/")
    (synopsis "Python wrapper for BEDtools programs")
    (description
     "pybedtools is a Python wrapper for Aaron Quinlan's BEDtools programs,
which are widely used for genomic interval manipulation or \"genome algebra\".
pybedtools extends BEDTools by offering feature-level manipulations from with
Python.")
    (license license:gpl2+)))

(define-public bioperl-minimal
  (let* ((inputs `(("perl-module-build" ,perl-module-build)
                   ("perl-data-stag" ,perl-data-stag)
                   ("perl-libwww" ,perl-libwww)
                   ("perl-uri" ,perl-uri)))
         (transitive-inputs
          (map (compose package-name cadr)
               (delete-duplicates
                (concatenate
                 (map (compose package-transitive-target-inputs cadr) inputs))))))
    (package
      (name "bioperl-minimal")
      (version "1.6.924")
      (source
       (origin
         (method url-fetch)
         (uri (string-append "mirror://cpan/authors/id/C/CJ/CJFIELDS/BioPerl-"
                             version ".tar.gz"))
         (sha256
          (base32
           "1l3npcvvvwjlhkna9dndpfv1hklhrgva013kw96m0n1wpd37ask1"))))
      (build-system perl-build-system)
      (arguments
       `(#:phases
         (modify-phases %standard-phases
           (add-after
            'install 'wrap-programs
            (lambda* (#:key outputs #:allow-other-keys)
              ;; Make sure all executables in "bin" find the required Perl
              ;; modules at runtime.  As the PERL5LIB variable contains also
              ;; the paths of native inputs, we pick the transitive target
              ;; inputs from %build-inputs.
              (let* ((out  (assoc-ref outputs "out"))
                     (bin  (string-append out "/bin/"))
                     (path (string-join
                            (cons (string-append out "/lib/perl5/site_perl")
                                  (map (lambda (name)
                                         (assoc-ref %build-inputs name))
                                       ',transitive-inputs))
                            ":")))
                (for-each (lambda (file)
                            (wrap-program file
                              `("PERL5LIB" ":" prefix (,path))))
                          (find-files bin "\\.pl$"))
                #t))))))
      (inputs inputs)
      (native-inputs
       `(("perl-test-most" ,perl-test-most)))
      (home-page "http://search.cpan.org/dist/BioPerl")
      (synopsis "Bioinformatics toolkit")
      (description
       "BioPerl is the product of a community effort to produce Perl code which
is useful in biology.  Examples include Sequence objects, Alignment objects
and database searching objects.  These objects not only do what they are
advertised to do in the documentation, but they also interact - Alignment
objects are made from the Sequence objects, Sequence objects have access to
Annotation and SeqFeature objects and databases, Blast objects can be
converted to Alignment objects, and so on.  This means that the objects
provide a coordinated and extensible framework to do computational biology.")
      (license (package-license perl)))))

(define-public python-biopython
  (package
    (name "python-biopython")
    (version "1.66")
    (source (origin
              (method url-fetch)
              ;; use PyPi rather than biopython.org to ease updating
              (uri (pypi-uri "biopython" version))
              (sha256
               (base32
                "1gdv92593klimg22icf5j9by7xiq86jnwzkpz4abaa05ylkdf6hp"))))
    (build-system python-build-system)
    (inputs
     `(("python-numpy" ,python-numpy)))
    (native-inputs
     `(("python-setuptools" ,python2-setuptools)))
    (home-page "http://biopython.org/")
    (synopsis "Tools for biological computation in Python")
    (description
     "Biopython is a set of tools for biological computation including parsers
for bioinformatics files into Python data structures; interfaces to common
bioinformatics programs; a standard sequence class and tools for performing
common operations on them; code to perform data classification; code for
dealing with alignments; code making it easy to split up parallelizable tasks
into separate processes; and more.")
    (license (license:non-copyleft "http://www.biopython.org/DIST/LICENSE"))))

(define-public python2-biopython
  (package (inherit (package-with-python2 python-biopython))
    (inputs
     `(("python2-numpy" ,python2-numpy)))))

(define-public blast+
  (package
    (name "blast+")
    (version "2.2.31")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/"
                    version "/ncbi-blast-" version "+-src.tar.gz"))
              (sha256
               (base32
                "19gq6as4k1jrgsd26158ads6h7v4jca3h4r5dzg1y0m6ya50x5ph"))
              (modules '((guix build utils)))
              (snippet
               '(begin
                  ;; Remove bundled bzip2 and zlib
                  (delete-file-recursively "c++/src/util/compress/bzip2")
                  (delete-file-recursively "c++/src/util/compress/zlib")
                  (substitute* "c++/src/util/compress/Makefile.in"
                    (("bzip2 zlib api") "api"))
                  ;; Remove useless msbuild directory
                  (delete-file-recursively
                   "c++/src/build-system/project_tree_builder/msbuild")
                  #t))))
    (build-system gnu-build-system)
    (arguments
     `(;; There are three(!) tests for this massive library, and all fail with
       ;; "unparsable timing stats".
       ;; ERR [127] --  [util/regexp] test_pcre.sh     (unparsable timing stats)
       ;; ERR [127] --  [serial/datatool] datatool.sh     (unparsable timing stats)
       ;; ERR [127] --  [serial/datatool] datatool_xml.sh     (unparsable timing stats)
       #:tests? #f
       #:out-of-source? #t
       #:parallel-build? #f ; not supported
       #:phases
       (modify-phases %standard-phases
         (add-before
          'configure 'set-HOME
          ;; $HOME needs to be set at some point during the configure phase
          (lambda _ (setenv "HOME" "/tmp") #t))
         (add-after
          'unpack 'enter-dir
          (lambda _ (chdir "c++") #t))
         (add-after
          'enter-dir 'fix-build-system
          (lambda _
            (define (which* cmd)
              (cond ((string=? cmd "date")
                     ;; make call to "date" deterministic
                     "date -d @0")
                    ((which cmd)
                     => identity)
                    (else
                     (format (current-error-port)
                             "WARNING: Unable to find absolute path for ~s~%"
                             cmd)
                     #f)))

            ;; Rewrite hardcoded paths to various tools
            (substitute* (append '("src/build-system/configure.ac"
                                   "src/build-system/configure"
                                   "scripts/common/impl/if_diff.sh"
                                   "scripts/common/impl/run_with_lock.sh"
                                   "src/build-system/Makefile.configurables.real"
                                   "src/build-system/Makefile.in.top"
                                   "src/build-system/Makefile.meta.gmake=no"
                                   "src/build-system/Makefile.meta.in"
                                   "src/build-system/Makefile.meta_l"
                                   "src/build-system/Makefile.meta_p"
                                   "src/build-system/Makefile.meta_r"
                                   "src/build-system/Makefile.mk.in"
                                   "src/build-system/Makefile.requirements"
                                   "src/build-system/Makefile.rules_with_autodep.in")
                                 (find-files "scripts/common/check" "\\.sh$"))
              (("(/usr/bin/|/bin/)([a-z][-_.a-z]*)" all dir cmd)
               (or (which* cmd) all)))

            (substitute* (find-files "src/build-system" "^config.*")
              (("LN_S=/bin/\\$LN_S") (string-append "LN_S=" (which "ln")))
              (("^PATH=.*") ""))

            ;; rewrite "/var/tmp" in check script
            (substitute* "scripts/common/check/check_make_unix.sh"
              (("/var/tmp") "/tmp"))

            ;; do not reset PATH
            (substitute* (find-files "scripts/common/impl/" "\\.sh$")
              (("^ *PATH=.*") "")
              (("action=/bin/") "action=")
              (("export PATH") ":"))
            #t))
         (replace
          'configure
          (lambda* (#:key inputs outputs #:allow-other-keys)
            (let ((out     (assoc-ref outputs "out"))
                  (lib     (string-append (assoc-ref outputs "lib") "/lib"))
                  (include (string-append (assoc-ref outputs "include")
                                          "/include/ncbi-tools++")))
              ;; The 'configure' script doesn't recognize things like
              ;; '--enable-fast-install'.
              (zero? (system* "./configure.orig"
                              (string-append "--with-build-root=" (getcwd) "/build")
                              (string-append "--prefix=" out)
                              (string-append "--libdir=" lib)
                              (string-append "--includedir=" include)
                              (string-append "--with-bz2="
                                             (assoc-ref inputs "bzip2"))
                              (string-append "--with-z="
                                             (assoc-ref inputs "zlib"))
                              ;; Each library is built twice by default, once
                              ;; with "-static" in its name, and again
                              ;; without.
                              "--without-static"
                              "--with-dll"))))))))
    (outputs '("out"       ;  19 MB
               "lib"       ; 203 MB
               "include")) ;  32 MB
    (inputs
     `(("bzip2" ,bzip2)
       ("zlib" ,zlib)))
    (native-inputs
     `(("cpio" ,cpio)))
    (home-page "http://blast.ncbi.nlm.nih.gov")
    (synopsis "Basic local alignment search tool")
    (description
     "BLAST is a popular method of performing a DNA or protein sequence
similarity search, using heuristics to produce results quickly.  It also
calculates an “expect value” that estimates how many matches would have
occurred at a given score by chance, which can aid a user in judging how much
confidence to have in an alignment.")
    ;; Most of the sources are in the public domain, with the following
    ;; exceptions:
    ;;   * Expat:
    ;;     * ./c++/include/util/bitset/
    ;;     * ./c++/src/html/ncbi_menu*.js
    ;;   * Boost license:
    ;;     * ./c++/include/util/impl/floating_point_comparison.hpp
    ;;   * LGPL 2+:
    ;;     * ./c++/include/dbapi/driver/odbc/unix_odbc/
    ;;   * ASL 2.0:
    ;;     * ./c++/src/corelib/teamcity_*
    (license (list license:public-domain
                   license:expat
                   license:boost1.0
                   license:lgpl2.0+
                   license:asl2.0))))

(define-public bless
  (package
    (name "bless")
    (version "1p02")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/bless-ec/bless.v"
                                  version ".tgz"))
              (sha256
               (base32
                "0rm0gw2s18dqwzzpl3c2x1z05ni2v0xz5dmfk3d33j6g4cgrlrdd"))
              (modules '((guix build utils)))
              (snippet
               `(begin
                  ;; Remove bundled boost, pigz, zlib, and .git directory
                  ;; FIXME: also remove bundled sources for google-sparsehash,
                  ;; murmurhash3, kmc once packaged.
                  (delete-file-recursively "boost")
                  (delete-file-recursively "pigz")
                  (delete-file-recursively "zlib")
                  (delete-file-recursively ".git")
                  #t))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f ;no "check" target
       #:make-flags
       (list (string-append "ZLIB="
                            (assoc-ref %build-inputs "zlib")
                            "/lib/libz.a")
             (string-append "LDFLAGS="
                            (string-join '("-lboost_filesystem"
                                           "-lboost_system"
                                           "-lboost_iostreams"
                                           "-lz"
                                           "-fopenmp"
                                           "-std=c++11"))))
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'do-not-build-bundled-pigz
          (lambda* (#:key inputs outputs #:allow-other-keys)
            (substitute* "Makefile"
              (("cd pigz/pigz-2.3.3; make") ""))
            #t))
         (add-after 'unpack 'patch-paths-to-executables
          (lambda* (#:key inputs outputs #:allow-other-keys)
            (substitute* "parse_args.cpp"
              (("kmc_binary = .*")
               (string-append "kmc_binary = \""
                              (assoc-ref outputs "out")
                              "/bin/kmc\";"))
              (("pigz_binary = .*")
               (string-append "pigz_binary = \""
                              (assoc-ref inputs "pigz")
                              "/bin/pigz\";")))
            #t))
         (replace 'install
          (lambda* (#:key outputs #:allow-other-keys)
            (let ((bin (string-append (assoc-ref outputs "out") "/bin/")))
              (for-each (lambda (file)
                          (install-file file bin))
                        '("bless" "kmc/bin/kmc"))
              #t)))
         (delete 'configure))))
    (native-inputs
     `(("perl" ,perl)))
    (inputs
     `(("openmpi" ,openmpi)
       ("boost" ,boost)
       ("pigz" ,pigz)
       ("zlib" ,zlib)))
    (supported-systems '("x86_64-linux"))
    (home-page "http://sourceforge.net/p/bless-ec/wiki/Home/")
    (synopsis "Bloom-filter-based error correction tool for NGS reads")
    (description
     "@dfn{Bloom-filter-based error correction solution for high-throughput
sequencing reads} (BLESS) uses a single minimum-sized bloom filter is a
correction tool for genomic reads produced by @dfn{Next-generation
sequencing} (NGS).  BLESS produces accurate correction results with much less
memory compared with previous solutions and is also able to tolerate a higher
false-positive rate.  BLESS can extend reads like DNA assemblers to correct
errors at the end of reads.")
    (license license:gpl3+)))

(define-public bowtie
  (package
    (name "bowtie")
    (version "2.2.6")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/BenLangmead/bowtie2/archive/v"
                                  version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1ssfvymxfrap6f9pf86s9bvsbqdgka4abr2r7j3mgr4w1l289m86"))
              (modules '((guix build utils)))
              (snippet
               '(substitute* "Makefile"
                  ;; replace BUILD_HOST and BUILD_TIME for deterministic build
                  (("-DBUILD_HOST=.*") "-DBUILD_HOST=\"\\\"guix\\\"\"")
                  (("-DBUILD_TIME=.*") "-DBUILD_TIME=\"\\\"0\\\"\"")))))
    (build-system gnu-build-system)
    (inputs `(("perl" ,perl)
              ("perl-clone" ,perl-clone)
              ("perl-test-deep" ,perl-test-deep)
              ("perl-test-simple" ,perl-test-simple)
              ("python" ,python-2)
              ("tbb" ,tbb)))
    (arguments
     '(#:make-flags
       (list "allall"
             "WITH_TBB=1"
             (string-append "prefix=" (assoc-ref %outputs "out")))
       #:phases
       (alist-delete
        'configure
        (alist-replace
         'check
         (lambda* (#:key outputs #:allow-other-keys)
           (system* "perl"
                    "scripts/test/simple_tests.pl"
                    "--bowtie2=./bowtie2"
                    "--bowtie2-build=./bowtie2-build"))
         %standard-phases))))
    (home-page "http://bowtie-bio.sourceforge.net/bowtie2/index.shtml")
    (synopsis "Fast and sensitive nucleotide sequence read aligner")
    (description
     "Bowtie 2 is a fast and memory-efficient tool for aligning sequencing
reads to long reference sequences.  It is particularly good at aligning reads
of about 50 up to 100s or 1,000s of characters, and particularly good at
aligning to relatively long (e.g. mammalian) genomes.  Bowtie 2 indexes the
genome with an FM Index to keep its memory footprint small: for the human
genome, its memory footprint is typically around 3.2 GB.  Bowtie 2 supports
gapped, local, and paired-end alignment modes.")
    (supported-systems '("x86_64-linux"))
    (license license:gpl3+)))

(define-public tophat
  (package
    (name "tophat")
    (version "2.1.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://ccb.jhu.edu/software/tophat/downloads/tophat-"
                    version ".tar.gz"))
              (sha256
               (base32
                "168zlzykq622zbgkh90a90f1bdgsxkscq2zxzbj8brq80hbjpyp7"))
              (patches (list (search-patch "tophat-build-with-later-seqan.patch")))
              (modules '((guix build utils)))
              (snippet
               '(begin
                  ;; Remove bundled SeqAn and samtools
                  (delete-file-recursively "src/SeqAn-1.3")
                  (delete-file-recursively "src/samtools-0.1.18")
                  #t))))
    (build-system gnu-build-system)
    (arguments
     '(#:parallel-build? #f ; not supported
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'use-system-samtools
           (lambda* (#:key inputs #:allow-other-keys)
             (substitute* "src/Makefile.in"
               (("(noinst_LIBRARIES = )\\$\\(SAMLIB\\)" _ prefix) prefix)
               (("\\$\\(SAMPROG\\): \\$\\(SAMLIB\\)") "")
               (("SAMPROG = samtools_0\\.1\\.18") "")
               (("\\$\\(samtools_0_1_18_SOURCES\\)") "")
               (("am__EXEEXT_1 = samtools_0\\.1\\.18\\$\\(EXEEXT\\)") ""))
             (substitute* '("src/common.cpp"
                            "src/tophat.py")
               (("samtools_0.1.18") (which "samtools")))
             (substitute* '("src/common.h"
                            "src/bam2fastx.cpp")
               (("#include \"bam.h\"") "#include <samtools/bam.h>")
               (("#include \"sam.h\"") "#include <samtools/sam.h>"))
             (substitute* '("src/bwt_map.h"
                            "src/map2gtf.h"
                            "src/align_status.h")
               (("#include <bam.h>") "#include <samtools/bam.h>")
               (("#include <sam.h>") "#include <samtools/sam.h>"))
             #t)))))
    (inputs
     `(("boost" ,boost)
       ("bowtie" ,bowtie)
       ("samtools" ,samtools-0.1)
       ("ncurses" ,ncurses)
       ("python" ,python-2)
       ("perl" ,perl)
       ("zlib" ,zlib)
       ("seqan" ,seqan)))
    (home-page "http://ccb.jhu.edu/software/tophat/index.shtml")
    (synopsis "Spliced read mapper for RNA-Seq data")
    (description
     "TopHat is a fast splice junction mapper for nucleotide sequence
reads produced by the RNA-Seq method.  It aligns RNA-Seq reads to
mammalian-sized genomes using the ultra high-throughput short read
aligner Bowtie, and then analyzes the mapping results to identify
splice junctions between exons.")
    ;; TopHat is released under the Boost Software License, Version 1.0
    ;; See https://github.com/infphilo/tophat/issues/11#issuecomment-121589893
    (license license:boost1.0)))

(define-public bwa
  (package
    (name "bwa")
    (version "0.7.12")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/bio-bwa/bwa-"
                                  version ".tar.bz2"))
              (sha256
               (base32
                "1330dpqncv0px3pbhjzz1gwgg39kkcv2r9qp2xs0sixf8z8wl7bh"))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f ;no "check" target
       #:phases
       (alist-replace
        'install
        (lambda* (#:key outputs #:allow-other-keys)
          (let ((bin (string-append
                      (assoc-ref outputs "out") "/bin"))
                (doc (string-append
                      (assoc-ref outputs "out") "/share/doc/bwa"))
                (man (string-append
                      (assoc-ref outputs "out") "/share/man/man1")))
            (mkdir-p bin)
            (mkdir-p doc)
            (mkdir-p man)
            (install-file "bwa" bin)
            (install-file "README.md" doc)
            (install-file "bwa.1" man)))
        ;; no "configure" script
        (alist-delete 'configure %standard-phases))))
    (inputs `(("zlib" ,zlib)))
    ;; Non-portable SSE instructions are used so building fails on platforms
    ;; other than x86_64.
    (supported-systems '("x86_64-linux"))
    (home-page "http://bio-bwa.sourceforge.net/")
    (synopsis "Burrows-Wheeler sequence aligner")
    (description
     "BWA is a software package for mapping low-divergent sequences against a
large reference genome, such as the human genome.  It consists of three
algorithms: BWA-backtrack, BWA-SW and BWA-MEM.  The first algorithm is
designed for Illumina sequence reads up to 100bp, while the rest two for
longer sequences ranged from 70bp to 1Mbp.  BWA-MEM and BWA-SW share similar
features such as long-read support and split alignment, but BWA-MEM, which is
the latest, is generally recommended for high-quality queries as it is faster
and more accurate.  BWA-MEM also has better performance than BWA-backtrack for
70-100bp Illumina reads.")
    (license license:gpl3+)))

(define-public python2-bx-python
  (package
    (name "python2-bx-python")
    (version "0.7.2")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://pypi.python.org/packages/source/b/bx-python/bx-python-"
                    version ".tar.gz"))
              (sha256
               (base32
                "0ld49idhc5zjdvbhvjq1a2qmpjj7h5v58rqr25dzmfq7g34b50xh"))
              (modules '((guix build utils)))
              (snippet
               '(substitute* "setup.py"
                  ;; remove dependency on outdated "distribute" module
                  (("^from distribute_setup import use_setuptools") "")
                  (("^use_setuptools\\(\\)") "")))))
    (build-system python-build-system)
    (arguments
     `(#:tests? #f ;tests fail because test data are not included
       #:python ,python-2))
    (inputs
     `(("python-numpy" ,python2-numpy)
       ("zlib" ,zlib)))
    (native-inputs
     `(("python-nose" ,python2-nose)
       ("python-setuptools" ,python2-setuptools)))
    (home-page "http://bitbucket.org/james_taylor/bx-python/")
    (synopsis "Tools for manipulating biological data")
    (description
     "bx-python provides tools for manipulating biological data, particularly
multiple sequence alignments.")
    (license license:expat)))

(define-public clipper
  (package
    (name "clipper")
    (version "0.3.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/YeoLab/clipper/archive/"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1q7jpimsqln7ic44i8v2rx2haj5wvik8hc1s2syd31zcn0xk1iyq"))
              (modules '((guix build utils)))
              (snippet
               ;; remove unnecessary setup dependency
               '(substitute* "setup.py"
                  (("setup_requires = .*") "")))))
    (build-system python-build-system)
    (arguments `(#:python ,python-2)) ; only Python 2 is supported
    (inputs
     `(("htseq" ,htseq)
       ("python-pybedtools" ,python2-pybedtools)
       ("python-cython" ,python2-cython)
       ("python-scikit-learn" ,python2-scikit-learn)
       ("python-matplotlib" ,python2-matplotlib)
       ("python-pysam" ,python2-pysam)
       ("python-numpy" ,python2-numpy)
       ("python-scipy" ,python2-scipy)))
    (native-inputs
     `(("python-mock" ,python2-mock) ; for tests
       ("python-pytz" ,python2-pytz) ; for tests
       ("python-setuptools" ,python2-setuptools)))
    (home-page "https://github.com/YeoLab/clipper")
    (synopsis "CLIP peak enrichment recognition")
    (description
     "CLIPper is a tool to define peaks in CLIP-seq datasets.")
    (license license:gpl2)))

(define-public couger
  (package
    (name "couger")
    (version "1.8.2")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://couger.oit.duke.edu/static/assets/COUGER"
                    version ".zip"))
              (sha256
               (base32
                "04p2b14nmhzxw5h72mpzdhalv21bx4w9b87z0wpw0xzxpysyncmq"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (delete 'build)
         (replace
          'install
          (lambda* (#:key outputs #:allow-other-keys)
            (let ((out (assoc-ref outputs "out")))
              (copy-recursively "src" (string-append out "/src"))
              (mkdir (string-append out "/bin"))
              ;; Add "src" directory to module lookup path.
              (substitute* "couger"
                (("from argparse")
                 (string-append "import sys\nsys.path.append(\""
                                out "\")\nfrom argparse")))
              (copy-file "couger" (string-append out "/bin/couger")))
            #t))
         (add-after
          'install 'wrap-program
          (lambda* (#:key inputs outputs #:allow-other-keys)
            ;; Make sure 'couger' runs with the correct PYTHONPATH.
            (let* ((out (assoc-ref outputs "out"))
                   (path (getenv "PYTHONPATH")))
              (wrap-program (string-append out "/bin/couger")
                `("PYTHONPATH" ":" prefix (,path))))
            #t)))))
    (inputs
     `(("python" ,python-2)
       ("python2-pillow" ,python2-pillow)
       ("python2-numpy" ,python2-numpy)
       ("python2-scipy" ,python2-scipy)
       ("python2-matplotlib" ,python2-matplotlib)))
    (propagated-inputs
     `(("r" ,r)
       ("libsvm" ,libsvm)
       ("randomjungle" ,randomjungle)))
    (native-inputs
     `(("unzip" ,unzip)))
    (home-page "http://couger.oit.duke.edu")
    (synopsis "Identify co-factors in sets of genomic regions")
    (description
     "COUGER can be applied to any two sets of genomic regions bound by
paralogous TFs (e.g., regions derived from ChIP-seq experiments) to identify
putative co-factors that provide specificity to each TF.  The framework
determines the genomic targets uniquely-bound by each TF, and identifies a
small set of co-factors that best explain the in vivo binding differences
between the two TFs.

COUGER uses classification algorithms (support vector machines and random
forests) with features that reflect the DNA binding specificities of putative
co-factors.  The features are generated either from high-throughput TF-DNA
binding data (from protein binding microarray experiments), or from large
collections of DNA motifs.")
    (license license:gpl3+)))

(define-public clustal-omega
  (package
    (name "clustal-omega")
    (version "1.2.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://www.clustal.org/omega/clustal-omega-"
                    version ".tar.gz"))
              (sha256
               (base32
                "02ibkx0m0iwz8nscg998bh41gg251y56cgh86bvyrii5m8kjgwqf"))))
    (build-system gnu-build-system)
    (inputs
     `(("argtable" ,argtable)))
    (home-page "http://www.clustal.org/omega/")
    (synopsis "Multiple sequence aligner for protein and DNA/RNA")
    (description
     "Clustal-Omega is a general purpose multiple sequence alignment (MSA)
program for protein and DNA/RNA.  It produces high quality MSAs and is capable
of handling data-sets of hundreds of thousands of sequences in reasonable
time.")
    (license license:gpl2+)))

(define-public crossmap
  (package
    (name "crossmap")
    (version "0.2.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/crossmap/CrossMap-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "07y179f63d7qnzdvkqcziwk9bs3k4zhp81q392fp1hwszjdvy22f"))
              ;; This patch has been sent upstream already and is available
              ;; for download from Sourceforge, but it has not been merged.
              (patches (list
                        (search-patch "crossmap-allow-system-pysam.patch")))
              (modules '((guix build utils)))
              ;; remove bundled copy of pysam
              (snippet
               '(delete-file-recursively "lib/pysam"))))
    (build-system python-build-system)
    (arguments
     `(#:python ,python-2
       #:phases
       (alist-cons-after
        'unpack 'set-env
        (lambda _ (setenv "CROSSMAP_USE_SYSTEM_PYSAM" "1"))
        %standard-phases)))
    (inputs
     `(("python-numpy" ,python2-numpy)
       ("python-pysam" ,python2-pysam)
       ("zlib" ,zlib)))
    (native-inputs
     `(("python-cython" ,python2-cython)
       ("python-nose" ,python2-nose)
       ("python-setuptools" ,python2-setuptools)))
    (home-page "http://crossmap.sourceforge.net/")
    (synopsis "Convert genome coordinates between assemblies")
    (description
     "CrossMap is a program for conversion of genome coordinates or annotation
files between different genome assemblies.  It supports most commonly used
file formats including SAM/BAM, Wiggle/BigWig, BED, GFF/GTF, VCF.")
    (license license:gpl2+)))

(define-public cufflinks
  (package
    (name "cufflinks")
    (version "2.2.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://cole-trapnell-lab.github.io/"
                                  "cufflinks/assets/downloads/cufflinks-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "1bnm10p8m7zq4qiipjhjqb24csiqdm1pwc8c795z253r2xk6ncg8"))))
    (build-system gnu-build-system)
    (arguments
     `(#:make-flags
       (list
        ;; The includes for "eigen" are located in a subdirectory.
        (string-append "EIGEN_CPPFLAGS="
                       "-I" (assoc-ref %build-inputs "eigen")
                       "/include/eigen3/")
        ;; Cufflinks must be linked with various boost libraries.
        (string-append "LDFLAGS="
                       (string-join '("-lboost_system"
                                      "-lboost_serialization"
                                      "-lboost_thread"))))
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-search-for-bam
          (lambda _
            (substitute* '("ax_bam.m4"
                           "configure"
                           "src/hits.h")
              (("<bam/sam\\.h>") "<samtools/sam.h>")
              (("<bam/bam\\.h>") "<samtools/bam.h>")
              (("<bam/version\\.hpp>") "<samtools/version.h>"))
            #t)))
       #:configure-flags
       (list (string-append "--with-bam="
                            (assoc-ref %build-inputs "samtools")))))
    (inputs
     `(("eigen" ,eigen)
       ("samtools" ,samtools-0.1)
       ("htslib" ,htslib)
       ("boost" ,boost)
       ("python" ,python-2)
       ("zlib" ,zlib)))
    (home-page "http://cole-trapnell-lab.github.io/cufflinks/")
    (synopsis "Transcriptome assembly and RNA-Seq expression analysis")
    (description
     "Cufflinks assembles RNA transcripts, estimates their abundances,
and tests for differential expression and regulation in RNA-Seq
samples.  It accepts aligned RNA-Seq reads and assembles the
alignments into a parsimonious set of transcripts.  Cufflinks then
estimates the relative abundances of these transcripts based on how
many reads support each one, taking into account biases in library
preparation protocols.")
    (license license:boost1.0)))

(define-public cutadapt
  (package
    (name "cutadapt")
    (version "1.8")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/marcelm/cutadapt/archive/v"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "161bp87y6gd6r5bmvjpn2b1k942i3fizfpa139f0jn6jv1wcp5h5"))))
    (build-system python-build-system)
    (arguments
     ;; tests must be run after install
     `(#:phases (alist-cons-after
                 'install 'check
                 (lambda* (#:key inputs outputs #:allow-other-keys)
                   (setenv "PYTHONPATH"
                           (string-append
                            (getenv "PYTHONPATH")
                            ":" (assoc-ref outputs "out")
                            "/lib/python"
                            (string-take (string-take-right
                                          (assoc-ref inputs "python") 5) 3)
                            "/site-packages"))
                   (zero? (system* "nosetests" "-P" "tests")))
                 (alist-delete 'check %standard-phases))))
    (native-inputs
     `(("python-cython" ,python-cython)
       ("python-nose" ,python-nose)
       ("python-setuptools" ,python-setuptools)))
    (home-page "https://code.google.com/p/cutadapt/")
    (synopsis "Remove adapter sequences from nucleotide sequencing reads")
    (description
     "Cutadapt finds and removes adapter sequences, primers, poly-A tails and
other types of unwanted sequence from high-throughput sequencing reads.")
    (license license:expat)))

(define-public libbigwig
  (package
    (name "libbigwig")
    (version "0.1.4")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/dpryan79/libBigWig/"
                                  "archive/" version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "098rjh35pi4a9q83n8wiwvyzykjqj6l8q189p1xgfw4ghywdlvw1"))))
    (build-system gnu-build-system)
    (arguments
     `(#:test-target "test"
       #:make-flags
       (list "CC=gcc"
             (string-append "prefix=" (assoc-ref %outputs "out")))
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (add-before 'check 'disable-curl-test
           (lambda _
             (substitute* "Makefile"
               (("./test/testRemote.*") ""))
             #t))
         ;; This has been fixed with the upstream commit 4ff6959cd8a0, but
         ;; there has not yet been a release containing this change.
         (add-before 'install 'create-target-dirs
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (mkdir-p (string-append out "/lib"))
               (mkdir-p (string-append out "/include"))
               #t))))))
    (inputs
     `(("zlib" ,zlib)
       ("curl" ,curl)))
    (native-inputs
     `(("doxygen" ,doxygen)))
    (home-page "https://github.com/dpryan79/libBigWig")
    (synopsis "C library for handling bigWig files")
    (description
     "This package provides a C library for parsing local and remote BigWig
files.")
    (license license:expat)))

(define-public deeptools
  (package
    (name "deeptools")
    (version "1.5.11")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/fidelram/deepTools/archive/"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1kaagygcbvjs9sxd9cqmskd02wcfp9imvb735r087w7hwqpvz6fs"))))
    (build-system python-build-system)
    (arguments
     `(#:python ,python-2))
    (propagated-inputs
     `(("python-scipy" ,python2-scipy)
       ("python-numpy" ,python2-numpy)
       ("python-matplotlib" ,python2-matplotlib)
       ("python-bx-python" ,python2-bx-python)
       ("python-pysam" ,python2-pysam)))
    (native-inputs
     `(("python-mock" ,python2-mock) ;for tests
       ("python-pytz" ,python2-pytz) ;for tests
       ("python-setuptools" ,python2-setuptools)))
    (home-page "https://github.com/fidelram/deepTools")
    (synopsis "Tools for normalizing and visualizing deep-sequencing data")
    (description
     "DeepTools addresses the challenge of handling the large amounts of data
that are now routinely generated from DNA sequencing centers.  To do so,
deepTools contains useful modules to process the mapped reads data to create
coverage files in standard bedGraph and bigWig file formats.  By doing so,
deepTools allows the creation of normalized coverage files or the comparison
between two files (for example, treatment and control).  Finally, using such
normalized and standardized files, multiple visualizations can be created to
identify enrichments with functional annotations of the genome.")
    (license license:gpl3+)))

(define-public diamond
  (package
    (name "diamond")
    (version "0.7.9")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/bbuchfink/diamond/archive/v"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "0hfkcfv9f76h5brbyw9fyvmc0l9cmbsxrcdqk0fa9xv82zj47p15"))
              (snippet '(begin
                          (delete-file "bin/diamond")
                          #t))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f  ;no "check" target
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'enter-source-dir
                    (lambda _
                      (chdir "src")
                      #t))
         (delete 'configure)
         (replace 'install
                  (lambda* (#:key outputs #:allow-other-keys)
                    (let ((bin (string-append (assoc-ref outputs "out")
                                              "/bin")))
                      (mkdir-p bin)
                      (copy-file "../bin/diamond"
                                 (string-append bin "/diamond"))
                      #t))))))
    (native-inputs
     `(("bc" ,bc)))
    (inputs
     `(("boost" ,boost)
       ("zlib" ,zlib)))
    (home-page "https://github.com/bbuchfink/diamond")
    (synopsis "Accelerated BLAST compatible local sequence aligner")
    (description
     "DIAMOND is a BLAST-compatible local aligner for mapping protein and
translated DNA query sequences against a protein reference database (BLASTP
and BLASTX alignment mode).  The speedup over BLAST is up to 20,000 on short
reads at a typical sensitivity of 90-99% relative to BLAST depending on the
data and settings.")
    ;; diamond fails to build on other platforms
    ;; https://github.com/bbuchfink/diamond/issues/18
    (supported-systems '("x86_64-linux"))
    (license (license:non-copyleft "file://src/COPYING"
                                   "See src/COPYING in the distribution."))))

(define-public edirect
  (package
    (name "edirect")
    (version "3.50")
    (source (origin
              (method url-fetch)
              ;; Note: older versions are not retained.
              (uri "ftp://ftp.ncbi.nlm.nih.gov/entrez/entrezdirect/edirect.tar.gz")
              (sha256
               (base32
                "1cr3gzcs3flmgnnbj5iz93vh9w0fca1ilzi2q82cl63ln3mwvpz0"))))
    (build-system perl-build-system)
    (arguments
     `(#:tests? #f ;no "check" target
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (delete 'build)
         (replace 'install
                  (lambda* (#:key outputs #:allow-other-keys)
                    (let ((target (string-append (assoc-ref outputs "out")
                                                 "/bin")))
                      (mkdir-p target)
                      (copy-file "edirect.pl"
                                 (string-append target "/edirect.pl"))
                      #t)))
         (add-after
          'install 'wrap-program
          (lambda* (#:key inputs outputs #:allow-other-keys)
            ;; Make sure 'edirect.pl' finds all perl inputs at runtime.
            (let* ((out (assoc-ref outputs "out"))
                   (path (getenv "PERL5LIB")))
              (wrap-program (string-append out "/bin/edirect.pl")
                `("PERL5LIB" ":" prefix (,path)))))))))
    (inputs
     `(("perl-html-parser" ,perl-html-parser)
       ("perl-encode-locale" ,perl-encode-locale)
       ("perl-file-listing" ,perl-file-listing)
       ("perl-html-tagset" ,perl-html-tagset)
       ("perl-html-tree" ,perl-html-tree)
       ("perl-http-cookies" ,perl-http-cookies)
       ("perl-http-date" ,perl-http-date)
       ("perl-http-message" ,perl-http-message)
       ("perl-http-negotiate" ,perl-http-negotiate)
       ("perl-lwp-mediatypes" ,perl-lwp-mediatypes)
       ("perl-lwp-protocol-https" ,perl-lwp-protocol-https)
       ("perl-net-http" ,perl-net-http)
       ("perl-uri" ,perl-uri)
       ("perl-www-robotrules" ,perl-www-robotrules)
       ("perl" ,perl)))
    (home-page "http://www.ncbi.nlm.nih.gov/books/NBK179288/")
    (synopsis "Tools for accessing the NCBI's set of databases")
    (description
     "Entrez Direct (EDirect) is a method for accessing the National Center
for Biotechnology Information's (NCBI) set of interconnected
databases (publication, sequence, structure, gene, variation, expression,
etc.) from a terminal.  Functions take search terms from command-line
arguments.  Individual operations are combined to build multi-step queries.
Record retrieval and formatting normally complete the process.

EDirect also provides an argument-driven function that simplifies the
extraction of data from document summaries or other results that are returned
in structured XML format.  This can eliminate the need for writing custom
software to answer ad hoc questions.")
    (license license:public-domain)))

(define-public express
  (package
    (name "express")
    (version "1.5.1")
    (source (origin
              (method url-fetch)
              (uri
               (string-append
                "http://bio.math.berkeley.edu/eXpress/downloads/express-"
                version "/express-" version "-src.tgz"))
              (sha256
               (base32
                "03rczxd0gjp2l1jxcmjfmf5j94j77zqyxa6x063zsc585nj40n0c"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f ;no "check" target
       #:phases
       (alist-cons-after
        'unpack 'use-shared-boost-libs-and-set-bamtools-paths
        (lambda* (#:key inputs #:allow-other-keys)
          (substitute* "CMakeLists.txt"
            (("set\\(Boost_USE_STATIC_LIBS ON\\)")
             "set(Boost_USE_STATIC_LIBS OFF)")
            (("\\$\\{CMAKE_CURRENT_SOURCE_DIR\\}/bamtools/include")
             (string-append (assoc-ref inputs "bamtools") "/include/bamtools")))
          (substitute* "src/CMakeLists.txt"
            (("\\$\\{CMAKE_CURRENT_SOURCE_DIR\\}/\\.\\./bamtools/lib")
             (string-append (assoc-ref inputs "bamtools") "/lib/bamtools")))
          #t)
        %standard-phases)))
    (inputs
     `(("boost" ,boost)
       ("bamtools" ,bamtools)
       ("protobuf" ,protobuf)
       ("zlib" ,zlib)))
    (home-page "http://bio.math.berkeley.edu/eXpress")
    (synopsis "Streaming quantification for high-throughput genomic sequencing")
    (description
     "eXpress is a streaming tool for quantifying the abundances of a set of
target sequences from sampled subsequences.  Example applications include
transcript-level RNA-Seq quantification, allele-specific/haplotype expression
analysis (from RNA-Seq), transcription factor binding quantification in
ChIP-Seq, and analysis of metagenomic data.")
    (license license:artistic2.0)))

(define-public express-beta-diversity
  (package
   (name "express-beta-diversity")
   (version "1.0.7")
   (source (origin
             (method url-fetch)
             (uri
              (string-append
               "https://github.com/dparks1134/ExpressBetaDiversity/archive/v"
               version ".tar.gz"))
             (file-name (string-append name "-" version ".tar.gz"))
             (sha256
              (base32
               "1djvdlmqvjf6h0zq7w36y8cl5cli6rgj86x65znl48agnwmzxfxr"))))
   (build-system gnu-build-system)
   (arguments
    `(#:phases
      (modify-phases %standard-phases
        (delete 'configure)
        (add-before 'build 'enter-source (lambda _ (chdir "source") #t))
        (replace 'check
                 (lambda _ (zero? (system* "../bin/ExpressBetaDiversity"
                                           "-u"))))
        (add-after 'check 'exit-source (lambda _ (chdir "..") #t))
        (replace 'install
                 (lambda* (#:key outputs #:allow-other-keys)
                   (let ((bin (string-append (assoc-ref outputs "out")
                                             "/bin")))
                     (mkdir-p bin)
                     (copy-file "scripts/convertToEBD.py"
                                (string-append bin "/convertToEBD.py"))
                     (copy-file "bin/ExpressBetaDiversity"
                                (string-append bin "/ExpressBetaDiversity"))
                     #t))))))
   (inputs
    `(("python" ,python-2)))
   (home-page "http://kiwi.cs.dal.ca/Software/ExpressBetaDiversity")
   (synopsis "Taxon- and phylogenetic-based beta diversity measures")
   (description
    "Express Beta Diversity (EBD) calculates ecological beta diversity
(dissimilarity) measures between biological communities.  EBD implements a
variety of diversity measures including those that make use of phylogenetic
similarity of community members.")
   (license license:gpl3+)))

(define-public fasttree
  (package
   (name "fasttree")
   (version "2.1.8")
   (source (origin
             (method url-fetch)
             (uri (string-append
                   "http://www.microbesonline.org/fasttree/FastTree-"
                   version ".c"))
             (sha256
              (base32
               "0dzqc9vr9iiiw21y159xfjl2z90vw0y7r4x6456pcaxiy5hd2wmi"))))
   (build-system gnu-build-system)
   (arguments
    `(#:tests? #f ; no "check" target
      #:phases
      (modify-phases %standard-phases
        (delete 'unpack)
        (delete 'configure)
        (replace 'build
                 (lambda* (#:key source #:allow-other-keys)
                   (and (zero? (system* "gcc"
                                        "-O3"
                                        "-finline-functions"
                                        "-funroll-loops"
                                        "-Wall"
                                        "-o"
                                        "FastTree"
                                        source
                                        "-lm"))
                        (zero? (system* "gcc"
                                        "-DOPENMP"
                                        "-fopenmp"
                                        "-O3"
                                        "-finline-functions"
                                        "-funroll-loops"
                                        "-Wall"
                                        "-o"
                                        "FastTreeMP"
                                        source
                                        "-lm")))))
        (replace 'install
                 (lambda* (#:key outputs #:allow-other-keys)
                   (let ((bin (string-append (assoc-ref outputs "out")
                                             "/bin")))
                     (mkdir-p bin)
                     (copy-file "FastTree"
                                (string-append bin "/FastTree"))
                     (copy-file "FastTreeMP"
                                (string-append bin "/FastTreeMP"))
                     #t))))))
   (home-page "http://www.microbesonline.org/fasttree")
   (synopsis "Infers approximately-maximum-likelihood phylogenetic trees")
   (description
    "FastTree can handle alignments with up to a million of sequences in a
reasonable amount of time and memory.  For large alignments, FastTree is
100-1,000 times faster than PhyML 3.0 or RAxML 7.")
   (license license:gpl2+)))

(define-public fastx-toolkit
  (package
    (name "fastx-toolkit")
    (version "0.0.14")
    (source (origin
              (method url-fetch)
              (uri
               (string-append
                "https://github.com/agordon/fastx_toolkit/releases/download/"
                version "/fastx_toolkit-" version ".tar.bz2"))
              (sha256
               (base32
                "01jqzw386873sr0pjp1wr4rn8fsga2vxs1qfmicvx1pjr72007wy"))))
    (build-system gnu-build-system)
    (inputs
     `(("libgtextutils" ,libgtextutils)))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (home-page "http://hannonlab.cshl.edu/fastx_toolkit/")
    (synopsis "Tools for FASTA/FASTQ file preprocessing")
    (description
     "The FASTX-Toolkit is a collection of command line tools for Short-Reads
FASTA/FASTQ files preprocessing.

Next-Generation sequencing machines usually produce FASTA or FASTQ files,
containing multiple short-reads sequences.  The main processing of such
FASTA/FASTQ files is mapping the sequences to reference genomes.  However, it
is sometimes more productive to preprocess the files before mapping the
sequences to the genome---manipulating the sequences to produce better mapping
results.  The FASTX-Toolkit tools perform some of these preprocessing tasks.")
    (license license:agpl3+)))

(define-public flexbar
  (package
    (name "flexbar")
    (version "2.5")
    (source (origin
              (method url-fetch)
              (uri
               (string-append "mirror://sourceforge/flexbar/"
                              version "/flexbar_v" version "_src.tgz"))
              (sha256
               (base32
                "13jaykc3y1x8y5nn9j8ljnb79s5y51kyxz46hdmvvjj6qhyympmf"))))
    (build-system cmake-build-system)
    (arguments
     `(#:configure-flags (list
                          (string-append "-DFLEXBAR_BINARY_DIR="
                                         (assoc-ref %outputs "out")
                                         "/bin/"))
       #:phases
       (alist-replace
        'check
        (lambda* (#:key outputs #:allow-other-keys)
          (setenv "PATH" (string-append
                          (assoc-ref outputs "out") "/bin:"
                          (getenv "PATH")))
          (chdir "../flexbar_v2.5_src/test")
          (zero? (system* "bash" "flexbar_validate.sh")))
        (alist-delete 'install %standard-phases))))
    (inputs
     `(("tbb" ,tbb)
       ("zlib" ,zlib)))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("seqan" ,seqan)))
    (home-page "http://flexbar.sourceforge.net")
    (synopsis "Barcode and adapter removal tool for sequencing platforms")
    (description
     "Flexbar preprocesses high-throughput nucleotide sequencing data
efficiently.  It demultiplexes barcoded runs and removes adapter sequences.
Moreover, trimming and filtering features are provided.  Flexbar increases
read mapping rates and improves genome and transcriptome assemblies.  It
supports next-generation sequencing data in fasta/q and csfasta/q format from
Illumina, Roche 454, and the SOLiD platform.")
    (license license:gpl3)))

(define-public fraggenescan
  (package
    (name "fraggenescan")
    (version "1.20")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append "mirror://sourceforge/fraggenescan/"
                       "FragGeneScan" version ".tar.gz"))
       (sha256
        (base32 "1zzigqmvqvjyqv4945kv6nc5ah2xxm1nxgrlsnbzav3f5c0n0pyj"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (add-before 'build 'patch-paths
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (string-append (assoc-ref outputs "out")))
                    (share (string-append out "/share/fraggenescan/")))
               (substitute* "run_FragGeneScan.pl"
                 (("system\\(\"rm")
                  (string-append "system(\"" (which "rm")))
                 (("system\\(\"mv")
                  (string-append "system(\"" (which "mv")))
                 ;; This script and other programs expect the training files
                 ;; to be in the non-standard location bin/train/XXX. Change
                 ;; this to be share/fraggenescan/train/XXX instead.
                 (("^\\$train.file = \\$dir.*")
                  (string-append "$train_file = \""
                                 share
                                 "train/\".$FGS_train_file;")))
               (substitute* "run_hmm.c"
                 (("^  strcat\\(train_dir, \\\"train/\\\"\\);")
                  (string-append "  strcpy(train_dir, \"" share "/train/\");")))
               (substitute* "post_process.pl"
                 (("^my \\$dir = substr.*")
                  (string-append "my $dir = \"" share "\";"))))
             #t))
         (replace 'build
           (lambda _ (and (zero? (system* "make" "clean"))
                          (zero? (system* "make" "fgs")))))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (string-append (assoc-ref outputs "out")))
                    (bin (string-append out "/bin/"))
                    (share (string-append out "/share/fraggenescan/train")))
               (install-file "run_FragGeneScan.pl" bin)
               (install-file "FragGeneScan" bin)
               (install-file "FGS_gff.py" bin)
               (install-file "post_process.pl" bin)
               (copy-recursively "train" share))))
         (delete 'check)
         (add-after 'install 'post-install-check
           ;; In lieu of 'make check', run one of the examples and check the
           ;; output files gets created.
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (string-append (assoc-ref outputs "out")))
                    (bin (string-append out "/bin/")))
               (and (zero? (system* (string-append bin "run_FragGeneScan.pl")
                             "-genome=./example/NC_000913.fna"
                             "-out=./test2"
                             "-complete=1"
                             "-train=complete"))
                    (file-exists? "test2.faa")
                    (file-exists? "test2.ffn")
                    (file-exists? "test2.gff")
                    (file-exists? "test2.out"))))))))
    (inputs
     `(("perl" ,perl)
       ("python" ,python-2))) ;not compatible with python 3.
    (home-page "https://sourceforge.net/projects/fraggenescan/")
    (synopsis "Finds potentially fragmented genes in short reads")
    (description
     "FragGeneScan is a program for predicting bacterial and archaeal genes in
short and error-prone DNA sequencing reads.  It can also be applied to predict
genes in incomplete assemblies or complete genomes.")
    ;; GPL3+ according to private correspondense with the authors.
    (license license:gpl3+)))

(define-public fxtract
  (let ((util-commit "776ca85a18a47492af3794745efcb4a905113115"))
    (package
      (name "fxtract")
      (version "2.3")
      (source
       (origin
         (method url-fetch)
         (uri (string-append
               "https://github.com/ctSkennerton/fxtract/archive/"
               version ".tar.gz"))
         (file-name (string-append "ctstennerton-util-"
                                   (string-take util-commit 7)
                                   "-checkout"))
         (sha256
          (base32
           "0275cfdhis8517hm01is62062swmi06fxzifq7mr3knbbxjlaiwj"))))
      (build-system gnu-build-system)
      (arguments
       `(#:make-flags (list
                       (string-append "PREFIX=" (assoc-ref %outputs "out"))
                       "CC=gcc")
         #:test-target "fxtract_test"
         #:phases
         (modify-phases %standard-phases
           (delete 'configure)
           (add-before 'build 'copy-util
             (lambda* (#:key inputs #:allow-other-keys)
               (rmdir "util")
               (copy-recursively (assoc-ref inputs "ctskennerton-util") "util")
               #t))
           ;; Do not use make install as this requires additional dependencies.
           (replace 'install
             (lambda* (#:key outputs #:allow-other-keys)
               (let* ((out (assoc-ref outputs "out"))
                      (bin (string-append out"/bin")))
                 (install-file "fxtract" bin)
                 #t))))))
      (inputs
       `(("pcre" ,pcre)
         ("zlib" ,zlib)))
      (native-inputs
       ;; ctskennerton-util is licensed under GPL2.
       `(("ctskennerton-util"
          ,(origin
             (method git-fetch)
             (uri (git-reference
                   (url "https://github.com/ctSkennerton/util.git")
                   (commit util-commit)))
             (file-name (string-append
                         "ctstennerton-util-" util-commit "-checkout"))
             (sha256
              (base32
               "0cls1hd4vgj3f36fpzzg4xc77d6f3hpc60cbpfmn2gdr7ykzzad7"))))))
      (home-page "https://github.com/ctSkennerton/fxtract")
      (synopsis "Extract sequences from FASTA and FASTQ files")
      (description
       "Fxtract extracts sequences from a protein or nucleotide fastx (FASTA
or FASTQ) file given a subsequence.  It uses a simple substring search for
basic tasks but can change to using POSIX regular expressions, PCRE, hash
lookups or multi-pattern searching as required.  By default fxtract looks in
the sequence of each record but can also be told to look in the header,
comment or quality sections.")
      (license license:expat))))

(define-public grit
  (package
    (name "grit")
    (version "2.0.2")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/nboley/grit/archive/"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "157in84dj70wimbind3x7sy1whs3h57qfgcnj2s6lrd38fbrb7mj"))))
    (build-system python-build-system)
    (arguments
     `(#:python ,python-2
       #:phases
       (alist-cons-after
        'unpack 'generate-from-cython-sources
        (lambda* (#:key inputs outputs #:allow-other-keys)
          ;; Delete these C files to force fresh generation from pyx sources.
          (delete-file "grit/sparsify_support_fns.c")
          (delete-file "grit/call_peaks_support_fns.c")
          (substitute* "setup.py"
            (("Cython.Setup") "Cython.Build")
            ;; Add numpy include path to fix compilation
            (("pyx\", \\]")
             (string-append "pyx\", ], include_dirs = ['"
                            (assoc-ref inputs "python-numpy")
                            "/lib/python2.7/site-packages/numpy/core/include/"
                            "']"))) #t)
        %standard-phases)))
    (inputs
     `(("python-scipy" ,python2-scipy)
       ("python-numpy" ,python2-numpy)
       ("python-pysam" ,python2-pysam)
       ("python-networkx" ,python2-networkx)))
    (native-inputs
     `(("python-cython" ,python2-cython)
       ("python-setuptools" ,python2-setuptools)))
    (home-page "http://grit-bio.org")
    (synopsis "Tool for integrative analysis of RNA-seq type assays")
    (description
     "GRIT is designed to use RNA-seq, TES, and TSS data to build and quantify
full length transcript models.  When none of these data sources are available,
GRIT can be run by providing a candidate set of TES or TSS sites.  In
addition, GRIT can merge in reference junctions and gene boundaries.  GRIT can
also be run in quantification mode, where it uses a provided GTF file and just
estimates transcript expression.")
    (license license:gpl3+)))

(define-public hisat
  (package
    (name "hisat")
    (version "0.1.4")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://ccb.jhu.edu/software/hisat/downloads/hisat-"
                    version "-beta-source.zip"))
              (sha256
               (base32
                "1k381ydranqxp09yf2y7w1d0chz5d59vb6jchi89hbb0prq19lk5"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ;no check target
       #:make-flags '("allall"
                      ;; Disable unsupported `popcnt' instructions on
                      ;; architectures other than x86_64
                      ,@(if (string-prefix? "x86_64"
                                            (or (%current-target-system)
                                                (%current-system)))
                            '()
                            '("POPCNT_CAPABILITY=0")))
       #:phases
       (alist-cons-after
        'unpack 'patch-sources
        (lambda _
          ;; XXX Cannot use snippet because zip files are not supported
          (substitute* "Makefile"
            (("^CC = .*$") "CC = gcc")
            (("^CPP = .*$") "CPP = g++")
            ;; replace BUILD_HOST and BUILD_TIME for deterministic build
            (("-DBUILD_HOST=.*") "-DBUILD_HOST=\"\\\"guix\\\"\"")
            (("-DBUILD_TIME=.*") "-DBUILD_TIME=\"\\\"0\\\"\""))
          (substitute* '("hisat-build" "hisat-inspect")
            (("/usr/bin/env") (which "env"))))
        (alist-replace
         'install
         (lambda* (#:key outputs #:allow-other-keys)
           (let ((bin (string-append (assoc-ref outputs "out") "/bi/")))
             (for-each (lambda (file)
                         (install-file file bin))
                       (find-files
                        "."
                        "hisat(-(build|align|inspect)(-(s|l)(-debug)*)*)*$"))))
         (alist-delete 'configure %standard-phases)))))
    (native-inputs
     `(("unzip" ,unzip)))
    (inputs
     `(("perl" ,perl)
       ("python" ,python)
       ("zlib" ,zlib)))
    ;; Non-portable SSE instructions are used so building fails on platforms
    ;; other than x86_64.
    (supported-systems '("x86_64-linux"))
    (home-page "http://ccb.jhu.edu/software/hisat/index.shtml")
    (synopsis "Hierarchical indexing for spliced alignment of transcripts")
    (description
     "HISAT is a fast and sensitive spliced alignment program for mapping
RNA-seq reads.  In addition to one global FM index that represents a whole
genome, HISAT uses a large set of small FM indexes that collectively cover the
whole genome.  These small indexes (called local indexes) combined with
several alignment strategies enable effective alignment of RNA-seq reads, in
particular, reads spanning multiple exons.")
    (license license:gpl3+)))

(define-public hmmer
  (package
    (name "hmmer")
    (version "3.1b2")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://selab.janelia.org/software/hmmer"
                    (version-prefix version 1) "/"
                    version "/hmmer-" version ".tar.gz"))
              (sha256
               (base32
                "0djmgc0pfli0jilfx8hql1axhwhqxqb8rxg2r5rg07aw73sfs5nx"))))
    (build-system gnu-build-system)
    (native-inputs `(("perl" ,perl)))
    (home-page "http://hmmer.janelia.org")
    (synopsis "Biosequence analysis using profile hidden Markov models")
    (description
     "HMMER is used for searching sequence databases for homologs of protein
sequences, and for making protein sequence alignments.  It implements methods
using probabilistic models called profile hidden Markov models (profile
HMMs).")
    (license (list license:gpl3+
                   ;; The bundled library 'easel' is distributed
                   ;; under The Janelia Farm Software License.
                   (license:non-copyleft
                    "file://easel/LICENSE"
                    "See easel/LICENSE in the distribution.")))))

(define-public htseq
  (package
    (name "htseq")
    (version "0.6.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://pypi.python.org/packages/source/H/HTSeq/HTSeq-"
                    version ".tar.gz"))
              (sha256
               (base32
                "1i85ppf2j2lj12m0x690qq5nn17xxk23pbbx2c83r8ayb5wngzwv"))))
    (build-system python-build-system)
    (arguments `(#:python ,python-2)) ; only Python 2 is supported
    ;; Numpy needs to be propagated when htseq is used as a Python library.
    (propagated-inputs
     `(("python-numpy" ,python2-numpy)))
    (inputs
     `(("python-pysam" ,python2-pysam)))
    (native-inputs
     `(("python-setuptools" ,python2-setuptools)))
    (home-page "http://www-huber.embl.de/users/anders/HTSeq/")
    (synopsis "Analysing high-throughput sequencing data with Python")
    (description
     "HTSeq is a Python package that provides infrastructure to process data
from high-throughput sequencing assays.")
    (license license:gpl3+)))

(define-public htsjdk
  (package
    (name "htsjdk")
    (version "1.129")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/samtools/htsjdk/archive/"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "0asdk9b8jx2ij7yd6apg9qx03li8q7z3ml0qy2r2qczkra79y6fw"))
              (modules '((guix build utils)))
              ;; remove build dependency on git
              (snippet '(substitute* "build.xml"
                          (("failifexecutionfails=\"true\"")
                           "failifexecutionfails=\"false\"")))))
    (build-system gnu-build-system)
    (arguments
     `(#:modules ((srfi srfi-1)
                  (guix build gnu-build-system)
                  (guix build utils))
       #:phases (alist-replace
                 'build
                 (lambda _
                   (setenv "JAVA_HOME" (assoc-ref %build-inputs "jdk"))
                   (zero? (system* "ant" "all"
                                   (string-append "-Ddist="
                                                  (assoc-ref %outputs "out")
                                                  "/share/java/htsjdk/"))))
                 (fold alist-delete %standard-phases
                       '(configure install check)))))
    (native-inputs
     `(("ant" ,ant)
       ("jdk" ,icedtea "jdk")))
    (home-page "http://samtools.github.io/htsjdk/")
    (synopsis "Java API for high-throughput sequencing data (HTS) formats")
    (description
     "HTSJDK is an implementation of a unified Java library for accessing
common file formats, such as SAM and VCF, used for high-throughput
sequencing (HTS) data.  There are also an number of useful utilities for
manipulating HTS data.")
    (license license:expat)))

(define-public htslib
  (package
    (name "htslib")
    (version "1.2.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/samtools/htslib/releases/download/"
                    version "/htslib-" version ".tar.bz2"))
              (sha256
               (base32
                "1c32ssscbnjwfw3dra140fq7riarp2x990qxybh34nr1p5r17nxx"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after
          'unpack 'patch-tests
          (lambda _
            (substitute* "test/test.pl"
              (("/bin/bash") (which "bash")))
            #t)))))
    (inputs
     `(("zlib" ,zlib)))
    (native-inputs
     `(("perl" ,perl)))
    (home-page "http://www.htslib.org")
    (synopsis "C library for reading/writing high-throughput sequencing data")
    (description
     "HTSlib is a C library for reading/writing high-throughput sequencing
data.  It also provides the bgzip, htsfile, and tabix utilities.")
    ;; Files under cram/ are released under the modified BSD license;
    ;; the rest is released under the Expat license
    (license (list license:expat license:bsd-3))))

(define-public idr
  (package
    (name "idr")
    (version "2.0.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/nboley/idr/archive/"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1k3x44biak00aiv3hpm1yd6nn4hhp7n0qnbs3zh2q9sw7qr1qj5r"))))
    (build-system python-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after
          'install 'wrap-program
          (lambda* (#:key inputs outputs #:allow-other-keys)
            (let* ((out (assoc-ref outputs "out"))
                   (python-version (string-take (string-take-right
                                                 (assoc-ref inputs "python") 5) 3))
                   (path (string-join
                          (map (lambda (name)
                                 (string-append (assoc-ref inputs name)
                                                "/lib/python" python-version
                                                "/site-packages"))
                               '("python-scipy"
                                 "python-numpy"
                                 "python-matplotlib"))
                          ":")))
              (wrap-program (string-append out "/bin/idr")
                `("PYTHONPATH" ":" prefix (,path))))
            #t)))))
    (inputs
     `(("python-scipy" ,python-scipy)
       ("python-numpy" ,python-numpy)
       ("python-matplotlib" ,python-matplotlib)))
    (native-inputs
     `(("python-cython" ,python-cython)
       ("python-setuptools" ,python-setuptools)))
    (home-page "https://github.com/nboley/idr")
    (synopsis "Tool to measure the irreproducible discovery rate (IDR)")
    (description
     "The IDR (Irreproducible Discovery Rate) framework is a unified approach
to measure the reproducibility of findings identified from replicate
experiments and provide highly stable thresholds based on reproducibility.")
    (license license:gpl3+)))

(define-public jellyfish
  (package
    (name "jellyfish")
    (version "2.2.4")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/gmarcais/Jellyfish/"
                                  "releases/download/v" version
                                  "/jellyfish-" version ".tar.gz"))
              (sha256
               (base32
                "0a6xnynqy2ibfbfz86b9g2m2dgm7f1469pmymkpam333gi3p26nk"))))
    (build-system gnu-build-system)
    (outputs '("out"      ;for library
               "ruby"     ;for Ruby bindings
               "python")) ;for Python bindings
    (arguments
     `(#:configure-flags
       (list (string-append "--enable-ruby-binding="
                            (assoc-ref %outputs "ruby"))
             (string-append "--enable-python-binding="
                            (assoc-ref %outputs "python")))
       #:phases
       (modify-phases %standard-phases
         (add-before 'check 'set-SHELL-variable
           (lambda _
             ;; generator_manager.hpp either uses /bin/sh or $SHELL
             ;; to run tests.
             (setenv "SHELL" (which "bash"))
             #t)))))
    (native-inputs
     `(("bc" ,bc)
       ("time" ,time)
       ("ruby" ,ruby)
       ("python" ,python-2)))
    (synopsis "Tool for fast counting of k-mers in DNA")
    (description
     "Jellyfish is a tool for fast, memory-efficient counting of k-mers in
DNA.  A k-mer is a substring of length k, and counting the occurrences of all
such substrings is a central step in many analyses of DNA sequence.  Jellyfish
is a command-line program that reads FASTA and multi-FASTA files containing
DNA sequences.  It outputs its k-mer counts in a binary format, which can be
translated into a human-readable text format using the @code{jellyfish dump}
command, or queried for specific k-mers with @code{jellyfish query}.")
    (home-page "http://www.genome.umd.edu/jellyfish.html")
    ;; The combined work is published under the GPLv3 or later.  Individual
    ;; files such as lib/jsoncpp.cpp are released under the Expat license.
    (license (list license:gpl3+ license:expat))))

(define-public macs
  (package
    (name "macs")
    (version "2.1.0.20151222")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "MACS2" version))
              (sha256
               (base32
                "1r2hcz6irhcq7lwbafjks98jbn34hv05avgbdjnp6w6mlfjkf8x5"))))
    (build-system python-build-system)
    (arguments
     `(#:python ,python-2 ; only compatible with Python 2.7
       #:tests? #f)) ; no test target
    (inputs
     `(("python-numpy" ,python2-numpy)))
    (native-inputs
     `(("python-setuptools" ,python2-setuptools)))
    (home-page "http://github.com/taoliu/MACS/")
    (synopsis "Model based analysis for ChIP-Seq data")
    (description
     "MACS is an implementation of a ChIP-Seq analysis algorithm for
identifying transcript factor binding sites named Model-based Analysis of
ChIP-Seq (MACS).  MACS captures the influence of genome complexity to evaluate
the significance of enriched ChIP regions and it improves the spatial
resolution of binding sites through combining the information of both
sequencing tag position and orientation.")
    (license license:bsd-3)))

(define-public mafft
  (package
    (name "mafft")
    (version "7.267")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://mafft.cbrc.jp/alignment/software/mafft-" version
                    "-without-extensions-src.tgz"))
              (file-name (string-append name "-" version ".tgz"))
              (sha256
               (base32
                "1xl6xq1rfxkws0svrlhyqxhhwbv6r77jwblsdpcyiwzsscw6wlk0"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ; no automated tests, though there are tests in the read me
       #:make-flags (let ((out (assoc-ref %outputs "out")))
                      (list (string-append "PREFIX=" out)
                            (string-append "BINDIR="
                                           (string-append out "/bin"))))
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'enter-dir
          (lambda _ (chdir "core") #t))
         (add-after 'enter-dir 'patch-makefile
          (lambda _
            ;; on advice from the MAFFT authors, there is no need to
            ;; distribute mafft-profile, mafft-distance, or
            ;; mafft-homologs.rb as they are too "specialised".
            (substitute* "Makefile"
              ;; remove mafft-homologs.rb from SCRIPTS
              (("^SCRIPTS = mafft mafft-homologs.rb")
               "SCRIPTS = mafft")
              ;; remove mafft-homologs from MANPAGES
              (("^MANPAGES = mafft.1 mafft-homologs.1")
               "MANPAGES = mafft.1")
              ;; remove mafft-distance from PROGS
              (("^PROGS = dvtditr dndfast7 dndblast sextet5 mafft-distance")
               "PROGS = dvtditr dndfast7 dndblast sextet5")
              ;; remove mafft-profile from PROGS
              (("splittbfast disttbfast tbfast mafft-profile 2cl mccaskillwrap")
               "splittbfast disttbfast tbfast f2cl mccaskillwrap")
              (("^rm -f mafft-profile mafft-profile.exe") "#")
              (("^rm -f mafft-distance mafft-distance.exe") ")#")
              ;; do not install MAN pages in libexec folder
              (("^\t\\$\\(INSTALL\\) -m 644 \\$\\(MANPAGES\\) \
\\$\\(DESTDIR\\)\\$\\(LIBDIR\\)") "#"))
            #t))
         (add-after 'enter-dir 'patch-paths
           (lambda* (#:key inputs #:allow-other-keys)
             (substitute* '("pairash.c"
                            "mafft.tmpl")
               (("perl") (which "perl"))
               (("([\"`| ])awk" _ prefix)
                (string-append prefix (which "awk")))
               (("grep") (which "grep")))
             #t))
         (delete 'configure))))
    (inputs
     `(("perl" ,perl)
       ("gawk" ,gawk)
       ("grep" ,grep)))
    (propagated-inputs
     `(("coreutils" ,coreutils)))
    (home-page "http://mafft.cbrc.jp/alignment/software/")
    (synopsis "Multiple sequence alignment program")
    (description
     "MAFFT offers a range of multiple alignment methods for nucleotide and
protein sequences.  For instance, it offers L-INS-i (accurate; for alignment
of <~200 sequences) and FFT-NS-2 (fast; for alignment of <~30,000
sequences).")
    (license (license:non-copyleft
              "http://mafft.cbrc.jp/alignment/software/license.txt"
              "BSD-3 with different formatting"))))

(define-public metabat
  (package
    (name "metabat")
    (version "0.26.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://bitbucket.org/berkeleylab/metabat/get/"
                    version ".tar.bz2"))
              (file-name (string-append name "-" version ".tar.bz2"))
              (sha256
               (base32
                "0vgrhbaxg4dkxyax2kbigak7w0arhqvw0szwp6gd9wmyilc44kfa"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-includes
                    (lambda _
                      (substitute* "SConstruct"
                        (("/include/bam/bam.h")
                         "/include/samtools/bam.h"))
                      (substitute* "src/BamUtils.h"
                        (("^#include \"bam/bam\\.h\"")
                         "#include \"samtools/bam.h\"")
                        (("^#include \"bam/sam\\.h\"")
                         "#include \"samtools/sam.h\""))
                      (substitute* "src/KseqReader.h"
                        (("^#include \"bam/kseq\\.h\"")
                         "#include \"samtools/kseq.h\""))
                      #t))
         (add-after 'unpack 'fix-scons
                    (lambda _
                      (substitute* "SConstruct" ; Do not distribute README
                        (("^env\\.Install\\(idir_prefix, 'README\\.md'\\)")
                         ""))
                      #t))
         (delete 'configure)
         (replace 'build
                  (lambda* (#:key inputs outputs #:allow-other-keys)
                    (mkdir (assoc-ref outputs "out"))
                    (zero? (system* "scons"
                                    (string-append
                                     "PREFIX="
                                     (assoc-ref outputs "out"))
                                    (string-append
                                     "HTSLIB_DIR="
                                     (assoc-ref inputs "htslib"))
                                    (string-append
                                     "SAMTOOLS_DIR="
                                     (assoc-ref inputs "samtools"))
                                    (string-append
                                     "BOOST_ROOT="
                                     (assoc-ref inputs "boost"))
                                    "install"))))
         ;; check and install carried out during build phase
         (delete 'check)
         (delete 'install))))
    (inputs
     `(("zlib" ,zlib)
       ("perl" ,perl)
       ("samtools" ,samtools)
       ("htslib" ,htslib)
       ("boost" ,boost)))
    (native-inputs
     `(("scons" ,scons)))
    (home-page "https://bitbucket.org/berkeleylab/metabat")
    (synopsis
     "Reconstruction of single genomes from complex microbial communities")
    (description
     "Grouping large genomic fragments assembled from shotgun metagenomic
sequences to deconvolute complex microbial communities, or metagenome binning,
enables the study of individual organisms and their interactions.  MetaBAT is
an automated metagenome binning software, which integrates empirical
probabilistic distances of genome abundance and tetranucleotide frequency.")
   (license (license:non-copyleft "file://license.txt"
                                  "See license.txt in the distribution."))))

(define-public miso
  (package
    (name "miso")
    (version "0.5.3")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://pypi.python.org/packages/source/m/misopy/misopy-"
                    version ".tar.gz"))
              (sha256
               (base32
                "0x446867az8ir0z8c1vjqffkp0ma37wm4sylixnkhgawllzx8v5w"))
              (modules '((guix build utils)))
              (snippet
               '(substitute* "setup.py"
                  ;; Use setuptools, or else the executables are not
                  ;; installed.
                  (("distutils.core") "setuptools")
                  ;; use "gcc" instead of "cc" for compilation
                  (("^defines")
                   "cc.set_executables(
compiler='gcc',
compiler_so='gcc',
linker_exe='gcc',
linker_so='gcc -shared'); defines")))))
    (build-system python-build-system)
    (arguments
     `(#:python ,python-2 ; only Python 2 is supported
       #:tests? #f)) ; no "test" target
    (inputs
     `(("samtools" ,samtools)
       ("python-numpy" ,python2-numpy)
       ("python-pysam" ,python2-pysam)
       ("python-scipy" ,python2-scipy)
       ("python-matplotlib" ,python2-matplotlib)))
    (native-inputs
     `(("python-mock" ,python2-mock) ;for tests
       ("python-pytz" ,python2-pytz) ;for tests
       ("python-setuptools" ,python2-setuptools)))
    (home-page "http://genes.mit.edu/burgelab/miso/index.html")
    (synopsis "Mixture of Isoforms model for RNA-Seq isoform quantitation")
    (description
     "MISO (Mixture-of-Isoforms) is a probabilistic framework that quantitates
the expression level of alternatively spliced genes from RNA-Seq data, and
identifies differentially regulated isoforms or exons across samples.  By
modeling the generative process by which reads are produced from isoforms in
RNA-Seq, the MISO model uses Bayesian inference to compute the probability
that a read originated from a particular isoform.")
    (license license:gpl2)))

(define-public orfm
  (package
    (name "orfm")
    (version "0.5.3")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/wwood/OrfM/releases/download/v"
                    version "/orfm-" version ".tar.gz"))
              (sha256
               (base32
                "0vb6d771gl4mix8bwx919x5ayy9pkj44n7ki336nz3rz2rx4c7gk"))))
    (build-system gnu-build-system)
    (inputs `(("zlib" ,zlib)))
    (native-inputs
     `(("ruby-bio-commandeer" ,ruby-bio-commandeer)
       ("ruby-rspec" ,ruby-rspec)
       ("ruby" ,ruby)))
    (synopsis "Simple and not slow open reading frame (ORF) caller")
    (description
     "An ORF caller finds stretches of DNA that, when translated, are not
interrupted by stop codons.  OrfM finds and prints these ORFs.")
    (home-page "https://github.com/wwood/OrfM")
    (license license:lgpl3+)))

(define-public python2-pbcore
  (package
    (name "python2-pbcore")
    (version "0.9.3")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/PacificBiosciences/pbcore/archive/"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1z46rwjac93jm87cbj2zgjg6qvsgs65140wkbbxsvxps7ai4pm09"))))
    (build-system python-build-system)
    (arguments `(#:python ,python-2)) ; pbcore requires Python 2.7
    (inputs
     `(("python-cython" ,python2-cython)
       ("python-numpy" ,python2-numpy)
       ("python-pysam" ,python2-pysam)
       ("python-h5py" ,python2-h5py)))
    (native-inputs
     `(("python-setuptools" ,python2-setuptools)))
    (home-page "http://pacificbiosciences.github.io/pbcore/")
    (synopsis "Library for reading and writing PacBio data files")
    (description
     "The pbcore package provides Python APIs for interacting with PacBio data
files and writing bioinformatics applications.")
    (license license:bsd-3)))

(define-public python2-warpedlmm
  (package
    (name "python2-warpedlmm")
    (version "0.21")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://pypi.python.org/packages/source/W/WarpedLMM/WarpedLMM-"
             version ".zip"))
       (sha256
        (base32
         "1agfz6zqa8nc6cw47yh0s3y14gkpa9wqazwcj7mwwj3ffnw39p3j"))))
    (build-system python-build-system)
    (arguments
     `(#:python ,python-2  ; requires Python 2.7
       #:phases
       (modify-phases %standard-phases
         (add-after
          'install 'remove-bin-directory
          (lambda* (#:key outputs #:allow-other-keys)
            ;; The "bin" directory only contains wrappers for running
            ;; the module tests.  They are not needed after the
            ;; "check" phase.
            (delete-file-recursively
             (string-append (assoc-ref outputs "out") "/bin"))
            #t)))))
    (propagated-inputs
     `(("python-scipy" ,python2-scipy)
       ("python-numpy" ,python2-numpy)
       ("python-matplotlib" ,python2-matplotlib)
       ("python-fastlmm" ,python2-fastlmm)
       ("python-pandas" ,python2-pandas)
       ("python-pysnptools" ,python2-pysnptools)))
    (native-inputs
     `(("python-setuptools" ,python2-setuptools)
       ("python-mock" ,python2-mock)
       ("python-nose" ,python2-nose)
       ("unzip" ,unzip)))
    (home-page "https://github.com/PMBio/warpedLMM")
    (synopsis "Implementation of warped linear mixed models")
    (description
     "WarpedLMM is a Python implementation of the warped linear mixed model,
which automatically learns an optimal warping function (or transformation) for
the phenotype as it models the data.")
    (license license:asl2.0)))

(define-public pbtranscript-tofu
  (let ((commit "8f5467fe6"))
    (package
      (name "pbtranscript-tofu")
      (version (string-append "2.2.3." commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/PacificBiosciences/cDNA_primer.git")
                      (commit commit)))
                (file-name (string-append name "-" version "-checkout"))
                (sha256
                 (base32
                  "1lgnpi35ihay42qx0b6yl3kkgra723i413j33kvs0kvs61h82w0f"))
                (modules '((guix build utils)))
                (snippet
                 '(begin
                    ;; remove bundled Cython sources
                    (delete-file "pbtranscript-tofu/pbtranscript/Cython-0.20.1.tar.gz")
                    #t))))
      (build-system python-build-system)
      (arguments
       `(#:python ,python-2
         ;; With standard flags, the install phase attempts to create a zip'd
         ;; egg file, and fails with an error: 'ZIP does not support timestamps
         ;; before 1980'
         #:configure-flags '("--single-version-externally-managed"
                             "--record=pbtranscript-tofu.txt")
         #:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'enter-directory
            (lambda _
              (chdir "pbtranscript-tofu/pbtranscript/")
              #t))
           ;; With setuptools version 18.0 and later this setup.py hack causes
           ;; a build error, so we disable it.
           (add-after 'enter-directory 'patch-setuppy
            (lambda _
              (substitute* "setup.py"
                (("if 'setuptools.extension' in sys.modules:")
                 "if False:"))
              #t)))))
      (inputs
       `(("python-numpy" ,python2-numpy)
         ("python-bx-python" ,python2-bx-python)
         ("python-networkx" ,python2-networkx)
         ("python-scipy" ,python2-scipy)
         ("python-pbcore" ,python2-pbcore)
         ("python-h5py" ,python2-h5py)))
      (native-inputs
       `(("python-cython" ,python2-cython)
         ("python-nose" ,python2-nose)
         ("python-setuptools" ,python2-setuptools)))
      (home-page "https://github.com/PacificBiosciences/cDNA_primer")
      (synopsis "Analyze transcriptome data generated with the Iso-Seq protocol")
      (description
       "pbtranscript-tofu contains scripts to analyze transcriptome data
generated using the PacBio Iso-Seq protocol.")
      (license license:bsd-3))))

(define-public prodigal
  (package
    (name "prodigal")
    (version "2.6.3")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/hyattpd/Prodigal/archive/v"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "17srxkqd3jc77xk15pfbgg1a9xahqg7337w95mrsia7mpza4l2c9"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ;no check target
       #:make-flags (list (string-append "INSTALLDIR="
                                         (assoc-ref %outputs "out")
                                         "/bin"))
       #:phases
       (modify-phases %standard-phases
         (delete 'configure))))
    (home-page "http://prodigal.ornl.gov")
    (synopsis "Protein-coding gene prediction for Archaea and Bacteria")
    (description
     "Prodigal runs smoothly on finished genomes, draft genomes, and
metagenomes, providing gene predictions in GFF3, Genbank, or Sequin table
format.  It runs quickly, in an unsupervised fashion, handles gaps, handles
partial genes, and identifies translation initiation sites.")
    (license license:gpl3+)))

(define-public rsem
  (package
    (name "rsem")
    (version "1.2.20")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append "http://deweylab.biostat.wisc.edu/rsem/src/rsem-"
                       version ".tar.gz"))
       (sha256
        (base32 "0nzdc0j0hjllhsd5f2xli95dafm3nawskigs140xzvjk67xh0r9q"))
       (patches (list (search-patch "rsem-makefile.patch")))
       (modules '((guix build utils)))
       (snippet
        '(begin
           ;; remove bundled copy of boost
           (delete-file-recursively "boost")
           #t))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ;no "check" target
       #:phases
       (modify-phases %standard-phases
         ;; No "configure" script.
         ;; Do not build bundled samtools library.
         (replace 'configure
                  (lambda _
                    (substitute* "Makefile"
                      (("^all : sam/libbam.a") "all : "))
                    #t))
         (replace 'install
                  (lambda* (#:key outputs #:allow-other-keys)
                    (let* ((out (string-append (assoc-ref outputs "out")))
                           (bin (string-append out "/bin/"))
                           (perl (string-append out "/lib/perl5/site_perl")))
                      (mkdir-p bin)
                      (mkdir-p perl)
                      (for-each (lambda (file)
                                  (copy-file file
                                             (string-append bin (basename file))))
                                (find-files "." "rsem-.*"))
                      (copy-file "rsem_perl_utils.pm"
                                 (string-append perl "/rsem_perl_utils.pm")))
                    #t))
         (add-after
          'install 'wrap-program
          (lambda* (#:key outputs #:allow-other-keys)
            (let ((out (assoc-ref outputs "out")))
              (for-each (lambda (prog)
                          (wrap-program (string-append out "/bin/" prog)
                            `("PERL5LIB" ":" prefix
                              (,(string-append out "/lib/perl5/site_perl")))))
                        '("rsem-plot-transcript-wiggles"
                          "rsem-calculate-expression"
                          "rsem-generate-ngvector"
                          "rsem-run-ebseq"
                          "rsem-prepare-reference")))
            #t)))))
    (inputs
     `(("boost" ,boost)
       ("ncurses" ,ncurses)
       ("r" ,r)
       ("perl" ,perl)
       ("samtools" ,samtools-0.1)
       ("zlib" ,zlib)))
    (home-page "http://deweylab.biostat.wisc.edu/rsem/")
    (synopsis "Estimate gene expression levels from RNA-Seq data")
    (description
     "RSEM is a software package for estimating gene and isoform expression
levels from RNA-Seq data.  The RSEM package provides a user-friendly
interface, supports threads for parallel computation of the EM algorithm,
single-end and paired-end read data, quality scores, variable-length reads and
RSPD estimation.  In addition, it provides posterior mean and 95% credibility
interval estimates for expression levels.  For visualization, it can generate
BAM and Wiggle files in both transcript-coordinate and genomic-coordinate.")
    (license license:gpl3+)))

(define-public rseqc
  (package
    (name "rseqc")
    (version "2.6.1")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append "mirror://sourceforge/rseqc/"
                       version "/RSeQC-" version ".tar.gz"))
       (sha256
        (base32 "15ly0254yi032qzkdplg00q144qfdsd986gh62829rl5bkxhj330"))
       (modules '((guix build utils)))
       (snippet
        '(begin
           ;; remove bundled copy of pysam
           (delete-file-recursively "lib/pysam")
           (substitute* "setup.py"
             ;; remove dependency on outdated "distribute" module
             (("^from distribute_setup import use_setuptools") "")
             (("^use_setuptools\\(\\)") "")
             ;; do not use bundled copy of pysam
             (("^have_pysam = False") "have_pysam = True"))))))
    (build-system python-build-system)
    (arguments `(#:python ,python-2))
    (inputs
     `(("python-cython" ,python2-cython)
       ("python-pysam" ,python2-pysam)
       ("python-numpy" ,python2-numpy)
       ("python-setuptools" ,python2-setuptools)
       ("zlib" ,zlib)))
    (native-inputs
     `(("python-nose" ,python2-nose)))
    (home-page "http://rseqc.sourceforge.net/")
    (synopsis "RNA-seq quality control package")
    (description
     "RSeQC provides a number of modules that can comprehensively evaluate
high throughput sequence data, especially RNA-seq data.  Some basic modules
inspect sequence quality, nucleotide composition bias, PCR bias and GC bias,
while RNA-seq specific modules evaluate sequencing saturation, mapped reads
distribution, coverage uniformity, strand specificity, etc.")
    (license license:gpl3+)))

(define-public samtools
  (package
    (name "samtools")
    (version "1.3")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append "mirror://sourceforge/samtools/"
                       version "/samtools-" version ".tar.bz2"))
       (sha256
        (base32
         "03mnf0mhbfwhqlqfslrhfnw68s3g0fs1as354i9a584mqw1l1smy"))))
    (build-system gnu-build-system)
    (arguments
     `(#:modules ((ice-9 ftw)
                  (ice-9 regex)
                  (guix build gnu-build-system)
                  (guix build utils))
       #:make-flags (list (string-append "prefix=" (assoc-ref %outputs "out")))
       #:configure-flags (list "--with-ncurses")
       #:phases
       (alist-cons-after
        'unpack 'patch-tests
        (lambda _
          (substitute* "test/test.pl"
            ;; The test script calls out to /bin/bash
            (("/bin/bash") (which "bash")))
          #t)
        (alist-cons-after
         'install 'install-library
         (lambda* (#:key outputs #:allow-other-keys)
           (let ((lib (string-append (assoc-ref outputs "out") "/lib")))
             (install-file "libbam.a" lib)))
         (alist-cons-after
          'install 'install-headers
          (lambda* (#:key outputs #:allow-other-keys)
            (let ((include (string-append (assoc-ref outputs "out")
                                          "/include/samtools/")))
              (for-each (lambda (file)
                          (install-file file include))
                        (scandir "." (lambda (name) (string-match "\\.h$" name))))
              #t))
          %standard-phases)))))
    (native-inputs `(("pkg-config" ,pkg-config)))
    (inputs `(("ncurses" ,ncurses)
              ("perl" ,perl)
              ("python" ,python)
              ("zlib" ,zlib)))
    (home-page "http://samtools.sourceforge.net")
    (synopsis "Utilities to efficiently manipulate nucleotide sequence alignments")
    (description
     "Samtools implements various utilities for post-processing nucleotide
sequence alignments in the SAM, BAM, and CRAM formats, including indexing,
variant calling (in conjunction with bcftools), and a simple alignment
viewer.")
    (license license:expat)))

(define-public samtools-0.1
  ;; This is the most recent version of the 0.1 line of samtools.  The input
  ;; and output formats differ greatly from that used and produced by samtools
  ;; 1.x and is still used in many bioinformatics pipelines.
  (package (inherit samtools)
    (version "0.1.19")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append "mirror://sourceforge/samtools/"
                       version "/samtools-" version ".tar.bz2"))
       (sha256
        (base32 "1m33xsfwz0s8qi45lylagfllqg7fphf4dr0780rsvw75av9wk06h"))))
    (arguments
     `(#:tests? #f ;no "check" target
       ,@(substitute-keyword-arguments (package-arguments samtools)
           ((#:make-flags flags)
            `(cons "LIBCURSES=-lncurses" ,flags))
           ((#:phases phases)
            `(modify-phases ,phases
               (replace 'install
                 (lambda* (#:key outputs #:allow-other-keys)
                   (let ((bin (string-append
                               (assoc-ref outputs "out") "/bin")))
                     (mkdir-p bin)
                     (copy-file "samtools"
                                (string-append bin "/samtools")))))
               (delete 'patch-tests)
               (delete 'configure))))))))

(define-public mosaik
  (let ((commit "5c25216d"))
    (package
      (name "mosaik")
      (version "2.2.30")
      (source (origin
                ;; There are no release tarballs nor tags.
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/wanpinglee/MOSAIK.git")
                      (commit commit)))
                (file-name (string-append name "-" version))
                (sha256
                 (base32
                  "17gj3s07cm77r41z92awh0bim7w7q7fbn0sf5nkqmcm1vw052qgw"))))
      (build-system gnu-build-system)
      (arguments
       `(#:tests? #f ; no tests
         #:make-flags (list "CC=gcc")
         #:phases
         (modify-phases %standard-phases
           (replace 'configure
                    (lambda _ (chdir "src") #t))
           (replace 'install
                    (lambda* (#:key outputs #:allow-other-keys)
                      (let ((bin (string-append (assoc-ref outputs "out")
                                                "/bin")))
                        (mkdir-p bin)
                        (copy-recursively "../bin" bin)
                        #t))))))
      (inputs
       `(("perl" ,perl)
         ("zlib" ,zlib)))
      (supported-systems '("x86_64-linux"))
      (home-page "https://code.google.com/p/mosaik-aligner/")
      (synopsis "Map nucleotide sequence reads to reference genomes")
      (description
       "MOSAIK is a program for mapping second and third-generation sequencing
reads to a reference genome.  MOSAIK can align reads generated by all the
major sequencing technologies, including Illumina, Applied Biosystems SOLiD,
Roche 454, Ion Torrent and Pacific BioSciences SMRT.")
      ;; MOSAIK is released under the GPLv2+ with the exception of third-party
      ;; code released into the public domain:
      ;; 1. fastlz by Ariya Hidayat - http://www.fastlz.org/
      ;; 2. MD5 implementation - RSA Data Security, RFC 1321
      (license (list license:gpl2+ license:public-domain)))))

(define-public ngs-sdk
  (package
    (name "ngs-sdk")
    (version "1.2.3")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append "https://github.com/ncbi/ngs/archive/"
                       version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "15074fdi94c6pjy83hhk22r86kfvzpaz2i07h3rqg9yy6x3w0pk2"))))
    (build-system gnu-build-system)
    (arguments
     `(#:parallel-build? #f ; not supported
       #:tests? #f ; no "check" target
       #:phases
       (alist-replace
        'configure
        (lambda* (#:key outputs #:allow-other-keys)
          (let ((out (assoc-ref outputs "out")))
            ;; The 'configure' script doesn't recognize things like
            ;; '--enable-fast-install'.
            (zero? (system* "./configure"
                            (string-append "--build-prefix=" (getcwd) "/build")
                            (string-append "--prefix=" out)))))
        (alist-cons-after
         'unpack 'enter-dir
         (lambda _ (chdir "ngs-sdk") #t)
         %standard-phases))))
    (native-inputs `(("perl" ,perl)))
    ;; According to the test
    ;;   unless ($MARCH =~ /x86_64/i || $MARCH =~ /i?86/i)
    ;; in ngs-sdk/setup/konfigure.perl
    (supported-systems '("i686-linux" "x86_64-linux"))
    (home-page "https://github.com/ncbi/ngs")
    (synopsis "API for accessing Next Generation Sequencing data")
    (description
     "NGS is a domain-specific API for accessing reads, alignments and pileups
produced from Next Generation Sequencing.  The API itself is independent from
any particular back-end implementation, and supports use of multiple back-ends
simultaneously.")
    (license license:public-domain)))

(define-public ngs-java
  (package (inherit ngs-sdk)
    (name "ngs-java")
    (arguments
     `(,@(substitute-keyword-arguments
             `(#:modules ((guix build gnu-build-system)
                          (guix build utils)
                          (srfi srfi-1)
                          (srfi srfi-26))
                         ,@(package-arguments ngs-sdk))
           ((#:phases phases)
            `(modify-phases ,phases
               (replace 'enter-dir (lambda _ (chdir "ngs-java") #t)))))))
    (inputs
     `(("jdk" ,icedtea "jdk")
       ("ngs-sdk" ,ngs-sdk)))
    (synopsis "Java bindings for NGS SDK")))

(define-public ncbi-vdb
  (package
    (name "ncbi-vdb")
    (version "2.5.7")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append "https://github.com/ncbi/ncbi-vdb/archive/"
                       version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "0hay5hy8ynva3mi5wbn4wmq1q23qwxc3aqzbb86hg3x4f1r73270"))))
    (build-system gnu-build-system)
    (arguments
     `(#:parallel-build? #f ; not supported
       #:tests? #f ; no "check" target
       #:phases
       (alist-replace
        'configure
        (lambda* (#:key inputs outputs #:allow-other-keys)
          (let ((out (assoc-ref outputs "out")))
            ;; Override include path for libmagic
            (substitute* "setup/package.prl"
              (("name => 'magic', Include => '/usr/include'")
               (string-append "name=> 'magic', Include => '"
                              (assoc-ref inputs "libmagic")
                              "/include" "'")))

            ;; Install kdf5 library (needed by sra-tools)
            (substitute* "build/Makefile.install"
              (("LIBRARIES_TO_INSTALL =")
               "LIBRARIES_TO_INSTALL = kdf5.$(VERSION_LIBX) kdf5.$(VERSION_SHLX)"))

            ;; The 'configure' script doesn't recognize things like
            ;; '--enable-fast-install'.
            (zero? (system*
                    "./configure"
                    (string-append "--build-prefix=" (getcwd) "/build")
                    (string-append "--prefix=" (assoc-ref outputs "out"))
                    (string-append "--debug")
                    (string-append "--with-xml2-prefix="
                                   (assoc-ref inputs "libxml2"))
                    (string-append "--with-ngs-sdk-prefix="
                                   (assoc-ref inputs "ngs-sdk"))
                    (string-append "--with-ngs-java-prefix="
                                   (assoc-ref inputs "ngs-java"))
                    (string-append "--with-hdf5-prefix="
                                   (assoc-ref inputs "hdf5"))))))
        (alist-cons-after
         'install 'install-interfaces
         (lambda* (#:key outputs #:allow-other-keys)
           ;; Install interface libraries.  On i686 the interface libraries
           ;; are installed to "linux/gcc/i386", so we need to use the Linux
           ;; architecture name ("i386") instead of the target system prefix
           ;; ("i686").
           (mkdir (string-append (assoc-ref outputs "out") "/ilib"))
           (copy-recursively (string-append "build/ncbi-vdb/linux/gcc/"
                                            ,(system->linux-architecture
                                              (or (%current-target-system)
                                                  (%current-system)))
                                            "/rel/ilib")
                             (string-append (assoc-ref outputs "out")
                                            "/ilib"))
           ;; Install interface headers
           (copy-recursively "interfaces"
                             (string-append (assoc-ref outputs "out")
                                            "/include")))
         %standard-phases))))
    (inputs
     `(("libxml2" ,libxml2)
       ("ngs-sdk" ,ngs-sdk)
       ("ngs-java" ,ngs-java)
       ("libmagic" ,file)
       ("hdf5" ,hdf5)))
    (native-inputs `(("perl" ,perl)))
    (home-page "https://github.com/ncbi/ncbi-vdb")
    (synopsis "Database engine for genetic information")
    (description
     "The NCBI-VDB library implements a highly compressed columnar data
warehousing engine that is most often used to store genetic information.
Databases are stored in a portable image within the file system, and can be
accessed/downloaded on demand across HTTP.")
    (license license:public-domain)))

(define-public plink
  (package
    (name "plink")
    (version "1.07")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://pngu.mgh.harvard.edu/~purcell/plink/dist/plink-"
             version "-src.zip"))
       (sha256
        (base32 "0as8gxm4pjyc8dxmm1sl873rrd7wn5qs0l29nqfnl31x8i467xaa"))
       (patches (list (search-patch "plink-1.07-unclobber-i.patch")))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f ;no "check" target
       #:make-flags (list (string-append "LIB_LAPACK="
                                         (assoc-ref %build-inputs "lapack")
                                         "/lib/liblapack.so")
                          "WITH_LAPACK=1"
                          "FORCE_DYNAMIC=1"
                          ;; disable phoning home
                          "WITH_WEBCHECK=")
       #:phases
       (modify-phases %standard-phases
         ;; no "configure" script
         (delete 'configure)
         (replace 'install
                  (lambda* (#:key outputs #:allow-other-keys)
                    (let ((bin (string-append (assoc-ref outputs "out")
                                              "/bin/")))
                      (install-file "plink" bin)
                      #t))))))
    (inputs
     `(("zlib" ,zlib)
       ("lapack" ,lapack)))
    (native-inputs
     `(("unzip" ,unzip)))
    (home-page "http://pngu.mgh.harvard.edu/~purcell/plink/")
    (synopsis "Whole genome association analysis toolset")
    (description
     "PLINK is a whole genome association analysis toolset, designed to
perform a range of basic, large-scale analyses in a computationally efficient
manner.  The focus of PLINK is purely on analysis of genotype/phenotype data,
so there is no support for steps prior to this (e.g. study design and
planning, generating genotype or CNV calls from raw data).  Through
integration with gPLINK and Haploview, there is some support for the
subsequent visualization, annotation and storage of results.")
    ;; Code is released under GPLv2, except for fisher.h, which is under
    ;; LGPLv2.1+
    (license (list license:gpl2 license:lgpl2.1+))))

(define-public smithlab-cpp
  (let ((revision "1")
        (commit "728a097"))
    (package
      (name "smithlab-cpp")
      (version (string-append "0." revision "." commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "https://github.com/smithlabcode/smithlab_cpp.git")
                      (commit commit)))
                (file-name (string-append name "-" version "-checkout"))
                (sha256
                 (base32
                  "0d476lmj312xk77kr9fzrv7z1bv96yfyx0w7y62ycmnfbx32ll74"))))
      (build-system gnu-build-system)
      (arguments
       `(#:modules ((guix build gnu-build-system)
                    (guix build utils)
                    (srfi srfi-26))
         #:tests? #f ;no "check" target
         #:phases
         (modify-phases %standard-phases
           (add-after 'unpack 'use-samtools-headers
            (lambda _
              (substitute* '("SAM.cpp"
                             "SAM.hpp")
                (("sam.h") "samtools/sam.h"))
              #t))
           (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out     (assoc-ref outputs "out"))
                     (lib     (string-append out "/lib"))
                     (include (string-append out "/include/smithlab-cpp")))
                (mkdir-p lib)
                (mkdir-p include)
                (for-each (cut install-file <> lib)
                          (find-files "." "\\.o$"))
                (for-each (cut install-file <> include)
                          (find-files "." "\\.hpp$")))
              #t))
           (delete 'configure))))
      (inputs
       `(("samtools" ,samtools-0.1)
         ("zlib" ,zlib)))
      (home-page "https://github.com/smithlabcode/smithlab_cpp")
      (synopsis "C++ helper library for functions used in Smith lab projects")
      (description
       "Smithlab CPP is a C++ library that includes functions used in many of
the Smith lab bioinformatics projects, such as a wrapper around Samtools data
structures, classes for genomic regions, mapped sequencing reads, etc.")
      (license license:gpl3+))))

(define-public preseq
  (package
    (name "preseq")
    (version "2.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/smithlabcode/"
                                  "preseq/archive/v" version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32 "08r684l50pnxjpvmhzjgqq56yv9rfw90k8vx0nsrnrzk8mf9hsdq"))
              (modules '((guix build utils)))
              (snippet
               ;; Remove bundled samtools.
               '(delete-file-recursively "samtools"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ;no "check" target
       #:phases
       (modify-phases %standard-phases
         (delete 'configure))
       #:make-flags
       (list (string-append "PREFIX="
                            (assoc-ref %outputs "out"))
             (string-append "LIBBAM="
                            (assoc-ref %build-inputs "samtools")
                            "/lib/libbam.a")
             (string-append "SMITHLAB_CPP="
                            (assoc-ref %build-inputs "smithlab-cpp")
                            "/lib")
             "PROGS=preseq"
             "INCLUDEDIRS=$(SMITHLAB_CPP)/../include/smithlab-cpp $(SAMTOOLS_DIR)")))
    (inputs
     `(("gsl" ,gsl)
       ("samtools" ,samtools-0.1)
       ("smithlab-cpp" ,smithlab-cpp)
       ("zlib" ,zlib)))
    (home-page "http://smithlabresearch.org/software/preseq/")
    (synopsis "Program for analyzing library complexity")
    (description
     "The preseq package is aimed at predicting and estimating the complexity
of a genomic sequencing library, equivalent to predicting and estimating the
number of redundant reads from a given sequencing depth and how many will be
expected from additional sequencing using an initial sequencing experiment.
The estimates can then be used to examine the utility of further sequencing,
optimize the sequencing depth, or to screen multiple libraries to avoid low
complexity samples.")
    (license license:gpl3+)))

(define-public sra-tools
  (package
    (name "sra-tools")
    (version "2.5.7")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append "https://github.com/ncbi/sra-tools/archive/"
                       version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "0q93qg744x787d08qmjmdafki1wkbvkdwynayjnjd454gkd26jl5"))))
    (build-system gnu-build-system)
    (arguments
     `(#:parallel-build? #f ; not supported
       #:tests? #f ; no "check" target
       #:phases
       (alist-replace
        'configure
        (lambda* (#:key inputs outputs #:allow-other-keys)
          ;; The build system expects a directory containing the sources and
          ;; raw build output of ncbi-vdb, including files that are not
          ;; installed.  Since we are building against an installed version of
          ;; ncbi-vdb, the following modifications are needed.
          (substitute* "setup/konfigure.perl"
            ;; Make the configure script look for the "ilib" directory of
            ;; "ncbi-vdb" without first checking for the existence of a
            ;; matching library in its "lib" directory.
            (("^            my \\$f = File::Spec->catdir\\(\\$libdir, \\$lib\\);")
             "my $f = File::Spec->catdir($ilibdir, $ilib);")
            ;; Look for interface libraries in ncbi-vdb's "ilib" directory.
            (("my \\$ilibdir = File::Spec->catdir\\(\\$builddir, 'ilib'\\);")
             "my $ilibdir = File::Spec->catdir($dir, 'ilib');"))

          ;; The 'configure' script doesn't recognize things like
          ;; '--enable-fast-install'.
          (zero? (system*
                  "./configure"
                  (string-append "--build-prefix=" (getcwd) "/build")
                  (string-append "--prefix=" (assoc-ref outputs "out"))
                  (string-append "--debug")
                  (string-append "--with-fuse-prefix="
                                 (assoc-ref inputs "fuse"))
                  (string-append "--with-magic-prefix="
                                 (assoc-ref inputs "libmagic"))
                  ;; TODO: building with libxml2 fails with linker errors
                  ;; (string-append "--with-xml2-prefix="
                  ;;                (assoc-ref inputs "libxml2"))
                  (string-append "--with-ncbi-vdb-sources="
                                 (assoc-ref inputs "ncbi-vdb"))
                  (string-append "--with-ncbi-vdb-build="
                                 (assoc-ref inputs "ncbi-vdb"))
                  (string-append "--with-ngs-sdk-prefix="
                                 (assoc-ref inputs "ngs-sdk"))
                  (string-append "--with-hdf5-prefix="
                                 (assoc-ref inputs "hdf5")))))
        %standard-phases)))
    (native-inputs `(("perl" ,perl)))
    (inputs
     `(("ngs-sdk" ,ngs-sdk)
       ("ncbi-vdb" ,ncbi-vdb)
       ("libmagic" ,file)
       ("fuse" ,fuse)
       ("hdf5" ,hdf5)
       ("zlib" ,zlib)))
    (home-page "http://www.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?view=software")
    (synopsis "Tools and libraries for reading and writing sequencing data")
    (description
     "The SRA Toolkit from NCBI is a collection of tools and libraries for
reading of sequencing files from the Sequence Read Archive (SRA) database and
writing files into the .sra format.")
    (license license:public-domain)))

(define-public seqan
  (package
    (name "seqan")
    (version "1.4.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://packages.seqan.de/seqan-library/"
                                  "seqan-library-" version ".tar.bz2"))
              (sha256
               (base32
                "05s3wrrwn50f81aklfm65i4a749zag1vr8z03k21xm0pdxy47yvp"))))
    ;; The documentation is 7.8MB and the includes are 3.6MB heavy, so it
    ;; makes sense to split the outputs.
    (outputs '("out" "doc"))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let ((tar  (assoc-ref %build-inputs "tar"))
               (bzip (assoc-ref %build-inputs "bzip2"))
               (out  (assoc-ref %outputs "out"))
               (doc  (assoc-ref %outputs "doc")))
           (setenv "PATH" (string-append tar "/bin:" bzip "/bin"))
           (system* "tar" "xvf" (assoc-ref %build-inputs "source"))
           (chdir (string-append "seqan-library-" ,version))
           (copy-recursively "include" (string-append out "/include"))
           (copy-recursively "share"  (string-append doc "/share"))))))
    (native-inputs
     `(("source" ,source)
       ("tar" ,tar)
       ("bzip2" ,bzip2)))
    (home-page "http://www.seqan.de")
    (synopsis "Library for nucleotide sequence analysis")
    (description
     "SeqAn is a C++ library of efficient algorithms and data structures for
the analysis of sequences with the focus on biological data.  It contains
algorithms and data structures for string representation and their
manipulation, online and indexed string search, efficient I/O of
bioinformatics file formats, sequence alignment, and more.")
    (license license:bsd-3)))

(define-public seqmagick
  (package
    (name "seqmagick")
    (version "0.6.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://pypi.python.org/packages/source/s/seqmagick/seqmagick-"
             version ".tar.gz"))
       (sha256
        (base32
         "0cgn477n74gsl4qdaakrrhi953kcsd4q3ivk2lr18x74s3g4ma1d"))))
    (build-system python-build-system)
    (arguments
     ;; python2 only, see https://github.com/fhcrc/seqmagick/issues/56
     `(#:python ,python-2
       #:phases
       (modify-phases %standard-phases
         ;; Current test in setup.py does not work as of 0.6.1,
         ;; so use nose to run tests instead for now. See
         ;; https://github.com/fhcrc/seqmagick/issues/55
         (replace 'check (lambda _ (zero? (system* "nosetests")))))))
    (inputs
     `(("python-biopython" ,python2-biopython)))
    (native-inputs
     `(("python-setuptools" ,python2-setuptools)
       ("python-nose" ,python2-nose)))
    (home-page "http://github.com/fhcrc/seqmagick")
    (synopsis "Tools for converting and modifying sequence files")
    (description
     "Bioinformaticians often have to convert sequence files between formats
and do little manipulations on them, and it's not worth writing scripts for
that.  Seqmagick is a utility to expose the file format conversion in
BioPython in a convenient way.  Instead of having a big mess of scripts, there
is one that takes arguments.")
    (license license:gpl3)))

(define-public snap-aligner
  (package
    (name "snap-aligner")
    (version "1.0beta.18")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/amplab/snap/archive/v"
                    version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1vnsjwv007k1fl1q7d681kbwn6bc66cgw6h16hym6gvyy71qv2ly"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'check (lambda _ (zero? (system* "./unit_tests"))))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (bin (string-append out "/bin")))
               (mkdir-p bin)
               (install-file "snap-aligner" bin)
               (install-file "SNAPCommand" bin)
               #t))))))
    (native-inputs
     `(("zlib" ,zlib)))
    (home-page "http://snap.cs.berkeley.edu/")
    (synopsis "Short read DNA sequence aligner")
    (description
     "SNAP is a fast and accurate aligner for short DNA reads.  It is
optimized for modern read lengths of 100 bases or higher, and takes advantage
of these reads to align data quickly through a hash-based indexing scheme.")
    (license license:asl2.0)))

(define-public sortmerna
  (package
    (name "sortmerna")
    (version "2.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/biocore/sortmerna/archive/"
             version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1mc5cf1c7xh0h7xb11vh7gqgzx0qvrfa606cb8ixlfg3f2av58s4"))))
    (build-system gnu-build-system)
    (outputs '("out"      ;for binaries
               "db"))     ;for sequence databases
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out   (assoc-ref outputs "out"))
                    (bin   (string-append out "/bin"))
                    (db    (assoc-ref outputs "db"))
                    (share
                     (string-append db "/share/sortmerna/rRNA_databases")))
               (install-file "sortmerna" bin)
               (install-file "indexdb_rna" bin)
               (for-each (lambda (file)
                           (install-file file share))
                         (find-files "rRNA_databases" ".*fasta"))
               #t))))))
    (home-page "http://bioinfo.lifl.fr/RNA/sortmerna")
    (synopsis "Biological sequence analysis tool for NGS reads")
    (description
     "SortMeRNA is a biological sequence analysis tool for filtering, mapping
and operational taxonomic unit (OTU) picking of next generation
sequencing (NGS) reads.  The core algorithm is based on approximate seeds and
allows for fast and sensitive analyses of nucleotide sequences.  The main
application of SortMeRNA is filtering rRNA from metatranscriptomic data.")
    (license license:lgpl3)))

(define-public star
  (package
    (name "star")
    (version "2.5.1b")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/alexdobin/STAR/archive/"
                                  version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "0wzcfhkg10apnh0y73xlarfa79xxwxdizicbdl11wb48awk44iq4"))
              (modules '((guix build utils)))
              (snippet
               '(begin
                  (substitute* "source/Makefile"
                    (("/bin/rm") "rm"))
                  ;; Remove pre-built binaries and bundled htslib sources.
                  (delete-file-recursively "bin/MacOSX_x86_64")
                  (delete-file-recursively "bin/Linux_x86_64")
                  (delete-file-recursively "source/htslib")
                  #t))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f ;no check target
       #:make-flags '("STAR")
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'enter-source-dir
           (lambda _ (chdir "source") #t))
         (add-after 'enter-source-dir 'do-not-use-bundled-htslib
           (lambda _
             (substitute* "Makefile"
               (("(Depend.list: \\$\\(SOURCES\\) parametersDefault\\.xxd) htslib"
                 _ prefix) prefix))
             (substitute* '("BAMfunctions.cpp"
                            "signalFromBAM.h"
                            "bam_cat.h"
                            "bam_cat.c"
                            "STAR.cpp"
                            "bamRemoveDuplicates.cpp")
               (("#include \"htslib/([^\"]+\\.h)\"" _ header)
                (string-append "#include <" header ">")))
             (substitute* "IncludeDefine.h"
               (("\"htslib/(htslib/[^\"]+.h)\"" _ header)
                (string-append "<" header ">")))
             #t))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let ((bin (string-append (assoc-ref outputs "out") "/bin/")))
               (install-file "STAR" bin))
             #t))
         (delete 'configure))))
    (native-inputs
     `(("vim" ,vim))) ; for xxd
    (inputs
     `(("htslib" ,htslib)
       ("zlib" ,zlib)))
    (home-page "https://github.com/alexdobin/STAR")
    (synopsis "Universal RNA-seq aligner")
    (description
     "The Spliced Transcripts Alignment to a Reference (STAR) software is
based on a previously undescribed RNA-seq alignment algorithm that uses
sequential maximum mappable seed search in uncompressed suffix arrays followed
by seed clustering and stitching procedure.  In addition to unbiased de novo
detection of canonical junctions, STAR can discover non-canonical splices and
chimeric (fusion) transcripts, and is also capable of mapping full-length RNA
sequences.")
    ;; STAR is licensed under GPLv3 or later; htslib is MIT-licensed.
    (license license:gpl3+)))

(define-public subread
  (package
    (name "subread")
    (version "1.4.6-p2")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://sourceforge/subread/subread-"
                    version "-source.tar.gz"))
              (sha256
               (base32
                "06sv9mpcsdj6p68y15d6gi70lca3lxmzk0dn61hg0kfsa7rxmsr3"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ;no "check" target
      ;; The CC and CCFLAGS variables are set to contain a lot of x86_64
      ;; optimizations by default, so we override these flags such that x86_64
      ;; flags are only added when the build target is an x86_64 system.
       #:make-flags
       (list (let ((system ,(or (%current-target-system)
                                (%current-system)))
                   (flags '("-ggdb" "-fomit-frame-pointer"
                            "-ffast-math" "-funroll-loops"
                            "-fmessage-length=0"
                            "-O9" "-Wall" "-DMAKE_FOR_EXON"
                            "-DMAKE_STANDALONE"
                            "-DSUBREAD_VERSION=\\\"${SUBREAD_VERSION}\\\""))
                   (flags64 '("-mmmx" "-msse" "-msse2" "-msse3")))
               (if (string-prefix? "x86_64" system)
                   (string-append "CCFLAGS=" (string-join (append flags flags64)))
                   (string-append "CCFLAGS=" (string-join flags))))
             "-f" "Makefile.Linux"
             "CC=gcc ${CCFLAGS}")
       #:phases
       (alist-cons-after
        'unpack 'enter-dir
        (lambda _ (chdir "src") #t)
        (alist-replace
         'install
         (lambda* (#:key outputs #:allow-other-keys)
           (let ((bin (string-append (assoc-ref outputs "out") "/bin/")))
             (mkdir-p bin)
             (copy-recursively "../bin" bin)))
         ;; no "configure" script
         (alist-delete 'configure %standard-phases)))))
    (inputs `(("zlib" ,zlib)))
    (home-page "http://bioinf.wehi.edu.au/subread-package/")
    (synopsis "Tool kit for processing next-gen sequencing data")
    (description
     "The subread package contains the following tools: subread aligner, a
general-purpose read aligner; subjunc aligner: detecting exon-exon junctions
and mapping RNA-seq reads; featureCounts: counting mapped reads for genomic
features; exactSNP: a SNP caller that discovers SNPs by testing signals
against local background noises.")
    (license license:gpl3+)))

(define-public stringtie
  (package
    (name "stringtie")
    (version "1.2.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://ccb.jhu.edu/software/stringtie/dl/"
                                  "stringtie-" version ".tar.gz"))
              (sha256
               (base32
                "1cqllsc1maq4kh92isi8yadgzbmnf042hlnalpk3y59aph1z3bfz"))
              (modules '((guix build utils)))
              (snippet
               '(begin
                  (delete-file-recursively "samtools-0.1.18")
                  #t))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ;no test suite
       #:phases
       (modify-phases %standard-phases
         ;; no configure script
         (delete 'configure)
         (add-before 'build 'use-system-samtools
           (lambda _
             (substitute* "Makefile"
               (("stringtie: \\$\\{BAM\\}/libbam\\.a")
                "stringtie: "))
             (substitute* '("gclib/GBam.h"
                            "gclib/GBam.cpp")
               (("#include \"(bam|sam|kstring).h\"" _ header)
                (string-append "#include <samtools/" header ".h>")))
             #t))
         (replace 'install
          (lambda* (#:key outputs #:allow-other-keys)
            (let ((bin (string-append (assoc-ref outputs "out") "/bin/")))
              (install-file "stringtie" bin)
              #t))))))
    (inputs
     `(("samtools" ,samtools-0.1)
       ("zlib" ,zlib)))
    (home-page "http://ccb.jhu.edu/software/stringtie/")
    (synopsis "Transcript assembly and quantification for RNA-Seq data")
    (description
     "StringTie is a fast and efficient assembler of RNA-Seq sequence
alignments into potential transcripts.  It uses a novel network flow algorithm
as well as an optional de novo assembly step to assemble and quantitate
full-length transcripts representing multiple splice variants for each gene
locus.  Its input can include not only the alignments of raw reads used by
other transcript assemblers, but also alignments of longer sequences that have
been assembled from those reads.  To identify differentially expressed genes
between experiments, StringTie's output can be processed either by the
Cuffdiff or Ballgown programs.")
    (license license:artistic2.0)))

(define-public vcftools
  (package
    (name "vcftools")
    (version "0.1.12b")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://sourceforge/vcftools/vcftools_"
                     version ".tar.gz"))
              (sha256
               (base32
                "148al9h7f8g8my2qdnpax51kdd2yjrivlx6frvakf4lz5r8j88wx"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ; no "check" target
       #:make-flags (list
                     "CFLAGS=-O2" ; override "-m64" flag
                     (string-append "PREFIX=" (assoc-ref %outputs "out"))
                     (string-append "MANDIR=" (assoc-ref %outputs "out")
                                    "/share/man/man1"))
       #:phases
       (alist-cons-after
        'unpack 'patch-manpage-install
        (lambda _
          (substitute* "Makefile"
            (("cp \\$\\{PREFIX\\}/cpp/vcftools.1") "cp ./cpp/vcftools.1")))
        (alist-delete 'configure %standard-phases))))
    (inputs
     `(("perl" ,perl)
       ("zlib" ,zlib)))
    (home-page "http://vcftools.sourceforge.net/")
    (synopsis "Tools for working with VCF files")
    (description
     "VCFtools is a program package designed for working with VCF files, such
as those generated by the 1000 Genomes Project.  The aim of VCFtools is to
provide easily accessible methods for working with complex genetic variation
data in the form of VCF files.")
    ;; The license is declared as LGPLv3 in the README and
    ;; at http://vcftools.sourceforge.net/license.html
    (license license:lgpl3)))

(define-public vsearch
  (package
    (name "vsearch")
    (version "1.10.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/torognes/vsearch/archive/v"
             version ".tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32
         "1i3bad7gnn2y3a1yfixzshd99xdkjc8w5bxzgifpysc6jiljwvb5"))
       (modules '((guix build utils)))
       (snippet
        '(begin
           ;; Remove bundled cityhash and '-mtune=native'.
           (substitute* "src/Makefile.am"
             (("^AM_CXXFLAGS=-I\\$\\{srcdir\\}/cityhash \
-O3 -mtune=native -Wall -Wsign-compare")
              (string-append "AM_CXXFLAGS=-lcityhash"
                             " -O3 -Wall -Wsign-compare"))
             (("^__top_builddir__bin_vsearch_SOURCES = city.h \\\\")
              "__top_builddir__bin_vsearch_SOURCES = \\")
             (("^city.h \\\\") "\\")
             (("^citycrc.h \\\\") "\\")
             (("^libcityhash_a.*") "")
             (("noinst_LIBRARIES = libcpu_sse2.a libcpu_ssse3.a \
libcityhash.a")
              "noinst_LIBRARIES = libcpu_sse2.a libcpu_ssse3.a")
             (("__top_builddir__bin_vsearch_LDADD = libcpu_ssse3.a \
libcpu_sse2.a libcityhash.a")
              "__top_builddir__bin_vsearch_LDADD = libcpu_ssse3.a \
libcpu_sse2.a -lcityhash"))
           (substitute* "src/vsearch.h"
             (("^\\#include \"city.h\"") "#include <city.h>")
             (("^\\#include \"citycrc.h\"") "#include <citycrc.h>"))
           (delete-file "src/city.h")
           (delete-file "src/citycrc.h")
           (delete-file "src/city.cc")
           #t))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-before 'configure 'autogen
                     (lambda _ (zero? (system* "autoreconf" "-vif")))))))
    (inputs
     `(("zlib" ,zlib)
       ("bzip2" ,bzip2)
       ("cityhash" ,cityhash)))
    (native-inputs
     `(("autoconf" ,autoconf)
       ("automake" ,automake)))
    (synopsis "Sequence search tools for metagenomics")
    (description
     "VSEARCH supports DNA sequence searching, clustering, chimera detection,
dereplication, pairwise alignment, shuffling, subsampling, sorting and
masking.  The tool takes advantage of parallelism in the form of SIMD
vectorization as well as multiple threads to perform accurate alignments at
high speed.  VSEARCH uses an optimal global aligner (full dynamic programming
Needleman-Wunsch).")
    (home-page "https://github.com/torognes/vsearch")
    ;; vsearch uses non-portable SSE intrinsics so building fails on other
    ;; platforms.
    (supported-systems '("x86_64-linux"))
    ;; Dual licensed; also includes public domain source.
    (license (list license:gpl3 license:bsd-2))))

(define-public bio-locus
  (package
    (name "bio-locus")
    (version "0.0.7")
    (source
     (origin
       (method url-fetch)
       (uri (rubygems-uri "bio-locus" version))
       (sha256
        (base32
         "02vmrxyimkj9sahsp4zhfhnmbvz6dbbqz1y01vglf8cbwvkajfl0"))))
    (build-system ruby-build-system)
    (native-inputs
     `(("ruby-rspec" ,ruby-rspec)))
    (synopsis "Tool for fast querying of genome locations")
    (description
     "Bio-locus is a tabix-like tool for fast querying of genome
locations.  Many file formats in bioinformatics contain records that
start with a chromosome name and a position for a SNP, or a start-end
position for indels.  Bio-locus allows users to store this chr+pos or
chr+pos+alt information in a database.")
    (home-page "https://github.com/pjotrp/bio-locus")
    (license license:expat)))

(define-public bio-blastxmlparser
  (package
    (name "bio-blastxmlparser")
    (version "2.0.4")
    (source (origin
              (method url-fetch)
              (uri (rubygems-uri "bio-blastxmlparser" version))
              (sha256
               (base32
                "1wf4qygcmdjgcqm6flmvsagfr1gs9lf63mj32qv3z1f481zc5692"))))
    (build-system ruby-build-system)
    (propagated-inputs
     `(("ruby-bio-logger" ,ruby-bio-logger)
       ("ruby-nokogiri" ,ruby-nokogiri)))
    (inputs
     `(("ruby-rspec" ,ruby-rspec)))
    (synopsis "Fast big data BLAST XML parser and library")
    (description
     "Very fast parallel big-data BLAST XML file parser which can be used as
command line utility.  Use blastxmlparser to: Parse BLAST XML; filter output;
generate FASTA, JSON, YAML, RDF, JSON-LD, HTML, CSV, tabular output etc.")
    (home-page "http://github.com/pjotrp/blastxmlparser")
    (license license:expat)))

(define-public bioruby
  (package
    (name "bioruby")
    (version "1.5.0")
    (source
     (origin
       (method url-fetch)
       (uri (rubygems-uri "bio" version))
       (sha256
        (base32
         "01k2fyjl5fpx4zn8g6gqiqvsg2j1fgixrs9p03vzxckynxdq3wmc"))))
    (build-system ruby-build-system)
    (propagated-inputs
     `(("ruby-libxml" ,ruby-libxml)))
    (native-inputs
     `(("which" ,which)))  ; required for test phase
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-before 'build 'patch-test-command
          (lambda _
            (substitute* '("test/functional/bio/test_command.rb")
              (("/bin/sh") (which "sh")))
            (substitute* '("test/functional/bio/test_command.rb")
              (("/bin/ls") (which "ls")))
            (substitute* '("test/functional/bio/test_command.rb")
              (("which") (which "which")))
            (substitute* '("test/functional/bio/test_command.rb",
                           "test/data/command/echoarg2.sh")
              (("/bin/echo") (which "echo")))
            #t)))))
    (synopsis "Ruby library, shell and utilities for bioinformatics")
    (description "BioRuby comes with a comprehensive set of Ruby development
tools and libraries for bioinformatics and molecular biology.  BioRuby has
components for sequence analysis, pathway analysis, protein modelling and
phylogenetic analysis; it supports many widely used data formats and provides
easy access to databases, external programs and public web services, including
BLAST, KEGG, GenBank, MEDLINE and GO.")
    (home-page "http://bioruby.org/")
    ;; Code is released under Ruby license, except for setup
    ;; (LGPLv2.1+) and scripts in samples (which have GPL2 and GPL2+)
    (license (list license:ruby license:lgpl2.1+ license:gpl2+ ))))

(define-public r-acsnminer
  (package
    (name "r-acsnminer")
    (version "0.15.11")
    (source (origin
              (method url-fetch)
              (uri (cran-uri "ACSNMineR" version))
              (sha256
               (base32
                "1dl4drhjyazwm9wxlm8yfppwvvj4h6jxwmz8kfw5bxpb3jdnsqvy"))))
    (properties `((upstream-name . "ACSNMineR")))
    (build-system r-build-system)
    (propagated-inputs
      `(("r-ggplot2" ,r-ggplot2)
        ("r-gridextra" ,r-gridextra)))
    (home-page "http://cran.r-project.org/web/packages/ACSNMineR")
    (synopsis "Gene enrichment analysis")
    (description
     "This package provides tools to compute and represent gene set enrichment
or depletion from your data based on pre-saved maps from the @dfn{Atlas of
Cancer Signalling Networks} (ACSN) or user imported maps.  The gene set
enrichment can be run with hypergeometric test or Fisher exact test, and can
use multiple corrections.  Visualization of data can be done either by
barplots or heatmaps.")
    (license license:gpl2+)))

(define-public r-biocgenerics
  (package
    (name "r-biocgenerics")
    (version "0.16.1")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "BiocGenerics" version))
              (sha256
               (base32
                "0f16ryy5f012hvksrwlmm33bcl7lw97i2jvhbnwfwl03j4w7nhc1"))))
    (properties
     `((upstream-name . "BiocGenerics")
       (r-repository . bioconductor)))
    (build-system r-build-system)
    (home-page "http://bioconductor.org/packages/BiocGenerics")
    (synopsis "S4 generic functions for Bioconductor")
    (description
     "This package provides S4 generic functions needed by many Bioconductor
packages.")
    (license license:artistic2.0)))

(define-public r-s4vectors
  (package
    (name "r-s4vectors")
    (version "0.8.11")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "S4Vectors" version))
              (sha256
               (base32
                "12iibcs63m9iy7f45wgjcqsna2dnqwckphk682389grshz0g4x66"))))
    (properties
     `((upstream-name . "S4Vectors")
       (r-repository . bioconductor)))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-biocgenerics" ,r-biocgenerics)))
    (home-page "http://bioconductor.org/packages/S4Vectors")
    (synopsis "S4 implementation of vectors and lists")
    (description
     "The S4Vectors package defines the @code{Vector} and @code{List} virtual
classes and a set of generic functions that extend the semantic of ordinary
vectors and lists in R.  Package developers can easily implement vector-like
or list-like objects as concrete subclasses of @code{Vector} or @code{List}.
In addition, a few low-level concrete subclasses of general interest (e.g.
@code{DataFrame}, @code{Rle}, and @code{Hits}) are implemented in the
S4Vectors package itself.")
    (license license:artistic2.0)))

(define-public r-iranges
  (package
    (name "r-iranges")
    (version "2.4.8")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "IRanges" version))
              (sha256
               (base32
                "0hi5k1j5jm4xrg1l506g279qw1xkvp1gg1zgsjzpbng4vx4k4iyl"))))
    (properties
     `((upstream-name . "IRanges")
       (r-repository . bioconductor)))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-biocgenerics" ,r-biocgenerics)
       ("r-s4vectors" ,r-s4vectors)))
    (home-page "http://bioconductor.org/packages/IRanges")
    (synopsis "Infrastructure for manipulating intervals on sequences")
    (description
     "This package provides efficient low-level and highly reusable S4 classes
for storing ranges of integers, RLE vectors (Run-Length Encoding), and, more
generally, data that can be organized sequentially (formally defined as
@code{Vector} objects), as well as views on these @code{Vector} objects.
Efficient list-like classes are also provided for storing big collections of
instances of the basic classes.  All classes in the package use consistent
naming and share the same rich and consistent \"Vector API\" as much as
possible.")
    (license license:artistic2.0)))

(define-public r-genomeinfodb
  (package
    (name "r-genomeinfodb")
    (version "1.6.1")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "GenomeInfoDb" version))
              (sha256
               (base32
                "1j2n1v1mrw1fxn7cyffz112pm76wd6gy9q9qwlsfv3brbsqbvdbf"))))
    (properties
     `((upstream-name . "GenomeInfoDb")
       (r-repository . bioconductor)))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-biocgenerics" ,r-biocgenerics)
       ("r-iranges" ,r-iranges)
       ("r-s4vectors" ,r-s4vectors)))
    (home-page "http://bioconductor.org/packages/GenomeInfoDb")
    (synopsis "Utilities for manipulating chromosome identifiers")
    (description
     "This package contains data and functions that define and allow
translation between different chromosome sequence naming conventions (e.g.,
\"chr1\" versus \"1\"), including a function that attempts to place sequence
names in their natural, rather than lexicographic, order.")
    (license license:artistic2.0)))

(define-public r-xvector
  (package
    (name "r-xvector")
    (version "0.10.0")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "XVector" version))
              (sha256
               (base32
                "0havwyr6xqk7w0rmbwfj9jq1djz7wzdz7w39adhklwzwz9l4ih3a"))))
    (properties
     `((upstream-name . "XVector")
       (r-repository . bioconductor)))
    (build-system r-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'use-system-zlib
           (lambda _
             (substitute* "DESCRIPTION"
               (("zlibbioc, ") ""))
             (substitute* "NAMESPACE"
               (("import\\(zlibbioc\\)") ""))
             #t)))))
    (inputs
     `(("zlib" ,zlib)))
    (propagated-inputs
     `(("r-biocgenerics" ,r-biocgenerics)
       ("r-iranges" ,r-iranges)
       ("r-s4vectors" ,r-s4vectors)))
    (home-page "http://bioconductor.org/packages/XVector")
    (synopsis "Representation and manpulation of external sequences")
    (description
     "This package provides memory efficient S4 classes for storing sequences
\"externally\" (behind an R external pointer, or on disk).")
    (license license:artistic2.0)))

(define-public r-genomicranges
  (package
    (name "r-genomicranges")
    (version "1.22.2")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "GenomicRanges" version))
              (sha256
               (base32
                "1jffvcs0jsi7q4l3pvjj6r73vll80csgkljvhqp0g2ixc43jjng9"))))
    (properties
     `((upstream-name . "GenomicRanges")
       (r-repository . bioconductor)))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-biocgenerics" ,r-biocgenerics)
       ("r-genomeinfodb" ,r-genomeinfodb)
       ("r-xvector" ,r-xvector)))
    (home-page "http://bioconductor.org/packages/GenomicRanges")
    (synopsis "Representation and manipulation of genomic intervals")
    (description
     "This package provides tools to efficiently represent and manipulate
genomic annotations and alignments is playing a central role when it comes to
analyzing high-throughput sequencing data (a.k.a. NGS data).  The
GenomicRanges package defines general purpose containers for storing and
manipulating genomic intervals and variables defined along a genome.")
    (license license:artistic2.0)))

(define-public r-biobase
  (package
    (name "r-biobase")
    (version "2.30.0")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "Biobase" version))
              (sha256
               (base32
                "1qasjpq3kw8h7qw8cin3bjvv1256hqr1mm24fq3v0ymxzlb66szi"))))
    (properties
     `((upstream-name . "Biobase")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-biocgenerics" ,r-biocgenerics)))
    (home-page "http://bioconductor.org/packages/Biobase")
    (synopsis "Base functions for Bioconductor")
    (description
     "This package provides functions that are needed by many other packages
on Bioconductor or which replace R functions.")
    (license license:artistic2.0)))

(define-public r-annotationdbi
  (package
    (name "r-annotationdbi")
    (version "1.32.3")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "AnnotationDbi" version))
              (sha256
               (base32
                "1v6x62hgys5827yg2xayjrd9xawbayzm6wy0q4vxh1s6yxc9bklj"))))
    (properties
     `((upstream-name . "AnnotationDbi")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-biobase" ,r-biobase)
       ("r-biocgenerics" ,r-biocgenerics)
       ("r-dbi" ,r-dbi)
       ("r-iranges" ,r-iranges)
       ("r-rsqlite" ,r-rsqlite)
       ("r-s4vectors" ,r-s4vectors)))
    (home-page "http://bioconductor.org/packages/AnnotationDbi")
    (synopsis "Annotation database interface")
    (description
     "This package provides user interface and database connection code for
annotation data packages using SQLite data storage.")
    (license license:artistic2.0)))

(define-public r-biomart
  (package
    (name "r-biomart")
    (version "2.26.1")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "biomaRt" version))
              (sha256
               (base32
                "1s709055abj2gd35g6nnk5d2ai5ii09iir270l2xika6pi62gj3f"))))
    (properties
     `((upstream-name . "biomaRt")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-annotationdbi" ,r-annotationdbi)
       ("r-rcurl" ,r-rcurl)
       ("r-xml" ,r-xml)))
    (home-page "http://bioconductor.org/packages/biomaRt")
    (synopsis "Interface to BioMart databases")
    (description
     "biomaRt provides an interface to a growing collection of databases
implementing the @url{BioMart software suite, http://www.biomart.org}.  The
package enables retrieval of large amounts of data in a uniform way without
the need to know the underlying database schemas or write complex SQL queries.
Examples of BioMart databases are Ensembl, COSMIC, Uniprot, HGNC, Gramene,
Wormbase and dbSNP mapped to Ensembl.  These major databases give biomaRt
users direct access to a diverse set of data and enable a wide range of
powerful online queries from gene annotation to database mining.")
    (license license:artistic2.0)))

(define-public r-biocparallel
  (package
    (name "r-biocparallel")
    (version "1.4.3")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "BiocParallel" version))
              (sha256
               (base32
                "1f5mndx66vampcsq0n66afg6x851crl0h3nyv2nyp9bsgzj9cdzq"))))
    (properties
     `((upstream-name . "BiocParallel")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-futile-logger" ,r-futile-logger)
       ("r-snow" ,r-snow)))
    (home-page "http://bioconductor.org/packages/BiocParallel")
    (synopsis "Bioconductor facilities for parallel evaluation")
    (description
     "This package provides modified versions and novel implementation of
functions for parallel evaluation, tailored to use with Bioconductor
objects.")
    (license (list license:gpl2+ license:gpl3+))))

(define-public r-biostrings
  (package
    (name "r-biostrings")
    (version "2.38.2")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "Biostrings" version))
              (sha256
               (base32
                "1afp9szc8ci6jn0m3hrrqh6df65cpw3v1dcnl6xir3d3m3lwwmk4"))))
    (properties
     `((upstream-name . "Biostrings")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-biocgenerics" ,r-biocgenerics)
       ("r-iranges" ,r-iranges)
       ("r-s4vectors" ,r-s4vectors)
       ("r-xvector" ,r-xvector)))
    (home-page "http://bioconductor.org/packages/Biostrings")
    (synopsis "String objects and algorithms for biological sequences")
    (description
     "This package provides memory efficient string containers, string
matching algorithms, and other utilities, for fast manipulation of large
biological sequences or sets of sequences.")
    (license license:artistic2.0)))

(define-public r-rsamtools
  (package
    (name "r-rsamtools")
    (version "1.22.0")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "Rsamtools" version))
              (sha256
               (base32
                "1yc3nzzms3igjwr4l9yd3wdac95glcs08b4cfp7disyly0wcskjd"))))
    (properties
     `((upstream-name . "Rsamtools")))
    (build-system r-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'use-system-zlib
           (lambda _
             (substitute* "DESCRIPTION"
               (("zlibbioc, ") ""))
             (substitute* "NAMESPACE"
               (("import\\(zlibbioc\\)") ""))
             #t)))))
    (inputs
     `(("zlib" ,zlib)))
    (propagated-inputs
     `(("r-biocgenerics" ,r-biocgenerics)
       ("r-biocparallel" ,r-biocparallel)
       ("r-biostrings" ,r-biostrings)
       ("r-bitops" ,r-bitops)
       ("r-genomeinfodb" ,r-genomeinfodb)
       ("r-genomicranges" ,r-genomicranges)
       ("r-iranges" ,r-iranges)
       ("r-s4vectors" ,r-s4vectors)
       ("r-xvector" ,r-xvector)))
    (home-page "http://bioconductor.org/packages/release/bioc/html/Rsamtools.html")
    (synopsis "Interface to samtools, bcftools, and tabix")
    (description
     "This package provides an interface to the 'samtools', 'bcftools', and
'tabix' utilities for manipulating SAM (Sequence Alignment / Map), FASTA,
binary variant call (BCF) and compressed indexed tab-delimited (tabix)
files.")
    (license license:expat)))

(define-public r-summarizedexperiment
  (package
    (name "r-summarizedexperiment")
    (version "1.0.1")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "SummarizedExperiment" version))
              (sha256
               (base32
                "0w1dwp99p6i7sc3cn0ir3dr8ksgxwjf16675h5i8n6gbv4rl9lz6"))))
    (properties
     `((upstream-name . "SummarizedExperiment")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-biobase" ,r-biobase)
       ("r-biocgenerics" ,r-biocgenerics)
       ("r-genomeinfodb" ,r-genomeinfodb)
       ("r-genomicranges" ,r-genomicranges)
       ("r-iranges" ,r-iranges)
       ("r-s4vectors" ,r-s4vectors)))
    (home-page "http://bioconductor.org/packages/SummarizedExperiment")
    (synopsis "Container for representing genomic ranges by sample")
    (description
     "The SummarizedExperiment container contains one or more assays, each
represented by a matrix-like object of numeric or other mode.  The rows
typically represent genomic ranges of interest and the columns represent
samples.")
    (license license:artistic2.0)))

(define-public r-genomicalignments
  (package
    (name "r-genomicalignments")
    (version "1.6.1")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "GenomicAlignments" version))
              (sha256
               (base32
                "03pxzkmwcpl0d7a09ahan0nllfv7qw2i7w361w6af2s4n3xwrniz"))))
    (properties
     `((upstream-name . "GenomicAlignments")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-biocgenerics" ,r-biocgenerics)
       ("r-biocparallel" ,r-biocparallel)
       ("r-biostrings" ,r-biostrings)
       ("r-genomeinfodb" ,r-genomeinfodb)
       ("r-genomicranges" ,r-genomicranges)
       ("r-iranges" ,r-iranges)
       ("r-rsamtools" ,r-rsamtools)
       ("r-s4vectors" ,r-s4vectors)
       ("r-summarizedexperiment" ,r-summarizedexperiment)))
    (home-page "http://bioconductor.org/packages/GenomicAlignments")
    (synopsis "Representation and manipulation of short genomic alignments")
    (description
     "This package provides efficient containers for storing and manipulating
short genomic alignments (typically obtained by aligning short reads to a
reference genome).  This includes read counting, computing the coverage,
junction detection, and working with the nucleotide content of the
alignments.")
    (license license:artistic2.0)))

(define-public r-rtracklayer
  (package
    (name "r-rtracklayer")
    (version "1.30.1")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "rtracklayer" version))
              (sha256
               (base32
                "1if31hg56islx5vwydpgs5gkyas26kyvv2ljv1c7jikpm62w14qv"))))
    (build-system r-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'use-system-zlib
           (lambda _
             (substitute* "DESCRIPTION"
               (("zlibbioc, ") ""))
             (substitute* "NAMESPACE"
               (("import\\(zlibbioc\\)") ""))
             #t)))))
    (inputs
     `(("zlib" ,zlib)))
    (propagated-inputs
     `(("r-biocgenerics" ,r-biocgenerics)
       ("r-biostrings" ,r-biostrings)
       ("r-genomeinfodb" ,r-genomeinfodb)
       ("r-genomicalignments" ,r-genomicalignments)
       ("r-genomicranges" ,r-genomicranges)
       ("r-iranges" ,r-iranges)
       ("r-rcurl" ,r-rcurl)
       ("r-rsamtools" ,r-rsamtools)
       ("r-s4vectors" ,r-s4vectors)
       ("r-xml" ,r-xml)
       ("r-xvector" ,r-xvector)))
    (home-page "http://bioconductor.org/packages/rtracklayer")
    (synopsis "R interface to genome browsers and their annotation tracks")
    (description
     "rtracklayer is an extensible framework for interacting with multiple
genome browsers (currently UCSC built-in) and manipulating annotation tracks
in various formats (currently GFF, BED, bedGraph, BED15, WIG, BigWig and 2bit
built-in).  The user may export/import tracks to/from the supported browsers,
as well as query and modify the browser state, such as the current viewport.")
    (license license:artistic2.0)))

(define-public r-genomicfeatures
  (package
    (name "r-genomicfeatures")
    (version "1.22.7")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "GenomicFeatures" version))
              (sha256
               (base32
                "1jb4s49ar5j9qslpd3kfdg2wrl4q7ciysd55h9a7zvspymxcngq8"))))
    (properties
     `((upstream-name . "GenomicFeatures")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-annotationdbi" ,r-annotationdbi)
       ("r-biobase" ,r-biobase)
       ("r-biocgenerics" ,r-biocgenerics)
       ("r-biomart" ,r-biomart)
       ("r-biostrings" ,r-biostrings)
       ("r-dbi" ,r-dbi)
       ("r-genomeinfodb" ,r-genomeinfodb)
       ("r-genomicranges" ,r-genomicranges)
       ("r-iranges" ,r-iranges)
       ("r-rcurl" ,r-rcurl)
       ("r-rsqlite" ,r-rsqlite)
       ("r-rtracklayer" ,r-rtracklayer)
       ("r-s4vectors" ,r-s4vectors)
       ("r-xvector" ,r-xvector)))
    (home-page "http://bioconductor.org/packages/GenomicFeatures")
    (synopsis "Tools for working with transcript centric annotations")
    (description
     "This package provides a set of tools and methods for making and
manipulating transcript centric annotations.  With these tools the user can
easily download the genomic locations of the transcripts, exons and cds of a
given organism, from either the UCSC Genome Browser or a BioMart
database (more sources will be supported in the future).  This information is
then stored in a local database that keeps track of the relationship between
transcripts, exons, cds and genes.  Flexible methods are provided for
extracting the desired features in a convenient format.")
    (license license:artistic2.0)))

(define-public r-go-db
  (package
    (name "r-go-db")
    (version "3.2.2")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "GO.db" version))
              (sha256
               (base32
                "00gariag9ampz82dh0xllrc26r85d7vdcwc0vca5zdy147rwxr7f"))))
    (properties
     `((upstream-name . "GO.db")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-annotationdbi" ,r-annotationdbi)))
    (home-page "http://bioconductor.org/packages/GO.db")
    (synopsis "Annotation maps describing the entire Gene Ontology")
    (description
     "The purpose of this GO.db annotation package is to provide detailed
information about the latest version of the Gene Ontologies.")
    (license license:artistic2.0)))

(define-public r-graph
  (package
    (name "r-graph")
    (version "1.48.0")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "graph" version))
              (sha256
               (base32
                "16w75rji3kv24gfv44w66y1a2y75ax26rl470y3ypna0ndc3rrcd"))))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-biocgenerics" ,r-biocgenerics)))
    (home-page "http://bioconductor.org/packages/graph")
    (synopsis "Handle graph data structures in R")
    (description
     "This package implements some simple graph handling capabilities for R.")
    (license license:artistic2.0)))

(define-public r-topgo
  (package
    (name "r-topgo")
    (version "2.22.0")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "topGO" version))
              (sha256
               (base32
                "029j9nb39b8l9xlzsp83pmjr8ap247aia387yzaa1yyw8klapdaf"))))
    (properties
     `((upstream-name . "topGO")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-annotationdbi" ,r-annotationdbi)
       ("r-biobase" ,r-biobase)
       ("r-biocgenerics" ,r-biocgenerics)
       ("r-go-db" ,r-go-db)
       ("r-graph" ,r-graph)
       ("r-sparsem" ,r-sparsem)))
    (home-page "http://bioconductor.org/packages/topGO")
    (synopsis "Enrichment analysis for gene ontology")
    (description
     "The topGO package provides tools for testing @dfn{gene ontology} (GO)
terms while accounting for the topology of the GO graph.  Different test
statistics and different methods for eliminating local similarities and
dependencies between GO terms can be implemented and applied.")
    ;; Any version of the LGPL applies.
    (license license:lgpl2.1+)))

(define-public r-bsgenome
  (package
    (name "r-bsgenome")
    (version "1.38.0")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "BSgenome" version))
              (sha256
               (base32
                "130w0m6q8kkca7gyz1aqj5jjhalwvwi6rk2yvbjrnj4gpnncyrd2"))))
    (properties
     `((upstream-name . "BSgenome")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-biocgenerics" ,r-biocgenerics)
       ("r-biostrings" ,r-biostrings)
       ("r-genomeinfodb" ,r-genomeinfodb)
       ("r-genomicranges" ,r-genomicranges)
       ("r-iranges" ,r-iranges)
       ("r-rsamtools" ,r-rsamtools)
       ("r-rtracklayer" ,r-rtracklayer)
       ("r-s4vectors" ,r-s4vectors)
       ("r-xvector" ,r-xvector)))
    (home-page "http://bioconductor.org/packages/BSgenome")
    (synopsis "Infrastructure for Biostrings-based genome data packages")
    (description
     "This package provides infrastructure shared by all Biostrings-based
genome data packages and support for efficient SNP representation.")
    (license license:artistic2.0)))

(define-public r-impute
  (package
    (name "r-impute")
    (version "1.44.0")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "impute" version))
              (sha256
               (base32
                "0y4x5jk7gsf4xn56jrkdcdnxpcfll4h6ivncd7n4snmzixldvmvw"))))
    (inputs
     `(("gfortran" ,gfortran)))
    (build-system r-build-system)
    (home-page "http://bioconductor.org/packages/impute")
    (synopsis "Imputation for microarray data")
    (description
     "This package provides a function to impute missing gene expression
microarray data, using nearest neighbor averaging.")
    (license license:gpl2+)))

(define-public r-seqpattern
  (package
    (name "r-seqpattern")
    (version "1.2.0")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "seqPattern" version))
              (sha256
               (base32
                "0p9zj6bic7sa0hb2bjm988kkk5n9r1kvlbqkzvy702f642n0j53i"))))
    (properties
     `((upstream-name . "seqPattern")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-biostrings" ,r-biostrings)
       ("r-genomicranges" ,r-genomicranges)
       ("r-iranges" ,r-iranges)
       ("r-plotrix" ,r-plotrix)))
    (home-page "http://bioconductor.org/packages/seqPattern")
    (synopsis "Visualising oligonucleotide patterns and motif occurrences")
    (description
     "This package provides tools to visualize oligonucleotide patterns and
sequence motif occurrences across a large set of sequences centred at a common
reference point and sorted by a user defined feature.")
    (license license:gpl3+)))

(define-public r-genomation
  (package
    (name "r-genomation")
    (version "1.2.1")
    (source (origin
              (method url-fetch)
              (uri (bioconductor-uri "genomation" version))
              (sha256
               (base32
                "1mzs995snwim13qk9kz4q3nczpnbsy1allwp4whfq0cflg2mndfr"))))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-biostrings" ,r-biostrings)
       ("r-bsgenome" ,r-bsgenome)
       ("r-data-table" ,r-data-table)
       ("r-genomeinfodb" ,r-genomeinfodb)
       ("r-genomicalignments" ,r-genomicalignments)
       ("r-genomicranges" ,r-genomicranges)
       ("r-ggplot2" ,r-ggplot2)
       ("r-gridbase" ,r-gridbase)
       ("r-impute" ,r-impute)
       ("r-iranges" ,r-iranges)
       ("r-matrixstats" ,r-matrixstats)
       ("r-plotrix" ,r-plotrix)
       ("r-plyr" ,r-plyr)
       ("r-readr" ,r-readr)
       ("r-reshape2" ,r-reshape2)
       ("r-rsamtools" ,r-rsamtools)
       ("r-rtracklayer" ,r-rtracklayer)
       ("r-seqpattern" ,r-seqpattern)))
    (home-page "http://bioinformatics.mdc-berlin.de/genomation/")
    (synopsis "Summary, annotation and visualization of genomic data")
    (description
     "This package provides a package for summary and annotation of genomic
intervals.  Users can visualize and quantify genomic intervals over
pre-defined functional regions, such as promoters, exons, introns, etc.  The
genomic intervals represent regions with a defined chromosome position, which
may be associated with a score, such as aligned reads from HT-seq experiments,
TF binding sites, methylation scores, etc.  The package can use any tabular
genomic feature data as long as it has minimal information on the locations of
genomic intervals.  In addition, it can use BAM or BigWig files as input.")
    (license license:artistic2.0)))

(define-public r-org-hs-eg-db
  (package
    (name "r-org-hs-eg-db")
    (version "3.2.3")
    (source (origin
              (method url-fetch)
              ;; We cannot use bioconductor-uri here because this tarball is
              ;; located under "data/annotation/" instead of "bioc/".
              (uri (string-append "http://www.bioconductor.org/packages/"
                                  "release/data/annotation/src/contrib/"
                                  "org.Hs.eg.db_" version ".tar.gz"))
              (sha256
               (base32
                "0xicgkbh6xkvs74s1piafqac63dyz2ycdyil4pj4ghhxx2sabm6p"))))
    (properties
     `((upstream-name . "org.Hs.eg.db")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-annotationdbi" ,r-annotationdbi)))
    (home-page "http://www.bioconductor.org/packages/org.Hs.eg.db/")
    (synopsis "Genome wide annotation for Human")
    (description
     "This package provides mappings from Entrez gene identifiers to various
annotations for the human genome.")
    (license license:artistic2.0)))

(define-public r-org-ce-eg-db
  (package
    (name "r-org-ce-eg-db")
    (version "3.2.3")
    (source (origin
              (method url-fetch)
              ;; We cannot use bioconductor-uri here because this tarball is
              ;; located under "data/annotation/" instead of "bioc/".
              (uri (string-append "http://www.bioconductor.org/packages/"
                                  "release/data/annotation/src/contrib/"
                                  "org.Ce.eg.db_" version ".tar.gz"))
              (sha256
               (base32
                "1d0lx00ybq34yqs6mziaa0lrh77xm0ggsmi76g6k95f77gi7m1sw"))))
    (properties
     `((upstream-name . "org.Ce.eg.db")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-annotationdbi" ,r-annotationdbi)))
    (home-page "http://www.bioconductor.org/packages/org.Ce.eg.db/")
    (synopsis "Genome wide annotation for Worm")
    (description
     "This package provides mappings from Entrez gene identifiers to various
annotations for the genome of the model worm Caenorhabditis elegans.")
    (license license:artistic2.0)))

(define-public r-org-dm-eg-db
  (package
    (name "r-org-dm-eg-db")
    (version "3.2.3")
    (source (origin
              (method url-fetch)
              ;; We cannot use bioconductor-uri here because this tarball is
              ;; located under "data/annotation/" instead of "bioc/".
              (uri (string-append "http://www.bioconductor.org/packages/"
                                  "release/data/annotation/src/contrib/"
                                  "org.Dm.eg.db_" version ".tar.gz"))
              (sha256
               (base32
                "0mib46c7nr00l7mh290n383za9hyl91a1dc6jhjbk884jmxaxyz6"))))
    (properties
     `((upstream-name . "org.Dm.eg.db")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-annotationdbi" ,r-annotationdbi)))
    (home-page "http://www.bioconductor.org/packages/org.Dm.eg.db/")
    (synopsis "Genome wide annotation for Fly")
    (description
     "This package provides mappings from Entrez gene identifiers to various
annotations for the genome of the model fruit fly Drosophila melanogaster.")
    (license license:artistic2.0)))

(define-public r-org-mm-eg-db
  (package
    (name "r-org-mm-eg-db")
    (version "3.2.3")
    (source (origin
              (method url-fetch)
              ;; We cannot use bioconductor-uri here because this tarball is
              ;; located under "data/annotation/" instead of "bioc/".
              (uri (string-append "http://www.bioconductor.org/packages/"
                                  "release/data/annotation/src/contrib/"
                                  "org.Mm.eg.db_" version ".tar.gz"))
              (sha256
               (base32
                "0wh1pm3npdg7070875kfgiid3bqkz3q7rq6snhk6bxfvph00298y"))))
    (properties
     `((upstream-name . "org.Mm.eg.db")))
    (build-system r-build-system)
    (propagated-inputs
     `(("r-annotationdbi" ,r-annotationdbi)))
    (home-page "http://www.bioconductor.org/packages/org.Mm.eg.db/")
    (synopsis "Genome wide annotation for Mouse")
    (description
     "This package provides mappings from Entrez gene identifiers to various
annotations for the genome of the model mouse Mus musculus.")
    (license license:artistic2.0)))

(define-public r-qtl
 (package
  (name "r-qtl")
  (version "1.38-4")
  (source
   (origin
    (method url-fetch)
    (uri (string-append "mirror://cran/src/contrib/qtl_"
                        version ".tar.gz"))
    (sha256
     (base32
      "0rv9xhp8lyldpgwxqirhyjqvg07dr5x4x1x2jpyj37dada9ccyx3"))))
  (build-system r-build-system)
  (home-page "http://rqtl.org/")
  (synopsis "R package for analyzing QTL experiments in genetics")
  (description "R/qtl is an extension library for the R statistics
system.  It is used to analyze experimental crosses for identifying
genes contributing to variation in quantitative traits (so-called
quantitative trait loci, QTLs).

Using a hidden Markov model, R/qtl allows to estimate genetic maps, to
identify genotyping errors, and to perform single-QTL and two-QTL,
two-dimensional genome scans.")
  (license license:gpl3)))
