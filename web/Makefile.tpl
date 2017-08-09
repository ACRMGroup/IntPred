HTML     = index.html 
INCLUDES = header.tt footer.tt menu.tt
DEST     = [%dest%]
IPHOME   = [%iphome%]
IPBIN    = [%ipbin%]
PDBCACHE = [%pdbcache%]

.IGNORE:

all: $(HTML)


clean:
	\rm -f $(HTML)

install:
	cp -Rcp * $(DEST)
	cp htaccess $(DEST)/.htaccess
	find $(DEST) -name '*.tt' -exec rm -f {} \;
	chmod 1777 $(IPBIN)
	chmod 0555 $(IPBIN)/*
	chmod 1777 $(PDBCACHE)
	chmod 1777 $(IPHOME)/data/consScores/BLAST
	chmod 1777 $(IPHOME)/data/consScores/FOSTA
#	find $(IPHOME) -type d -exec chmod 1777 {} \;

undo:
	chmod 0755 $(IPBIN)
	chmod 0755 $(IPBIN)/*
	chmod 0755 $(PDBCACHE)
	chmod 0777 $(IPHOME)/data/consScores/BLAST
	chmod 0777 $(IPHOME)/data/consScores/FOSTA
#	find $(IPHOME) -type d -exec chmod 0777 {} \;

%.html : %.tt $(INCLUDES)
	tpage $< > $@

