# Apache VCL Chef cookbook
This cookbook install and configures Apache VCL system on CentOS 6.3

# Requirements
## Chef:
* Chef: 0.10.10+

## Cookbooks:
Look in `metadata.rb`.

## Platforms:
This cookbook supports and was tested on Centos 6.3 only.

# Usage
To test it in virtual environment:

    $ gem install bundler
    $ git clone https://github.com/illotum/chef-vcl.git
    $ cd chef-vcl
    $ bundle install
    $ bundle exec vagrant up

And point your browser to https://192.168.33.10

# Attributes
Cookbook supports number of attributes, check `attributes/default.rb`.

# Recipes
Only `default` installation exists for now. All VCL roles and MySQL
database are installed on one node.

# Author
Author:: Alex Valiushko (<alex.valiushko@cybera.ca>)
