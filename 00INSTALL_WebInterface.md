IntPred Web Server Install
==========================

1. Create a directory in your web hierarchy - e.g.
```/home/httpd/html/intpred2```

2. Clone the IntPred repository into a directory. This will be where
IntPred is installed. It doesn't have to be in the web hierarchy, but
I suggest that it is. e.g.
```
cd /home/httpd/html/intpred2/
git clone git@github.com:ACRMGroup/IntPred.git
```

3. Install IntPred from the cloned directory. e.g.
```
cd /home/httpd/html/intpred2/IntPred
./install.sh
source ./setup.sh
```
You must be root or have sudo permissions to do this. See the notes in
`00INSTALL_CommandLine.txt` (`README.md`) for more details.

4. Change to the `web` sub-directory of IntPred to your web
Create/modify the config.cfg file as required
```
cd /home/httpd/html/intpred2/IntPred/web
emacs config.cfg
```

5. Run the configure script, build and install the web pages:
```
./configure.pl
make
make install
```
See notes in the `web/README.md` file on Apache configuration.



