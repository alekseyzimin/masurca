# MaSurCA version
NAME=MaSuRCA
VERSION = 4.1.1
NCPU = $(shell grep -c '^processor' /proc/cpuinfo 2>/dev/null || sysctl hw.ncpu 2>/dev/null || echo 1)

# Component versions
COMPONENTS = global

##################################################################
# Rules for compilling a working distribution in build (or DEST) #
##################################################################
UPD_INSTALL = $(shell which install) -C
PWD = $(shell pwd)
PREF ?= $(PWD)
# PREF ?= .
BUILDDIR ?= $(PREF)/build
BUILDNAME = $(notdir $(BUILDDIR))
BINDIR = $(BUILDDIR)/inst/bin
LIBDIR = $(BUILDDIR)/inst/lib
INCDIR = $(BUILDDIR)/inst/include

SUBDIRS = $(foreach i,$(COMPONENTS),$(BUILDDIR)/$(i))

# Get info of where things are installed
PKGCONFIGDIR = $(BUILDDIR)/inst/lib/pkgconfig

.PHONY: subdirs $(SUBDIRS)

all: $(SUBDIRS)

$(BUILDDIR)/global: ./configure
	mkdir -p $@
	test -f $@/Makefile -a $@/Makefile -nt configure.ac || \
	  (cd $@; $(PWD)/configure --prefix=$(BUILDDIR)/inst --libdir=$(LIBDIR) --enable-swig)
	$(MAKE) -C $@ -j $(NCPU) install-special INSTALL="$(UPD_INSTALL)"

configure: configure.ac
	autoreconf -fi

SHORTCUTS =  Flye CA8 jellyfish PacBio prepare ufasta quorum SuperReads SOAPdenovo2 MUMmer eviann
.PHONY: $(SHORTCUTS)
$(SHORTCUTS):
	$(MAKE) -C build/global/$@ install INSTALL="$(UPD_INSTALL)"


#############################################
# Tag all components with MaSuRCA's version #
#############################################
tag:
	git submodule foreach git tag -f $(NAME)-$(VERSION)
	git tag -f $(NAME)-$(VERSION)
	git submodule foreach git push --tags 
	git push --tags

###########################################
# Rules for making a tarball distribution #
###########################################
DISTNAME = $(NAME)-$(VERSION)
DISTDIR ?= $(PREF)/distdir
DISTDIST = $(DISTDIR)/$(DISTNAME)

.PHONY: clean_distdir
clean_distdir:
	rm -rf $(DISTDIST)
	mkdir -p $(DISTDIST)

# For the module that support 'make distdir', create directly the distribution directory
$(DISTDIST)/%:
	$(MAKE) -C $(BUILDDIR)/$* -j $(NCPU) distdir distdir="$@"

$(DISTDIST)/global:
	cd $(BUILDDIR)/global; make -j $(NCPU) dist && tar zxf global*.tar.gz -C $(DISTDIST)

# For the module that do not support 'make distdir', get a verbatim copy from git
define GIT_TAR =
$(DISTDIST)/$1:
	(cd $1; git archive --format=tar --prefix=$1/ HEAD) | (cd $(DISTDIST); tar -x)
endef

define TAR =
$(DISTDIST)/$1:
	(tar c $1) | (cd $(DISTDIST); tar -x)
endef

$(foreach d,Flye,$(eval $(call GIT_TAR,$d)))

$(DISTDIST)/install.sh: install.sh.in
	install $< $@

$(DISTDIST)/PkgConfig.pm: PkgConfig.pm
	install $< $@

$(DISTDIST)/LICENSE.txt: LICENSE.txt
	install $< $@

DIST_COMPONENTS = $(foreach comp,$(COMPONENTS),$(DISTDIST)/$(comp))

EXTRA_DIST = $(DISTDIST)/install.sh $(DISTDIST)/PkgConfig.pm $(DISTDIST)/LICENSE.txt

$(DISTNAME).tar.gz: clean_distdir $(DIST_COMPONENTS)  $(EXTRA_DIST)
	tar -zcPf $@ --xform 's|^$(DISTDIR)||' $(DISTDIST)

$(DISTNAME).tar.bz: clean_distdir $(DIST_COMPONENTS) $(EXTRA_DIST)
	tar -jcPf $@ --xform 's|^$(DISTDIR)||' $(DISTDIST)

$(DISTNAME).tar.xz: clean_distdir $(DIST_COMPONENTS) $(EXTRA_DIST)
	tar -JcPf $@ --xform 's|^$(DISTDIR)||' $(DISTDIST)

.PHONY: dist dist-all
dist: $(DISTNAME).tar.gz
dist-all: dist $(DISTNAME).tar.xz $(DISTNAME).tar.bz

###############################
# Rules for compiling locally #
###############################
.PHONY: install clean_test_install
TESTDIR ?= $(PREF)/tests

clean_test_install:
	rm -rf $(TESTDIR)/$(DISTNAME)
	mkdir -p $(TESTDIR)

$(TESTDIR): $(DISTNAME).tar.gz
	tar -zxf $< -C $(TESTDIR)

install: clean_test_install $(TESTDIR)
	cd $(TESTDIR)/$(DISTNAME); ./install.sh
#	@echo -e "**************************************************\n* Installation of $(DISTNAME) successful\n* Distribution available as $(DISTNAME).tar.gz\n**************************************************"
