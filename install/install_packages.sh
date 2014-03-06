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
yum install perl-CPAN
yum install gcc
cpan Safe
cpan -f -i MongoDB
cpan Safe::Hole
cpan Math::Cephes
cpan Math::Random
cpan Cache::Memcached
cpan Locale::Maketext
cpan Lingua::Bork
cpan Lingua::PigLatin
cpan Data::Uniqid
cpan Time::y2038
cpan Digest::MD5
cpan File::Util
cpan File::Touch
cpan JSON::DWIW
cpan Net::SSL
cpan DateTime
