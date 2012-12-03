name             "vcl"
maintainer       "Alex Valiushko"
maintainer_email "alex.valiushko@cybera.ca"
license          "Apache 2.0"
description      "Installs and configures Apache VCL"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.1"

%w{ centos rhel }.each do |os|
  supports os
end

%w{ database mysql selinux yum apache2 build-essential openssl }.each do |dep|
  depends dep
end
