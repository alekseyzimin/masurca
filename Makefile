# MaSurCA version
NAME=MaSuRCA
VERSION = 2.3.2
NCPU = $(shell grep -c '^processor' /proc/cpuinfo 2>/dev/null || sysctl hw.ncpu 2>/dev/null || echo 1)

# Component versions
COMPONENTS = jellyfish SuperReads quorum

# # Defines variables jellyfish-2.0_VERSION, etc.
# $(foreach comp,$(COMPONENTS),$(eval $(comp)_VERSION=$(shell autom4te --language=autoconf --trace 'AC_INIT:$$2' $(comp)/configure.ac)))
# jellyfish_DIR = jellyfish-$(jellyfish_VERSION)
# SuperReads_DIR = SuperReads-$(SuperReads_VERSION)
# quorum_DIR = quorum-$(quorum_VERSION)

##################################################################
# Rules for compilling a working distribution in build (or DEST) #
##################################################################
UPD_INSTALL = $(shell which install) -C
PWD = $(shell pwd)
DEST = $(PWD)/build
SUBDIRS = $(foreach i,$(COMPONENTS) CA,$(DEST)/$(i))
check_config = test -f $@/Makefile -a $@/Makefile -nt $(1)/configure.ac || (cd $@; $(PWD)/$(1)/configure --prefix=$(DEST)/inst $(2))
make_install = $(MAKE) -C $@ -j $(NCPU) install INSTALL="$(UPD_INSTALL)"

# Get info of where things are installed
get_var = $(shell make -s -C $(DEST)/$(1) print-$(2))
BINDIR = $(call get_var,jellyfish,bindir)
LIBDIR = $(call get_var,jellyfish,libdir)
PKGCONFIGDIR = $(call get_var,jellyfish,pkgconfigdir)

.PHONY: subdirs $(SUBDIRS)

all: $(SUBDIRS)

pull:
	for i in $(COMPONENTS) wgs; do (cd $$i; git checkout develop; git pull); done

$(DEST)/jellyfish: jellyfish/configure
	mkdir -p $@
	$(call check_config,jellyfish,--program-suffix=-2.0)
	$(call make_install)

$(DEST)/SuperReads: SuperReads/configure
	mkdir -p $@
	$(call check_config,SuperReads,PKG_CONFIG_PATH=$(PKGCONFIGDIR))
	$(call make_install)

$(DEST)/quorum: quorum/configure
	mkdir -p $@
	$(call check_config,quorum,--enable-relative-paths JELLYFISH=$(BINDIR)/jellyfish-2.0 PKG_CONFIG_PATH=$(PKGCONFIGDIR))
	$(call make_install)

$(DEST)/CA: wgs/build-default/tup.config wgs/.tup/db
	test -d $@ || (mkdir -p $(PWD)/wgs/build-default; ln -sf $(PWD)/wgs/build-default $@)
	cd $@; export LD_RUN_PATH=$(LIBDIR); tup upd
	mkdir -p $(DEST)/inst/CA/Linux-amd64; rsync -a --delete $@/bin $(DEST)/inst/CA/Linux-amd64

wgs/build-default/tup.config:
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

#####################################
# Display version of all components #
#####################################
# .PHONY: versions
# versions:
# 	@echo $(foreach comp,$(COMPONENTS),$(comp):$($(comp)_VERSION):$($(comp)_DIR))


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
DISTDIR = $(NAME)-$(VERSION)
.PHONY: clean_distdir
clean_distdir:
	rm -rf $(DISTDIR)
	mkdir -p $(DISTDIR)

$(DISTDIR)/%:
	$(MAKE) -C $(DEST)/$* -j $(NCPU) distdir distdir=$(shell pwd)/$@

$(DISTDIR)/CA:
	(cd wgs; git archive --format=tar --prefix=CA/ HEAD) | (cd $(dir $@); tar -x)

$(DISTDIR)/install.sh: install.sh.in
	install $< $@

$(DISTDIR)/PkgConfig.pm: PkgConfig.pm
	install $< $@

$(DISTDIR).tar.gz: clean_distdir $(foreach comp,$(COMPONENTS),$(DISTDIR)/$(comp)) $(DISTDIR)/CA $(DISTDIR)/install.sh $(DISTDIR)/PkgConfig.pm
	tar -zcf $@ $(DISTDIR)

$(DISTDIR).tar.bz: clean_distdir $(foreach comp,$(COMPONENTS),$(DISTDIR)/$(comp)) $(DISTDIR)/CA $(DISTDIR)/install.sh $(DISTDIR)/PkgConfig.pm
	tar -jcf $@ $(DISTDIR)

$(DISTDIR).tar.xz: clean_distdir $(foreach comp,$(COMPONENTS),$(DISTDIR)/$(comp)) $(DISTDIR)/CA $(DISTDIR)/install.sh $(DISTDIR)/PkgConfig.pm
	tar -Jcf $@ $(DISTDIR)

.PHONY: dist
dist: $(DISTDIR).tar.gz $(DISTDIR).tar.xz

###############################
# Rules for compiling locally #
###############################
.PHONY: install clean_test_install

clean_test_install:
	rm -rf tests/$(DISTDIR)
	mkdir -p tests

tests/$(DISTDIR): $(DISTDIR).tar.gz
	tar zxf $< -C tests

install: clean_test_install tests/$(DISTDIR)
	cd tests/$(DISTDIR); ./install.sh
	@echo -e "**************************************************\n* Installation of $(DISTDIR) successful\n* Distribution available as $(DISTDIR).tar.gz\n**************************************************"

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
	cd build-static/CA/src; make ALL_STATIC=1
	touch $@

# SuperReads and Quorum rely on jellyfish being installed
build-static/Quorum/Makefile: build-static/jellyfish-2.0.installed
build-static/SuperReads/Makefile: build-static/jellyfish-2.0.installed

$(STATICDIR).tar.gz: $(foreach comp,$(COMPONENTS),build-static/$(comp).installed) build-static/CA.installed
	rm -rf $(STATICDIR); mkdir -p $(STATICDIR) $(STATICDIR)/Linux-amd64
	cp -R build-static/install/bin $(STATICDIR)
	cp -R build-static/CA/Linux-amd64/bin $(STATICDIR)/Linux-amd64
	tar zcf $@ $(STATICDIR)

static: $(STATICDIR).tar.gz
