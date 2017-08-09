HTML     = index.html 
INCLUDES = header.tt footer.tt menu.tt
DEST     = [%dest%]

.IGNORE:

all: $(HTML)


clean:
	\rm -f $(HTML)

install:
	cp -Rcp * $(DEST)
	find $(DEST) -name '*.tt' -exec rm -f {} \;

%.html : %.tt $(INCLUDES)
	tpage $< > $@

