# Apache VCL Chef cookbook
This cookbook install and configures Apache VCL system on CentOS 6.3

# Requirements
## Chef:
* Chef: 0.10.10+

## Cookbooks:
Look in `Berksfile`

# Platforms
This cookbooks supports and was tested in Centos 6.3 only.

# Usage
To test it in virtual environment:

    $ gem install bundler
    $ git clone
    $ cd apache-vcl
    $ bundle install
    $ vagrant up

# Attributes
Cookbook supports number of attributes, all of which are explained in
VCL installation guide:

    https://cwiki.apache.org/VCL/vcl-23-installation.html

## VCL mail
`node['vcl']['helpmail']`
`node['vcl']['errormail']`
`node['vcl']['envelopesender']`

## Database connection
`node['vcl']['dbname']`
`node['vcl']['dbuser']`
`node['vcl']['dbpass']`

## Crypto keys
`node['vcl']['cryptkey']`
`node['vcl']['pemkey']`

# Recipes
Only `default` installation exists for now. All VCL roles and MySQL are
installed on one node.

# Author
Author:: Alex Valiushko (<alex.valiushko@cybera.ca>)
