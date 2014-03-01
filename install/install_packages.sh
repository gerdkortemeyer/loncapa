cp mongodb.repo /etc/yum.repos.d
yum install mongo-10gen mongo-10gen-server
service mongod start
chkconfig mongod on
yum install postgresql
yum install postgresql-server
yum install perl-DBD-Pg
service postgresql initdb
service postgresql start
sudo -u postgres psql -U postgres -d postgres -c "create user loncapa with password 'loncapa';"
sudo -u postgres psql -U postgres -d postgres -c "create database loncapa;"
sudo -u postgres psql -U postgres -d postgres -c "grant all privileges on database loncapa to loncapa;"
cp ../conf/pg_hba.conf /var/lib/pgsql/data
service postgresql restart
chkconfig postgresql on
perl postgres_make_tables.pl 
yum install memcached
service memcached start
chkconfig memcached on
cpan install Safe
cpan install MongoDB
cpan install Safe::Hole
cpan install Math::Cephes
cpan install Math::Random
cpan install Cache::Memcached
cpan install Locale::Maketext
cpan install Lingua::Bork
cpan install Lingua::PigLatin
cpan install Data::Uniqid
cpan install Digest::MD5
