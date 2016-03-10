# GNU Guix --- Functional package management for GNU
# Copyright © 2012, 2013, 2014, 2015, 2016 Ludovic Courtès <ludo@gnu.org>
# Copyright © 2013 Nikita Karetnikov <nikita@karetnikov.org>
#
# This file is part of GNU Guix.
#
# GNU Guix is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or (at
# your option) any later version.
#
# GNU Guix is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

#
# Test the `guix package' command-line utility.
#

guix package --version

readlink_base ()
{
    basename `readlink "$1"`
}

module_dir="t-guix-package-$$"
profile="t-profile-$$"
tmpfile="t-guix-package-file-$$"
rm -f "$profile" "$tmpfile"

trap 'rm -f "$profile" "$profile-"[0-9]* "$tmpfile"; rm -rf "$module_dir" t-home-'"$$" EXIT

# Use `-e' with a non-package expression.
if guix package --bootstrap -e +;
then false; else true; fi

guix package --bootstrap -p "$profile" -i guile-bootstrap
test -L "$profile" && test -L "$profile-1-link"
test -f "$profile/bin/guile"

# Make sure the profile is a GC root.
guix gc --list-live | grep "`readlink "$profile-1-link"`"

# Installing the same package a second time does nothing.
guix package --bootstrap -p "$profile" -i guile-bootstrap
test -L "$profile" && test -L "$profile-1-link"
! test -f "$profile-2-link"
test -f "$profile/bin/guile"

# No search path env. var. here.
guix package -p "$profile" --search-paths
guix package -p "$profile" --search-paths | grep '^export PATH='
test "`guix package -p "$profile" --search-paths | wc -l`" = 1  # $PATH
( set -e; set -x;						\
  eval `guix package --search-paths=prefix -p "$PWD/$profile"`;	\
  test "`type -P guile`" = "$PWD/$profile/bin/guile" ;		\
  type -P rm )

# Exit with 1 when a generation does not exist.
if guix package -p "$profile" --delete-generations=42;
then false; else true; fi

# Exit with 0 when trying to delete the zeroth generation.
guix package -p "$profile" --delete-generations=0

# Make sure multiple arguments to -i works.
guix package --bootstrap -i guile gcc -p "$profile" -n

# Make sure the `:' syntax works.
guix package --bootstrap -i "glibc:debug" -p "$profile" -n

# Make sure nonexistent outputs are reported.
guix package --bootstrap -i "guile-bootstrap:out" -p "$profile" -n
if guix package --bootstrap -i "guile-bootstrap:does-not-exist" -p "$profile" -n;
then false; else true; fi
if guix package --bootstrap -i "guile-bootstrap:does-not-exist" -p "$profile";
then false; else true; fi

# Check whether `--list-available' returns something sensible.
guix package -p "$profile" -A 'gui.*e' | grep guile

# Check whether `--show' returns something sensible.
guix package --show=guile | grep "^name: guile"

# Ensure `--show' doesn't fail for packages with non-package inputs.
guix package --show=texlive

# Search.
LC_MESSAGES=C
export LC_MESSAGES
test "`guix package -s "An example GNU package" | grep ^name:`" = \
    "name: hello"
test -z "`guix package -s "n0t4r341p4ck4g3"`"

# Search with one and then two regexps.
# First we get printed circuit boards *and* board games.
guix package -s '\<board\>' > "$tmpfile"
grep '^name: pcb' "$tmpfile"
grep '^name: gnubg' "$tmpfile"

# Second we get only board games.
guix package -s '\<board\>' -s game > "$tmpfile"
grep -v '^name: pcb' "$tmpfile" > /dev/null
grep '^name: gnubg' "$tmpfile"

rm -f "$tmpfile"

# Make sure `--search' can display all the packages.
guix package --search="" > /dev/null

# There's no generation older than 12 months, so the following command should
# have no effect.
generation="`readlink_base "$profile"`"
if guix package -p "$profile" --delete-generations=12m;
then false; else true; fi
test "`readlink_base "$profile"`" = "$generation"

# The following command should not delete the current generation, even though
# it matches the given pattern (see <http://bugs.gnu.org/19978>.)  And since
# there's nothing else to delete, it should just fail.
guix package --list-generations -p "$profile"
if guix package --bootstrap -p "$profile" --delete-generations=1..
then false; else true; fi
test "`readlink_base "$profile"`" = "$generation"

# Make sure $profile is a GC root at this point.
real_profile="`readlink -f "$profile"`"
if guix gc -d "$real_profile"
then false; else true; fi
test -d "$real_profile"

# Now, let's remove all the symlinks to $real_profile, and make sure
# $real_profile is no longer a GC root.
rm "$profile" "$profile"-[0-9]-link
guix gc -d "$real_profile"
[ ! -d "$real_profile" ]

#
# Try with the default profile.
#

XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_CACHE_HOME
HOME="$PWD/t-home-$$"
export HOME

mkdir -p "$HOME"

# Get the canonical directory name so that 'guix package' recognizes it.
HOME="`cd $HOME; pwd -P`"

guix package --bootstrap -i guile-bootstrap
test -L "$HOME/.guix-profile"
test -f "$HOME/.guix-profile/bin/guile"

