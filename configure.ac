AC_INIT([global], [1], [gmarcais@umd.edu])
AC_CANONICAL_HOST
AC_CONFIG_MACRO_DIR([m4])
AM_INIT_AUTOMAKE([subdir-objects foreign parallel-tests color-tests])
AM_SILENT_RULES([yes])
AC_CONFIG_SRCDIR([.])
AC_CONFIG_HEADERS([config.h])
AC_PROG_LIBTOOL

# Change default compilation flags
AC_SUBST([ALL_CXXFLAGS], [-std=c++0x])
CXXFLAGS="-std=c++0x $CXXFLAGS"
AC_LANG(C++)
AC_PROG_CC
AC_PROG_CXX

# Checks for libraries.
AC_CHECK_LIB([pthread], [pthread_create])
AC_SEARCH_LIBS([clock_gettime], [rt], [AC_DEFINE([HAVE_CLOCK_GETTIME], [1], [Define to 1 if you have the `clock_gettime' function])])

# Checks for Jellyfish module
PKG_CHECK_MODULES([JELLYFISH2_0], [jellyfish-2.0])
JELLYFISH_VERSION=$(pkg-config --modversion jellyfish-2.0)
AC_SUBST([JELLYFISH_VERSION])
AC_ARG_VAR([JELLYFISH], [Jellyfish executable absolute path (default to looking in PATH)])
AS_IF([test "x$JELLYFISH" = "x"], [AC_PATH_PROG([JELLYFISH], [jellyfish], [false])])

# On MacOS X, use _NSGetExecutablePath to find path to own executable
AC_MSG_CHECKING([for _NSGetExecutablePath])
AC_LINK_IFELSE([AC_LANG_PROGRAM([[#include <mach-o/dyld.h>]],
                                   [[_NSGetExecutablePath(0, 0);]])],
                  [AC_MSG_RESULT([yes])]
                  [AC_DEFINE([HAVE_NSGETEXECUTABLEPATH], [1], [Used to find executable path on MacOS X])],
                  [AC_MSG_RESULT([no])])

# AC_CHECK_LIB(boost_regex, toto)
AC_MSG_CHECKING([for libboost_regex])
AC_LINK_IFELSE([AC_LANG_PROGRAM([#include <boost/regex.hpp>],
                                [boost::regex regexp])],
                                [AC_MSG_RESULT([yes])] [AC_DEFINE([HAVE_BOOST_REGEX], 1, [Have libboost_regex])]
                                                       [have_boost=true],
                                [AC_MSG_RESULT([no])]
                                [have_boost=false])
AM_CONDITIONAL([BOOST_REGEX], [test x$have_boost = xtrue])

# Checks for library functions.
AC_FUNC_MMAP
AC_CHECK_FUNCS([mremap])

# Use valgrind to check memory allocation with mmap
AC_ARG_ENABLE([valgrind],
              [AS_HELP_STRING([--enable-valgrind], [Instrument mmap memory allocation with valgrind])])
AS_IF([test "x$enable_valgrind" = xyes],
      [AC_DEFINE([HAVE_VALGRIND], [1], [Define is using Valgrind])]
      [PKG_CHECK_MODULES([VALGRIND], [valgrind >= 1.8.0])])

# Check for builtin functions
AC_MSG_CHECKING([for __builtin_prefetch])
AC_LINK_IFELSE([AC_LANG_PROGRAM([[int x = 0;]],
                                [[__builtin_prefetch(&x);]])],
               [AC_MSG_RESULT([yes])]
               [AC_DEFINE([HAVE_BUILTIN_PREFETCH], [1], [Defined if __builtin_prefetch is supported])],
               [AC_MSG_RESULT([no])])

# From Quorum
# --enable-relative-paths
AC_ARG_ENABLE([relative-paths],
              [AC_HELP_STRING([--enable-relative-paths], [store relative paths in quorum Perl script])])
AM_CONDITIONAL([RELATIVE_PATHS], [test x$enable_relative_paths = xyes])

# --with-relative-jf-path
AC_ARG_WITH([relative-jf-path],
            [AC_HELP_STRING([--with-relative-jf-path], [relative path from quorum to jellyfish (use an absolute path if not given. default to "." if given with no argument)])],
            [case "$withval" in (yes) with_relative_jf_path="jellyfish" ;; (no) with_relative_jf_path= ;; (*) with_relative_jf_path=$withval/jellyfish ;; esac],
            [with_relative_jf_path= ])
AC_SUBST([RELATIVE_JF_PATH], $with_relative_jf_path)
AM_CONDITIONAL([HAVE_RELATIVE_JF_PATH], [test x$with_relative_jf_path != x])

AC_CHECK_TYPE([__int128],
              [AC_DEFINE([HAVE_INT128], [1], [Define if type __int128 is supported])])


# Check for yaggo
AC_ARG_VAR([YAGGO], [Yaggo switch parser generator])
AS_IF([test "x$YAGGO" = "x"], [AC_PATH_PROG([YAGGO], [yaggo], [false])])

AC_CONFIG_FILES([Makefile prepare/Makefile ufasta/Makefile PacBio/Makefile quorum/Makefile SuperReads/Makefile SOAPdenovo2/Makefile])
AC_OUTPUT
