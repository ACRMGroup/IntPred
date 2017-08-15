IntPred Web Site
================

This is the code for the IntPred web page.

Installation
------------

1. Create a `config.cfg` file - at UCL this is done with:

        ln -s config_ucl.cfg config.cfg

2. Run the `configure.pl` script:

        ./configure.pl

3. Build the web pages:

        make

4. Install the pages on the web site (the destination is specified in
the `config.cfg` file):

        make install

Apache Configuration
--------------------

1. Set the TimeOut

        Timeout 1200
        ProxyTimeout 1200

2. Ensure that AllowOverride and ExecCGI are set

        <Directory "/var/www/html">
            Options Indexes FollowSymLinks ExecCGI Includes
            AllowOverride All
            Order allow,deny
            Allow from all
        </Directory>
