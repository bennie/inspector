#
# Cookbook Name:: inspector
# Recipe:: default
#
# Copyright 2013, Phillip Pollard
#
# Released under MIT license.
#

# This code relies on setting a local node attribute value to keep from running
# on each chef-client run. If you remove this node attribute, it will return.

# To bulk remove all of these attributes and to "reset" you can run the following
# from the workstation:

# knife exec -E 'nodes.all { |n| n.delete("inspector-resolv.conf"); n.save() }'
# knife exec -E 'nodes.all { |n| n.delete("inspector-sudoers"); n.save() }'
# knife exec -E 'nodes.all { |n| n.delete("inspector-sysctl.conf"); n.save() }'
# knife exec -E 'nodes.all { |n| n.delete("inspector-netfiles"); n.save() }'

ftp_server = "my.ftp.server"

case node['platform_family']
when "rhel"

	files = Hash.new

	files["exports"]        = "/etc/exports"
	files["ntp.conf"]       = "/etc/ntp.conf"
	files["postfix-main"]   = "/etc/postfix/main.cf"
	files["postfix-master"] = "/etc/postfix/master.cf"
	files["resolv.conf"]    = "/etc/resolv.conf"
	files["snmpd.conf"]     = "/etc/snmp/snmpd.conf"
	files["sshd_config"]    = "/etc/ssh/sshd_config"
	files["sudoers"]        = "/etc/sudoers"
	files["sysctl.conf"]    = "/etc/sysctl.conf"

	files.each do|name,sourcefile|
		bash "resolv.conf" do
			code "curl -v -T #{sourcefile} ftp://#{ftp_server}/incoming/#{node.name}-#{name}"
			notifies :create, "ruby_block[inspector-#{name}-flag]", :immediately
			not_if { node.attribute?("inspector-#{name}") }
		end

	    ruby_block "inspector-#{name}-flag" do
	    	block do
		 		node.set["inspector-#{name}"] = true
				node.save
			end
			action :nothing
	    end
	end

	# Network interface files    

	bash "Network Files" do
		code "
			for file in /etc/sysconfig/network-scripts/ifcfg-*; do
				FILENAME=`echo $file | tr '\/' ' ' | awk '{ print $4 }'`
				curl -v -T $file ftp://#{ftp_server}/incoming/#{node.name}-${FILENAME}
      		done
			"
		notifies :create, "ruby_block[inspector-netfiles-flag]", :immediately
		not_if { node.attribute?("inspector-netfiles") }
	end

    ruby_block "inspector-netfiles-flag" do
    	block do
    		node.set['inspector-netfiles'] = true
			node.save
		end
		action :nothing
    end

end