# Move to the empty profile.
default_profile="`readlink "$HOME/.guix-profile"`"
for i in `seq 1 3`
do
    # Make sure the current generation is a GC root.
    profile_link="`readlink "$default_profile"`"
    guix gc --list-live | grep "`readlink "$profile_link"`"

    guix package --bootstrap --roll-back
    ! test -f "$HOME/.guix-profile/bin"
    ! test -f "$HOME/.guix-profile/lib"
    test "`readlink "$default_profile"`" = "$default_profile-0-link"
done

# Check whether '-p ~/.guix-profile' makes any difference.
# See <http://bugs.gnu.org/17939>.
if test -e "$HOME/.guix-profile-0-link"; then false; fi
if test -e "$HOME/.guix-profile-1-link"; then false; fi
guix package --bootstrap -p "$HOME/.guix-profile" -i guile-bootstrap
if test -e "$HOME/.guix-profile-1-link"; then false; fi
guix package --bootstrap --roll-back -p "$HOME/.guix-profile"
if test -e "$HOME/.guix-profile-0-link"; then false; fi

# Extraneous argument.
if guix package install foo-bar;
then false; else true; fi

# Make sure the "broken pipe" doesn't yield an error.
# Note: 'pipefail' is a Bash-specific option.
set -o pipefail || true
guix package -A g | head -1 2> "$HOME/err1"
guix package -I | head -1 2> "$HOME/err2"
test "`cat "$HOME/err1" "$HOME/err2"`" = ""

# Make sure '-L' extends the package module search path.
mkdir "$module_dir"

cat > "$module_dir/foo.scm"<<EOF
(define-module (foo)
  #:use-module (guix packages)
  #:use-module (gnu packages emacs))

(define-public x
  (package (inherit emacs)
    (name "emacs-foo-bar")
    (version "42")))
EOF

guix package -A emacs-foo-bar -L "$module_dir" | grep 42
guix package -i emacs-foo-bar@42 -n -L "$module_dir"

# Same thing using the 'GUIX_PACKAGE_PATH' environment variable.
GUIX_PACKAGE_PATH="$module_dir"
export GUIX_PACKAGE_PATH
guix package -A emacs-foo-bar | grep 42
guix package -i emacs-foo-bar@42 -n

# Make sure patches that live under $GUIX_PACKAGE_PATH are found.
cat > "$module_dir/emacs.patch"<<EOF
This is a fake patch.
EOF
cat > "$module_dir/foo.scm"<<EOF
(define-module (foo)
  #:use-module (guix packages)
  #:use-module (gnu packages)
  #:use-module (gnu packages emacs))

(define-public x
  (package (inherit emacs)
    (source (origin (inherit (package-source emacs))
              (patches (list (search-patch "emacs.patch")))))
    (name "emacs-foo-bar-patched")
    (version "42")))

(define-public y
  (package (inherit emacs)
    (name "super-non-portable-emacs")
    (supported-systems '("foobar64-hurd"))))
EOF
guix package -i emacs-foo-bar-patched -n

# Same when -L is used.
( unset GUIX_PACKAGE_PATH;					\
  guix package -L "$module_dir" -i emacs-foo-bar-patched -n )

# Make sure installing from a file works.
cat > "$module_dir/package.scm"<<EOF
(use-modules (gnu))
(use-package-modules bootstrap)

%bootstrap-guile
EOF
guix package --bootstrap --install-from-file="$module_dir/package.scm"

# This one should not show up in searches since it's no supported on the
# current system.
test "`guix package -A super-non-portable-emacs`" = ""
test "`guix package -s super-non-portable-emacs | grep ^systems:`" = "systems: "

unset GUIX_PACKAGE_PATH

# Using 'GUIX_BUILD_OPTIONS'.
available="`guix package -A | sort`"
GUIX_BUILD_OPTIONS="--dry-run --no-grafts"
export GUIX_BUILD_OPTIONS

# Make sure $GUIX_BUILD_OPTIONS is not simply appended to the command-line,
# which would break 'guix package -A' and similar.
available2="`guix package -A | sort`"
test "$available2" = "$available"
guix package -I

# Restore '--no-grafts', which makes sure we don't end up building stuff when
# '--dry-run' is passed.
GUIX_BUILD_OPTIONS="--no-grafts"

# Applying a manifest file.
cat > "$module_dir/manifest.scm"<<EOF
(use-package-modules bootstrap)

(packages->manifest (list %bootstrap-guile))
EOF
guix package --bootstrap -m "$module_dir/manifest.scm"
guix package -I | grep guile
test `guix package -I | wc -l` -eq 1

# Error reporting.
cat > "$module_dir/manifest.scm"<<EOF
(use-package-modules bootstrap)
(packages->manifest
  (list %bootstrap-guile
        wonderful-package-that-does-not-exist))
EOF
if guix package --bootstrap -n -m "$module_dir/manifest.scm" \
	2> "$module_dir/stderr"
then false
else
    cat "$module_dir/stderr"
    grep "manifest.scm:[1-3]:.*[Uu]nbound variable.*wonderful-package" \
	 "$module_dir/stderr"
fi
