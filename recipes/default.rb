# Cookbook Name:: apache-vcl
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
::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
include_recipe "selinux::permissive"
include_recipe "yum::epel"
include_recipe "yum::repoforge"

yum_repository "serverascode" do
  description "Serverascode Extra Packages for Enterprise Linux 6"
  url "http://packages.serverascode.com/mrepo/custom-centos6-noarch/RPMS.updates"
  action :add
end

# Populate passwords. Allow simple passwords for non-production.
if node['instance_role'] == 'vagrant'
  node.set_unless['vcl']['dbpass'] = 'vclpass'
  node.set_unless['vcl']['cryptkey'] = 'vclpass'
  node.set_unless['vcl']['pemkey'] = 'vclpass'
else
  node.set_unless['vcl']['dbpass'] = secure_password
  node.set_unless['vcl']['cryptkey'] = secure_password
  node.set_unless['vcl']['pemkey'] = secure_password
end
# }}}
# {{{ SETUP

package "dhclient" do
  action :remove
end

%w{ vcl-cybera vcl-cybera-web vcl-cybera-managementnode }.each do |pack|
  package pack do
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
include_recipe "mysql::server"
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
  sql <<-API_MOD
  insert into module (id, name, prettyname, description, perlpackage) values (28, 'provisioning_nova', 'Openstack Nova Module', '', 'VCL::Module::Provisioning::openstack');
  insert into provisioning (id, name, prettyname, moduleid) values (11, 'openstack_nova', 'Openstack Nova', 28);
  insert into OSinstalltype (id, name) values (6, 'openstack_nova');
  insert into provisioningOSinstalltype (provisioningid, OSinstalltypeid) values (11, 6);
  create table openstackImageNameMap(openstackimagename VARCHAR(60), vclimagename VARCHAR(60));
  # According to: https://issues.apache.org/jira/browse/VCL-590?focusedCommentId=13416496#comment-13416496 moduleid should be 5 for linux
  # insert into OS (id,name,prettyname,type,installtype,sourcepath,moduleid) values (45, "rhel6openstack", "CentOS 6 OpenStack", "linux", "openstack_nova", "centos6", 5);
  API_MOD
  action :query
end

cookbook_file "/usr/share/vcl-managementnode/lib/VCL/Module/Provisioning/openstack.pm" do
  source "openstack_nova_api.pm"
  mode 0644
end

"python-setuptools python-novaclient".split.each do |p|
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
