cd ..
mkdir /home/loncapa
mkdir /home/loncapa/certs
mkdir /home/httpd
mkdir /home/httpd/lib
mkdir /home/httpd/lib/perl
mkdir /home/httpd/lib/perl/Apache
cp connections/*.pm /home/httpd/lib/perl/Apache
cp conf/httpd.conf /etc/httpd/conf
cp conf/ssl.conf /etc/httpd/conf.d
cp conf/lc.conf /etc/httpd/conf.d
cp conf/lc_startup.pl /etc/httpd/conf
cp conf/lc_parameters.pm /home/httpd/lib/perl/Apache
mkdir /home/httpd/html
mkdir /home/httpd/html/scripts
if [ ! -d /home/httpd/html/scripts/mathjax ]; then
   unzip loncapaNG/app/scripts/v2.3-latest -d /home/httpd/html/scripts
   mv /home/httpd/html/scripts/mathjax* /home/httpd/html/scripts/mathjax 
fi
/etc/init.d/httpd restart
