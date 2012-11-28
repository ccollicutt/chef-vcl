name             "apache-vcl"
maintainer       "Alex Valiushko"
maintainer_email "alex.valiushko@cybera.ca"
license          "Apache 2.0"
description      "Installs/Configures Apache VCL"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "2012.1.0"

%w{ centos rhel }.each do |os|
  supports os
end

%w{ database mysql selinux iptables yum apache2 build-essential php openssl }.each do |dep|
  depends dep
end
