cd ..
mkdir /home/loncapa
mkdir /home/loncapa/certs
mkdir /home/loncapa/cluster
mkdir /home/loncapa/logs
chown -R www:www /home/loncapa
mkdir /home/httpd
mkdir /home/httpd/lib
mkdir /home/httpd/lib/perl
mkdir /home/httpd/lib/perl/Apache
cp connections/*.pm /home/httpd/lib/perl/Apache
cp xml/*pm /home/httpd/lib/perl/Apache
cp xml/xml_tag_defs/*.pm /home/httpd/lib/perl/Apache
cp json/*.pm /home/httpd/lib/perl/Apache
cp file_handling/*.pm /home/httpd/lib/perl/Apache
cp conf/httpd.conf /etc/httpd/conf
cp conf/ssl.conf /etc/httpd/conf.d
cp conf/lc.conf /etc/httpd/conf.d
cp conf/lc_startup.pl /etc/httpd/conf
cp conf/lc_parameters.pm /home/httpd/lib/perl/Apache
cp app/handlers/*pm /home/httpd/lib/perl/Apache
cp app/handlers/lc_localize/*.pm /home/httpd/lib/perl/Apache
cp auth/*.pm /home/httpd/lib/perl/Apache
cp test/lc_test.pm /home/httpd/lib/perl/Apache
mkdir /home/httpd/html
cp app/favicon.ico /home/httpd/html
cp app/html/*.html /home/httpd/html
mkdir /home/httpd/html/images
cp app/images/* /home/httpd/html/images
mkdir /home/httpd/html/scripts
if [ ! -d /home/httpd/html/scripts/mathjax ]; then
   unzip app/scripts/v2.3-latest -d /home/httpd/html/scripts
   mv /home/httpd/html/scripts/mathjax* /home/httpd/html/scripts/mathjax 
fi
cp app/scripts/jquery* /home/httpd/html/scripts
cp app/scripts/lc* /home/httpd/html/scripts
mkdir /home/httpd/html/css
cp app/css/* /home/httpd/html/css
mkdir /home/httpd/html/pages
cp app/html/pages/* /home/httpd/html/pages
mkdir /home/httpd/html/help
cp app/html/help/* /home/httpd/html/help
if [ ! -e /home/loncapa/cluster/cluster_manager.conf ]; then
   cp conf/cluster/cluster_manager.conf /home/loncapa/cluster
fi
/etc/init.d/httpd restart
