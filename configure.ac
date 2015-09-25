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

# Flags for Jellyfish
AC_SUBST([JELLYFISH2_0_CFLAGS], ['-I$(includedir)/jellyfish-1'])
AC_SUBST([JELLYFISH2_0_LIBS], ['-L$(libdir) -ljellyfish-2.0'])
AC_SUBST([JELLYFISH], ['$(bindir)/jellyfish'])

# Flags for samtools
AC_SUBST([SAMTOOLS_CFLAGS], ['-I$(includedir)/samtools'])
AC_SUBST([SAMTOOLS_LIBS], ['-L$(libdir) -lbam'])

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

# Check for zlib
AC_CHECK_HEADER([zlib.h], [], [AC_MSG_FAILURE([Cannot find zlib.h header. Install zlib development files (e.g. zlib1g-dev)])])
AC_CHECK_LIB([z], [zlibVersion], [], [AC_MSG_FAILURE([Cannot find zlib library. Install zlib libray])])

# Check bzip2 library
AC_CHECK_HEADER([bzlib.h], [], [AC_MSG_FAILURE([Cannot find bzilb.h header. Install bzip2 development files (e.g. bzip2-devel)])])
AC_CHECK_LIB([bz2], [BZ2_bzlibVersion], [], [AC_MSG_FAILURE([Cannot find bzip2 library. Install bzip2 library])])


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

# For Quorum
AM_CONDITIONAL([RELATIVE_PATHS], [true])
AM_CONDITIONAL([HAVE_RELATIVE_JF_PATH], [false])

# For Samtools, don't compile ncurses stuff
AC_SUBST([CURSES_LIB], [0])

AC_CHECK_TYPE([__int128],
              [AC_DEFINE([HAVE_INT128], [1], [Define if type __int128 is supported])])


# Check for yaggo
AC_ARG_VAR([YAGGO], [Yaggo switch parser generator])
AS_IF([test "x$YAGGO" = "x"], [AC_PATH_PROG([YAGGO], [yaggo], [false])])

# Check for swig and enable Perl bindings
# --enable-swig
AC_ARG_ENABLE([swig],
              [AC_HELP_STRING([--enable-swig], [enable development of swig binding])])
AS_IF([test x$enable_swig = xyes],
      [AX_PKG_SWIG([3.0.0], [], [AC_MSG_FAILURE([SWIG version 3 is required])])])
AS_IF([test -n "$SWIG"],
      [SWIG_ENABLE_CXX])
AM_CONDITIONAL([HAVE_SWIG], [test -n "$SWIG"])
AC_SUBST([MAYBE_SWIG], [swig])
# Conf Perl
PERL_EXT_LIB='$(libdir)/perl'
AX_PERL_EXT
AM_CONDITIONAL([PERL_BINDING], [true])
# Disable others
AM_CONDITIONAL([PYTHON_BINDING], [false])
AM_CONDITIONAL([RUBY_BINDING], [false])

# Output configuration files
AC_CONFIG_FILES([Makefile samtools/Makefile jellyfish/Makefile jellyfish/jellyfish-2.0.pc jellyfish/swig/Makefile])
AC_CONFIG_FILES([prepare/Makefile ufasta/Makefile quorum/Makefile SuperReads/Makefile SOAPdenovo2/Makefile])
AC_CONFIG_FILES([PacBio/Makefile])
AC_CONFIG_FILES([MUMmer/Makefile MUMmer/tests/Makefile MUMmer/swig/Makefile])
AC_OUTPUT
