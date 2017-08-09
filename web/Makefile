HTML     = index.html 
INCLUDES = header.tt footer.tt menu.tt
DEST     = /home/httpd/html/intpred

.IGNORE:

all: $(HTML)


clean:
	\rm -f $(HTML)

install:
	cp -Rcp * $(DEST)
	find $(DEST) -name '*.tt' -exec rm -f {} \;

%.html : %.tt $(INCLUDES)
	tpage $< > $@

