SUBDIRS = jellyfish samtools prepare ufasta quorum SuperReads SOAPdenovo2 PacBio MUMmer CA8 eviann 
ACLOCAL_AMFLAGS = -I m4

EXTRA_DIST = LICENSE.txt

install-special:
	@echo $(SUBDIRS) | tr ' ' '\n' | grep -v -P '^CA'| while read subdir; do \
	  echo "Making install in $$subdir pwd `pwd -P`"; \
	  $(MAKE) $(AM_MAKEFLAGS) -C $$subdir install; \
	done
	@echo $(SUBDIRS) | tr ' ' '\n' | grep '^CA' |while read subdir; do \
	  echo "Making install in $$subdir"; \
	  $(MAKE) $(AM_MAKEFLAGS) -C $$subdir install bindir=$(dir $(bindir))/$$subdir/$(LOCAL_NAME)/bin; \
	done


# Print the value of a variable
print-%:
	@echo -n $($*)
