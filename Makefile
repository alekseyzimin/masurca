# MaSurCA version
NAME=MaSuRCA
VERSION = 2.0.3.1
NCPU = $(shell grep -c '^processor' /proc/cpuinfo)

# Component versions
COMPONENTS = jellyfish-1.1 jellyfish-2.0 SuperReads quorum
# Defines variables jellyfish-1.1_VERSION, etc.
$(foreach comp,$(COMPONENTS),$(eval $(comp)_VERSION=$(shell autom4te --language=autoconf --trace 'AC_INIT:$$2' $(comp)/configure.ac)))
jellyfish-1.1_DIR = jellyfish-$(jellyfish-1.1_VERSION)
jellyfish-2.0_DIR = jellyfish-$(jellyfish-2.0_VERSION)
SuperReads_DIR = SuperReads-$(SuperReads_VERSION)
quorum_DIR = quorum-$(quorum_VERSION)

UPD_INSTALL = $(shell which install) -C


.PHONY: versions
versions:
	@echo $(foreach comp,$(COMPONENTS),$(comp):$($(comp)_VERSION):$($(comp)_DIR))

##################################################################
# Rules for compilling a working distribution in build (or DEST) #
##################################################################
PWD = $(shell pwd)
DEST = $(PWD)/build
SUBDIRS = $(foreach i,jellyfish2 jellyfish1 SuperReads quorum CA_kmer CA,$(DEST)/$(i))
check_config = test -f $@/Makefile -a $@/Makefile -nt $(1)/configure.ac || (cd $@; $(PWD)/$(1)/configure --prefix=$(DEST)/inst $(2))
make_install = $(MAKE) -C $@ -j $(NCPU) install INSTALL="$(UPD_INSTALL)"
.PHONY: subdirs $(SUBDIRS)

subdirs: $(SUBDIRS)

$(DEST)/jellyfish2: jellyfish-2.0/configure
	mkdir -p $@
	$(call check_config,jellyfish-2.0,--program-suffix=-2.0)
	$(call make_install)

$(DEST)/jellyfish1: jellyfish-1.1/configure
	mkdir -p $@
	$(call check_config,jellyfish-1.1,)
	$(call make_install)

$(DEST)/SuperReads: SuperReads/configure
	mkdir -p $@
	$(call check_config,SuperReads,PKG_CONFIG_PATH=$(shell make -s -C $(DEST)/jellyfish2 print-pkgconfigdir))
	$(call make_install)

$(DEST)/quorum: quorum/configure
	mkdir -p $@
	$(call check_config,quorum,--with-relative-jf-path --enable-relative-paths PKG_CONFIG_PATH=$(shell make -s -C $(DEST)/jellyfish1 print-pkgconfigdir))
	$(call make_install)

$(DEST)/CA_kmer:
	test -f $@/Makefile || (ln -sf $(PWD)/wgs/kmer $@; cd $@; ./configure.sh)
	cd $@; make; make install

$(DEST)/CA: wgs/build-default/tup.config wgs/.tup/db
	test -d $@ || (mkdir -p $(PWD)/wgs/build-default; ln -sf $(PWD)/wgs/build-default $@)
	cd $@; tup upd
	mkdir -p $(DEST)/inst/CA/Linux-amd64; rsync -a $@/bin $(DEST)/inst/CA/Linux-amd64

wgs/build-default/tup.config:
	mkdir -p $(dir $@)
	(echo "CONFIG_CXXFLAGS=-Wno-error=format -Wno-error=unused-function -Wno-error=unused-variable"; \
	 echo "CONFIG_KMER=$(PWD)/wgs/kmer/Linux-amd64") > $@

%/.tup/db:
	cd $*; tup init

%/configure: %/configure.ac %/Makefile.am
	cd $*; autoreconf -fi

#############################################
# Tag all components with MaSuRCA's version #
#############################################
tag:
	git submodule foreach git tag -f $(NAME)-$(VERSION)
	git tag -f $(NAME)-$(VERSION)
	git submodule foreach git push --tags 
#	git foreach git push --tags

