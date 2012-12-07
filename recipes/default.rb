# Cookbook Name:: vcl
# Recipe:: default
#
# Copyright (C) 2012 Alex Valiushko
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# {{{ INIT
include_recipe "selinux::permissive"
include_recipe "yum::epel"
include_recipe "yum::repoforge"

link "/etc/localtime" do
  filename = "/usr/share/zoneinfo/#{node['vcl']['timezone']}"
  to filename
  only_if { File.exists? filename }
end

include_recipe "ntp::default"

yum_repository "serverascode" do
  description "Serverascode Extra Packages for Enterprise Linux 6"
  url "http://packages.serverascode.com/mrepo/custom-centos6-noarch/RPMS.updates"
  action :add
end

cookbook_file "/etc/sysconfig/iptables" do
  source "iptables"
  mode 0755
end

service "iptables" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :restart ]
end

# }}}
# {{{ SETUP
node['vcl']['packages'].values.each do |p|
  package p do
    action :install
  end
end

template "/etc/vcl/vcld.conf" do
  source "vcld.erb"
  mode 0640
end

# Generate crypto-keys
script "generate keys" do
  interpreter "sh"
  user "root"
  cwd "/usr/share/vcl-web/.ht-inc"
  code <<-CODE
  ssh-keygen -q -t dsa -C '' -N '' -f /etc/vcl/vcl.key
  openssl genrsa -aes256 -passout pass:#{node['vcl']['pemkey']} -out ./keys.pem 2048
  openssl rsa -pubout -passin pass:#{node['vcl']['pemkey']} -in ./keys.pem -out ./pubkey.pem
  CODE
end

# }}}
#{{{ DATABASE
include_recipe "mysql::client"
include_recipe "mysql::ruby"

# Stub for multi-host setup
#if Chef::Config[:solo]
#  Chef::Log.warn("This recipe uses search for multi-host setup. Chef Solo does not support search. Assuming all-in-one setup.")
#else
#  nodes = search(:node, "hostname:[* TO *] AND chef_environment:#{node.chef_environment}")
#end

mysql_connection = {
  :host     => 'localhost',
  :username => 'root',
  :password => node['mysql']['server_root_password']
}

mysql_database node['vcl']['dbname'] do
  connection  mysql_connection
  action      :create
end

mysql_database_user node['vcl']['dbuser'] do
  connection    mysql_connection
  password      node['vcl']['dbpass']
  database_name node['vcl']['dbname']
  host          'localhost'
  privileges    [:all]
  action        :grant
end

mysql_database node['vcl']['dbname'] do
  connection mysql_connection
  sql { File.open("/usr/share/doc/vcl-2.3/vcl.sql").read }
  action :query
end
# }}}
# {{{ WEB
include_recipe "apache2::default"
include_recipe "apache2::mod_ssl"
include_recipe "apache2::mod_php5"

%w{ php-gd php-mysql php-xml php-xmlrpc php-ldap php-process }.each do |p|
  package p do
    action :install
  end
end

cookbook_file "/etc/httpd/conf.d/vcl.conf" do
  source "vcl.conf"
  mode 0644
end

template "/etc/httpd/sites-available/default" do
  source "apache-site.erb"
  mode 0644
end

%w{ server.key server.crt }.each do |f|
  cookbook_file "/etc/httpd/ssl/#{f}" do
    source f
    mode 0644
    action :create_if_missing
  end
end

template "/usr/share/vcl-web/.ht-inc/conf.php" do
  source "conf.erb"
  mode 0644
end

template "/usr/share/vcl-web/.ht-inc/secrets.php" do
  source "secrets.erb"
  mode 0644
end
# }}}
# {{{ OPENSTACK MOD
mysql_database node['vcl']['dbname'] do
  connection mysql_connection
  # TODO: Abstract inserts via attributes
  sql <<-QUERY
  insert into module (id, name, prettyname, description, perlpackage) values (28, 'provisioning_nova', 'Openstack Nova Module', '', 'VCL::Module::Provisioning::openstack');
  insert into provisioning (id, name, prettyname, moduleid) values (11, 'openstack_nova', 'Openstack Nova', 28);
  insert into OSinstalltype (id, name) values (6, 'openstack_nova');
  insert into provisioningOSinstalltype (provisioningid, OSinstalltypeid) values (11, 6);
  insert into provisioning (name,prettyname,moduleid) values ("openstack_nova", "OpenStack Nova Module", 28);
  create table openstackImageNameMap(openstackimagename VARCHAR(60), vclimagename VARCHAR(60), flavor tinyint);
  #insert into OS (name, prettyname, type, installtype, sourcepath, moduleid) values ("win7openstack", "win7openstack", "windows", "openstack_nova", "image", 17);
  #insert into managementnode (hostname, IPaddress, ownerid, stateid, checkininterval, installpath, imagelibenable, imagelibgroupid, imagelibuser, imagelibkey, `keys`, predictivemoduleid, sshport, publicIPconfiguration, publicSubnetMask, publicDefaultGateway, publicDNSserver, sysadminEmailAddress, sharedMailBox) VALUES ('localhost', '127.0.0.1', 1, 2, 5, '', 0, NULL, NULL, NULL, '/etc/vcl/vcl.key', 8, 22, 'nat', NULL, NULL, NULL, NULL, NULL);
  #insert into resource (resourcetypeid, subid) VALUES (16, 1);
  QUERY
  action :nothing
end

cookbook_file "/usr/share/vcl-managementnode/lib/VCL/Module/Provisioning/openstack.pm" do
  source "openstack_nova_api.pm"
  mode 0644
end

%w{ python-setuptools python-novaclient }.each do |p|
  package p do
    action :install
  end
end

directory "/etc/vcl/openstack" do
  action :create
  mode 0755
end

template "etc/vcl/openstack/openstack.conf" do
  source "openstack.erb"
  mode 0644
end
# }}}
# {{{RUN
service "vcld" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
# }}}
#
# vim:fdm=marker:ft=ruby
