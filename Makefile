# MaSurCA version
NAME=MaSuRCA
VERSION = 3.0.0
NCPU = $(shell grep -c '^processor' /proc/cpuinfo 2>/dev/null || sysctl hw.ncpu 2>/dev/null || echo 1)

# Component versions
COMPONENTS = jellyfish SuperReads quorum PacBio CA CA8

##################################################################
# Rules for compilling a working distribution in build (or DEST) #
##################################################################
UPD_INSTALL = $(shell which install) -C
PWD = $(shell pwd)
PREF ?= $(PWD)
BUILDDIR ?= $(PREF)/build
SUBDIRS = $(foreach i,$(COMPONENTS),$(BUILDDIR)/$(i))
check_config = test -f $@/Makefile -a $@/Makefile -nt $(1)/configure.ac || (cd $@; $(PWD)/$(1)/configure --prefix=$(BUILDDIR)/inst $(2))
make_install = $(MAKE) -C $@ -j $(NCPU) install INSTALL="$(UPD_INSTALL)"

# Get info of where things are installed
get_var = $(shell make -s -C $(BUILDDIR)/$(1) print-$(2))
BINDIR = $(call get_var,jellyfish,bindir)
LIBDIR = $(call get_var,jellyfish,libdir)
PKGCONFIGDIR = $(call get_var,jellyfish,pkgconfigdir)

.PHONY: subdirs $(SUBDIRS)

all: $(SUBDIRS)

# Not all submodule use develop
# pull:
# 	for i in $(COMPONENTS); do (cd $$i; git checkout develop; git pull); done

$(BUILDDIR)/jellyfish: jellyfish/configure
	mkdir -p $@
	$(call check_config,jellyfish,--program-suffix=-2.0)
	$(call make_install)

$(BUILDDIR)/SuperReads: SuperReads/configure
	mkdir -p $@
	$(call check_config,SuperReads,PKG_CONFIG_PATH=$(PKGCONFIGDIR))
	$(call make_install)

$(BUILDDIR)/quorum: quorum/configure
	mkdir -p $@
	$(call check_config,quorum,--enable-relative-paths JELLYFISH=$(BINDIR)/jellyfish-2.0 PKG_CONFIG_PATH=$(PKGCONFIGDIR))
	$(call make_install)

$(BUILDDIR)/PacBio: PacBio/configure
	mkdir -p $@
	$(call check_config,PacBio,PKG_CONFIG_PATH=$(PKGCONFIGDIR))
	$(call make_install)

$(BUILDDIR)/CA: CA/build-default/tup.config CA/.tup/db
	test -d $@ || (mkdir -p $(PWD)/CA/build-default; ln -sf $(PWD)/CA/build-default $@)
	cd $@; export LD_RUN_PATH=$(LIBDIR); tup upd
	mkdir -p $(BUILDDIR)/inst/CA/Linux-amd64; rsync -a --delete $@/bin $(BUILDDIR)/inst/CA/Linux-amd64

$(BUILDDIR)/CA8:
	cd CA8/kmer && make install
	cd CA8/samtools && make
	cd CA8/src && make
	mkdir -p $(BUILDDIR)/inst/CA8/Linux-amd64; rsync -a --delete CA8/Linux-amd64/bin $(BUILDDIR)/inst/CA8/Linux-amd64

CA/build-default/tup.config:
	mkdir -p $(dir $@)
	(export PKG_CONFIG_PATH=$(PKGCONFIGDIR); \
	 echo "CONFIG_CXXFLAGS=-Wno-error=format -Wno-error=unused-function -Wno-error=unused-variable -fopenmp"; \
         echo "CONFIG_LDFLAGS=-fopenmp"; \
	 echo -n "CONFIG_JELLYFISH_CFLAGS="; pkg-config --cflags jellyfish-2.0; \
	 echo -n "CONFIG_JELLYFISH_LIBS="; pkg-config --libs jellyfish-2.0 \
	) > $@

%/.tup/db:
	cd $*; tup init

%/configure: %/configure.ac
	cd $*; autoreconf -fi

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

$(DISTDIST)/%:
	$(MAKE) -C $(BUILDDIR)/$* -j $(NCPU) distdir distdir="$@"

$(DISTDIST)/CA:
	(cd $(notdir $@); git archive --format=tar --prefix=$(notdir $@)/ HEAD) | (cd $(dir $@); tar -x)

$(DISTDIST)/CA8:
	(cd $(notdir $@); git archive --format=tar --prefix=$(notdir $@)/ HEAD) | (cd $(dir $@); tar -x)

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

.PHONY: dist
dist: $(DISTNAME).tar.gz $(DISTNAME).tar.xz

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