###########################################
# Rules for making a tarball distribution #
###########################################
define Makefile_template =
build-dist/$(1)/Makefile: $(1)/configure
	mkdir -p $$(dir $$@)
	@conf=`readlink -f $$<`; ipath=`pwd`/build/install; echo $$$$conf; cd $$(dir $$@); $$$$conf
endef
$(foreach comp,$(COMPONENTS),$(eval $(call Makefile_template,$(comp))))

define tarball_template =
%/$($(1)_DIR).tar.gz: build-dist/$(1)/Makefile
	mkdir -p $$*
	make -C $$(dir $$<) -j $(NCPU) dist; mv $$(dir $$<)$$(notdir $$@) $$@
endef
$(foreach comp,$(COMPONENTS),$(eval $(call tarball_template,$(comp))))

%/CA.tar.gz:
	(cd wgs; git archive --format=tar --prefix=CA/ HEAD) | gzip > $@

%/install.sh: install.sh.in
	mkdir -p $(dir $@)
	sed $(foreach comp,$(COMPONENTS), -e 's/@$(comp)_DIR@/$($(comp)_DIR)/') $< > $@	
	chmod a+rx $@

%/PkgConfig.pm: PkgConfig.pm
	cp $< $@
	chmod a+rx $@

DISTDIR = $(NAME)-$(VERSION)
$(DISTDIR).tar.gz: $(foreach comp,$(COMPONENTS),$(DISTDIR)/$($(comp)_DIR).tar.gz) $(DISTDIR)/CA.tar.gz $(DISTDIR)/install.sh $(DISTDIR)/PkgConfig.pm
	for i in $^; do case $$i in (*.tar.gz) tar -zxf $$i -C $(DISTDIR); (*) ;; esac; done
	tar -zcf $@ --exclude='*.tar.gz' $(DISTDIR)

.PHONY: dist
dist: $(DISTDIR).tar.gz

###############################
# Rules for compiling locally #
###############################
.PHONY: install
tests/$(DISTDIR): $(DISTDIR).tar.gz
	mkdir -p tests
	tar zxf $< -C tests

install: tests/$(DISTDIR)
	cd $<; ./install.sh

#########################################
# Rules to create a static distribution #
#########################################
.PHONY: static
STATICDIR=$(NAME)-$(VERSION)-static-$(shell uname -p)
define Makefile_static_template =
build-static/$(1)/Makefile: $(1)/configure
	mkdir -p $$(dir $$@)
	@conf=`readlink -f $$<`; ipath=`pwd`/build-static/install; echo $$$$conf; cd $$(dir $$@); $$$$conf --prefix=$$$$ipath --enable-all-static --enable-relative-paths --with-relative-jf-path PKG_CONFIG_PATH=$$$$ipath/lib/pkgconfig
endef
$(foreach comp,$(COMPONENTS),$(eval $(call Makefile_static_template,$(comp))))

define build_static_template =
build-static/$(1).installed: build-static/$(1)/Makefile
	cd $$(dir $$<); make -j $(NCPU) install
	touch $$@
endef
$(foreach comp,$(COMPONENTS),$(eval $(call build_static_template,$(comp))))

build-static/CA/src/Makefile: build-static/CA.tar.gz
	tar -zxf $< -C build-static

build-static/CA.installed: build-static/CA/src/Makefile
	cd build-static/CA/kmer; ./configure.sh; make; make install
	cd build-static/CA/src; make ALL_STATIC=1
	touch $@

# SuperReads and Quorum rely on jellyfish being installed
build-static/Quorum/Makefile: build-static/jellyfish-1.1.installed
build-static/SuperReads/Makefile: build-static/jellyfish-2.0.installed build-static/jellyfish-1.1.installed
build-static/jellyfish-1.1.installed: build-static/jellyfish-2.0.installed

$(STATICDIR).tar.gz: $(foreach comp,$(COMPONENTS),build-static/$(comp).installed) build-static/CA.installed
	rm -rf $(STATICDIR); mkdir -p $(STATICDIR) $(STATICDIR)/Linux-amd64
	cp -R build-static/install/bin $(STATICDIR)
	cp -R build-static/CA/Linux-amd64/bin $(STATICDIR)/Linux-amd64
	tar zcf $@ $(STATICDIR)

static: $(STATICDIR).tar.gz
