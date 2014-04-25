Installing LON-CAPA

For development, you can use a virtual machine. Recommended is a minimal CentOS installation. If you would like to use the test certificates included here, the machine should be named "localhost", which is the default during installation.

After installation, until a policy is developed, disable SELinux in "/etc/selinux/config". Reboot the box.

Run "sh install_packages.sh" as root from this directory. Depending on network speed, this may take a long time, and you might have to press "yes" quite a few times. Sorry.

Then, if you want to use the development test certificates, use "sh install_test_certs.sh" from the "testcerts" subdirectory.

Finally, run "sh install.sh". 
