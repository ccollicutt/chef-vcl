::Chef::Node.send(:include, Opscode::OpenSSL::Password)


default['vcl']['timezone'] = "America/Edmonton"

# Emails. Check https://cwiki.apache.org/VCL/vcl-23-installation.html
default['vcl']['fqdn'] = "vcl.vm"
default['vcl']['helpmail'] = "help"
default['vcl']['errormail'] = "errors"
default['vcl']['envelopesender'] = "envelope"

# Packages to install.
default['vcl']['packages']['vcl'] = "vcl-cybera"
default['vcl']['packages']['vcl-web'] = "vcl-cybera-web"
default['vcl']['packages']['vcl-mgmt'] = "vcl-cybera-managementnode"

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
  set_unless['vcl']['stackkey'] = secure_password
end

# Configure mysql to listen ourselves
set_unless['mysql']['bind_address'] = "127.0.0.1"
