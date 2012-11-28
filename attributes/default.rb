# Cookbook Name:: apache-vcl
# Attributes:: default
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

::Chef::Node.send(:include, Opscode::OpenSSL::Password)

# Emails
default['vcl']['helpmail'] = "help"
default['vcl']['errormail'] = "errors"
default['vcl']['envelopesender'] = "envelope"

# Database connection
default['vcl']['dbname'] = "vcldb"
default['vcl']['dbuser'] = "vcluser"

# OpenStack connection
default['vcl']['stackuri'] = "http://127.0.0.1:5000/v2.0/"
default['vcl']['stackuser'] = "admin"
default['vcl']['stacktenant'] = "admin"

# Populate passwords. Allow simple passwords for non-production.
if node['instance_role'] == 'vagrant'
  set_unless['vcl']['dbpass'] = 'vclpass' # Database connection
  set_unless['vcl']['cryptkey'] = 'vclpass' # SSL
  set_unless['vcl']['pemkey'] = 'vclpass' # SSH
  set_unless['vcl']['stackkey'] = 'vclpass' # OpenStack connection
else
  set_unless['vcl']['dbpass'] = secure_password
  set_unless['vcl']['cryptkey'] = secure_password
  set_unless['vcl']['pemkey'] = secure_password
  set_unless['vcl']['access_key'] = secure_password
end

# Configure mysql to listen ourselves
set_unless['mysql']['bind_address'] = "127.0.0.1"
