HTML     = index.html 
INCLUDES = header.tt footer.tt menu.tt
DEST     = [%dest%]
IPBIN    = [%ipbin%]

.IGNORE:

all: $(HTML)


clean:
	\rm -f $(HTML)

install:
	cp -Rcp * $(DEST)
	find $(DEST) -name '*.tt' -exec rm -f {} \;
	chmod 1777 $(IPBIN)
	chmod 0555 $(IPBIN)/*

undo:
	chmod 0755 $(IPBIN)
	chmod 0755 $(IPBIN)/*

%.html : %.tt $(INCLUDES)
	tpage $< > $@

