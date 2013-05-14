# Apache VCL Chef cookbook
This cookbook installs and configures Apache VCL system on CentOS 6.3

# Requirements
## Chef:
* Chef: 0.10.10+

## Cookbooks:
Look in `metadata.rb`.

## Platforms:
This cookbook supports and was tested on Centos 6.3 only.

# Usage
## Init
To prepare a testing environment, install [Vagrant](http://vagrantup.com) first, then 
follow these steps:

    $ gem install bundler
    $ git clone https://github.com/illotum/chef-vcl.git
    $ cd chef-vcl
    $ bundle install

## Test
You will need a custom `hosts` recod to point to VM ip:

    $ sudo echo "192.168.33.10 vcl.vm" >> /etc/hosts
    $ bundle exec vagrant up

And point your browser to the http://vcl.vm. Admin credentials are default `admin:adminVc1passw0rd` as per VCL documentation.

## Chef-Solo
Easiest way to use this cookbook in chef-solo is to use the tar.gz archive
for a transportable cookbooks package:

    $ bundle exec berks install --path ./cookbooks
    $ tar zcvf vcl-package.tar.gz ./cookbooks

Move package to the destination server or publish it over the net, and
create a `solo.rb` file which defines
    
    cookbook_path "/url/to/your/archive"    

Finally invoke chef-solo with this configuration and your attributes defined:

    $ chef-solo -c solo.rb -j vcl-attributes.json

# Attributes
Cookbook supports a number of attributes, see `attributes/default.rb`.

# Recipes
Only `default` installation exists for now. VCL expects a database server
to reside on the same node.

# Author
Author:: Alex Valiushko (<alex.valiushko@cybera.ca>)
