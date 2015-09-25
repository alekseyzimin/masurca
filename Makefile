# MaSurCA version
NAME=MaSuRCA
VERSION = 3.1.3
NCPU = $(shell grep -c '^processor' /proc/cpuinfo 2>/dev/null || sysctl hw.ncpu 2>/dev/null || echo 1)

# Component versions
COMPONENTS = global CA8 # jellyfish PacBio prepare ufasta quorum SuperReads SOAPdenovo2

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
global_config = test -f $@/Makefile -a $@/Makefile -nt configure.ac || (cd $@; $(PWD)/configure --prefix=$(BUILDDIR)/inst --libdir=$(LIBDIR) --enable-swig $(1))
make_install = $(MAKE) -C $@ -j $(NCPU) install INSTALL="$(UPD_INSTALL)"

# Get info of where things are installed
PKGCONFIGDIR = $(BUILDDIR)/inst/lib/pkgconfig

.PHONY: subdirs $(SUBDIRS)

all: $(SUBDIRS)

# Not all submodule use develop
# pull:
# 	for i in $(COMPONENTS); do (cd $$i; git checkout develop; git pull); done

$(BUILDDIR)/global: ./configure
	mkdir -p $@
	$(call global_config,)
	$(call make_install)

$(BUILDDIR)/CA8:
	[ -n "$$SKIP_CA8" ] || ( cd CA8/kmer && make install )
	[ -n "$$SKIP_CA8" ] || ( cd CA8/src && make )
	[ -n "$$SKIP_CA8" ] || ( mkdir -p $(BUILDDIR)/inst/CA8/Linux-amd64; rsync -a --delete CA8/Linux-amd64/bin $(BUILDDIR)/inst/CA8/Linux-amd64 )

SOAPdenovo2/build-$(BUILDNAME)/tup.config:
	mkdir -p $(dir $@)
	echo "CONFIG_CFLAGS=-O3" > $@



%/.tup/db:
	cd $*; tup init

configure: configure.ac
	autoreconf -fi

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

$(foreach d,CA8 SOAPdenovo2,$(eval $(call GIT_TAR,$d)))

$(DISTDIST)/install.sh: install.sh.in
	install $< $@

$(DISTDIST)/PkgConfig.pm: PkgConfig.pm
	install $< $@

DIST_COMPONENTS = $(foreach comp,$(COMPONENTS),$(DISTDIST)/$(comp))

$(DISTNAME).tar.gz: clean_distdir $(DIST_COMPONENTS) $(DISTDIST)/install.sh $(DISTDIST)/PkgConfig.pm
	tar -zcPf $@ --xform 's|^$(DISTDIR)||' $(DISTDIST)

$(DISTNAME).tar.bz: clean_distdir $(DIST_COMPONENTS) $(DISTDIST)/install.sh $(DISTDIST)/PkgConfig.pm
	tar -jcPf $@ --xform 's|^$(DISTDIR)||' $(DISTDIST)

$(DISTNAME).tar.xz: clean_distdir $(DIST_COMPONENTS) $(DISTDIST)/install.sh $(DISTDIST)/PkgConfig.pm
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
