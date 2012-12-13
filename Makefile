# MaSurCA version
VERSION = 1.9.2

NCPU = $(shell grep -c '^processor' /proc/cpuinfo)

# Component versions
COMPONENTS = jellyfish-1.1 jellyfish-2.0 SuperReads quorum
# Defines variables jellyfish-1.1_VERSION, etc.
$(foreach comp,$(COMPONENTS),$(eval $(comp)_VERSION=$(shell autom4te --language=autoconf --trace 'AC_INIT:$$2' $(comp)/configure.ac)))
jellyfish-1.1_DIR = jellyfish-$(jellyfish-1.1_VERSION)
jellyfish-2.0_DIR = jellyfish-$(jellyfish-2.0_VERSION)
SuperReads_DIR = SuperReads-$(SuperReads_VERSION)
quorum_DIR = quorum-$(quorum_VERSION)


.PHONY: versions
versions:
	@echo $(foreach comp,$(COMPONENTS),$(comp):$($(comp)_VERSION):$($(comp)_DIR))

%/configure: %/configure.ac %/Makefile.am
	cd $*; autoreconf -fi

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

DISTDIR = MaSurCA-$(VERSION)
$(DISTDIR).tar.gz: $(foreach comp,$(COMPONENTS),$(DISTDIR)/$($(comp)_DIR).tar.gz) $(DISTDIR)/CA.tar.gz $(DISTDIR)/install.sh
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
