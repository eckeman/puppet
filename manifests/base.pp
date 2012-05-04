# base.pp

import "decommissioning.pp"
import "generic-definitions.pp"
import "ssh.pp"
import "sudo.pp"
import "nagios.pp"
import "nrpe.pp"
import "../private/manifests/passwords.pp"
import "../private/manifests/contacts.pp"
import "../private/manifests/mail.pp"


class base::access::dc-techs {
	# Add sudoers rules for data center techs

	sudo_user { [ "cmjohnson" ]: privileges => [
		'ALL = (root) NOPASSWD: /sbin/fdisk',
		'ALL = (root) NOPASSWD: /sbin/mdadm',
		'ALL = (root) NOPASSWD: /sbin/parted',
		'ALL = (root) NOPASSWD: /sbin/sfdisk',
		'ALL = (root) NOPASSWD: /usr/bin/MegaCli',
		'ALL = (root) NOPASSWD: /usr/bin/arcconf',
		'ALL = (root) NOPASSWD: /usr/bin/lshw',
		'ALL = (root) NOPASSWD: /usr/sbin/grub-install',
	]}

}

class base::apt::update {
	# Make sure puppet runs apt-get update!
	exec { "/usr/bin/apt-get update":
		timeout => 240,
		returns => [ 0, 100 ];
	}
}

class base::apt {
	$proxyconfig = "Acquire::http::Proxy::security.ubuntu.com \"http://brewster.wikimedia.org:8080\";
Acquire::http::Proxy::old-releases.ubuntu.com \"http://brewster.wikimedia.org:8080\";
"

	# security.ubuntu.com should be accessed through a proxy
	file { "/etc/apt/apt.conf.d/80wikimedia-proxy":
		mode => 0444,
		owner => root,
		group => root,
		path => "/etc/apt/apt.conf.d/80wikimedia-proxy",
		content => $proxyconfig
	}

	# Setup the APT repositories
	$aptrepository = "## Wikimedia APT repository
deb http://apt.wikimedia.org/wikimedia ${::lsbdistcodename}-wikimedia main universe
deb-src http://apt.wikimedia.org/wikimedia ${::lsbdistcodename}-wikimedia main universe
"
	$aptpref = "Explanation: Prefer Wikimedia APT repository packages in all cases
Package: *
Pin: release o=Wikimedia
Pin-Priority: 1001
"

	file {
		"/etc/apt/sources.list.d/wikimedia.list":
			require => Exec[sed-wikimedia-repository],
			content => $aptrepository,
			mode => 0444;
	}
	
	if versioncmp($::lsbdistrelease, "10.04") >= 0 {
		file { "/etc/apt/preferences.d/wikimedia.pref":
			require => File["/etc/apt/sources.list.d/wikimedia.list"],
			content => $aptpref,
			mode => 0444;
		}
	}

	# Comment out the old entries in /etc/apt/sources.list
	exec { 
		sed-wikimedia-repository:
			path => "/bin:/sbin:/usr/bin:/usr/sbin",
			command => "sed -i '/deb.*apt\\.wikimedia\\.org.*-wikimedia main/s/^deb/#deb/g' /etc/apt/sources.list",
			creates => "/etc/apt/sources.list.d/wikimedia.list";
	}


	package { apt-show-versions:
		ensure => latest;
	}
	
	# Point out-of-support distributions to http://old-releases.ubuntu.com
	if $::lsbdistcodename in [ "karmic" ] {
		$oldrepository = "## Unsupported (old) Ubuntu release
deb http://old-releases.ubuntu.com/ubuntu ${lsbdistcodename} main universe multiverse
deb-src http://old-releases.ubuntu.com/ubuntu ${lsbdistcodename} main universe multiverse
deb http://old-releases.ubuntu.com/ubuntu ${lsbdistcodename}-updates main universe multiverse
deb-src http://old-releases.ubuntu.com/ubuntu ${lsbdistcodename}-updates main universe multiverse
"
		file { "/etc/apt/sources.list.d/ubuntu-${lsbdistcodename}.list":
			content => $oldrepository,
			mode => 0444;
		}
	}
}

class base::grub {
	# Disable the 'quiet' kernel command line option so console messages
	# will be printed.
	exec {
		"grub1 remove quiet":
			path => "/bin:/usr/bin",
			command => "sed -i '/^# defoptions.*[= ]quiet /s/quiet //' /boot/grub/menu.lst",
			onlyif => "grep -q '^# defoptions.*[= ]quiet ' /boot/grub/menu.lst",
			notify => Exec["update-grub"];
		"grub2 remove quiet":
			path => "/bin:/usr/bin",
			command => "sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"/s/quiet splash//' /etc/default/grub",
			onlyif => "grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"' /etc/default/grub",
			notify => Exec["update-grub"];
	}

	# Ubuntu Precise Pangolin no longer has a server kernel flavour.
	# The generic flavour uses the CFQ I/O scheduler, which is rather
	# suboptimal for some of our I/O work loads. Override with deadline.
	# (the installer does this too, but not for Lucid->Precise upgrades)
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "12.04") >= 0 {
		exec {
			"grub1 iosched deadline":
				path => "/bin:/usr/bin",
				command => "sed -i '/^# kopt=/s/\$/ elevator=deadline/' /boot/grub/menu.lst",
				unless => "grep -q '^# kopt=.*elevator=deadline' /boot/grub/menu.lst",
				onlyif => "test -f /boot/grub/menu.lst",
				notify => Exec["update-grub"];
			"grub2 iosched deadline":
				path => "/bin:/usr/bin",
				command => "sed -i '/^GRUB_CMDLINE_LINUX=/s/\\\"\$/ elevator=deadline\\\"/' /etc/default/grub",
				unless => "grep -q '^GRUB_CMDLINE_LINUX=.*elevator=deadline' /etc/default/grub",
				onlyif => "test -f /etc/default/grub",
				notify => Exec["update-grub"];
		}
	}

	exec { "update-grub":
		refreshonly => true,
		path => "/bin:/usr/bin:/sbin:/usr/sbin"
	}
}

class base::puppet($server="puppet") {

	include passwords::puppet::database

	package { [ "puppet" ]:
		ensure => latest;
	}

	# monitoring via snmp traps
	package { [ "snmp" ]:
		ensure => latest;
	}

	monitor_service { "puppet freshness": description => "Puppet freshness", check_command => "puppet-FAIL", passive => "true", freshness => 36000, retries => 1 ; }
	
	exec { "spence puppet snmp trap":
		command => "snmptrap -v 1 -c public nagios.wikimedia.org .1.3.6.1.4.1.33298 `hostname` 6 1004 `uptime | awk '{ split(\$3,a,\":\"); print (a[1]*60+a[2])*60 }'`",
		path => "/bin:/usr/bin",
		require => Package["snmp"]
	}

	exec {	"neon puppet snmp trap":
			command => "snmptrap -v 1 -c public neon.wikimedia.org .1.3.6.1.4.1.33298 `hostname` 6 1004 `uptime | awk '{ split(\$3,a,\":\"); print (a[1]*60+a[2])*60 }'`",
			path => "/bin:/usr/bin",
			require => Package["snmp"]
	}

	file {
		"/etc/default/puppet":
			owner => root,
			group => root,
			mode  => 0444,
			source => "puppet:///files/puppet/puppet.default";
		"/etc/puppet/puppet.conf":
			owner => root,
			group => root,
			mode => 0444,
			ensure => file,
			notify => Exec["compile puppet.conf"];
		"/etc/puppet/puppet.conf.d/":
			owner => root,
			group => root,
			mode => 0550,
			ensure => directory;
		"/etc/puppet/puppet.conf.d/10-main.conf":
			owner => root,
			group => root,
			mode  => 0444,
			content => template("puppet/puppet.conf.d/10-main.conf.erb"),
			notify => Exec["compile puppet.conf"];
		"/etc/init.d/puppet":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/puppet.init";
		"/var/lib/puppet/lib/facter":
			owner => root,
			group => root,
			mode => 0555,
			ensure => directory;
		"/var/lib/puppet/lib/facter/default_gateway.rb":
			owner => root,
			group => root,
			mode => 0755,
			source => "puppet:///files/puppet/default_gateway.rb";
	}

	# Compile /etc/puppet/puppet.conf from individual files in /etc/puppet/puppet.conf.d
	exec { "compile puppet.conf":
		path => "/usr/bin:/bin",
		command => "cat /etc/puppet/puppet.conf.d/??-*.conf > /etc/puppet/puppet.conf",
		refreshonly => true;
	}

	# Keep puppet running
	cron {
		restartpuppet:
			require => File[ [ "/etc/default/puppet" ] ],
			command => "/etc/init.d/puppet restart > /dev/null",
			user => root,
			hour => 2,
			minute => 37,
			ensure => present;
		remove-old-lockfile:
			require => Package[puppet],
			command => "[ -f /var/lib/puppet/state/puppetdlock ] && find /var/lib/puppet/state/puppetdlock -ctime +1 -delete",
			user => root,
			minute => 43,
			ensure => present;
	}	

	# Report the last puppet run in MOTD
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "9.10") >= 0 {
		file { "/etc/update-motd.d/97-last-puppet-run":
			source => "puppet:///files/misc/97-last-puppet-run",
			mode => 0555;
		}
	}
}

class base::remote-syslog {
	if ($::lsbdistid == "Ubuntu") and ($::hostname != "nfs1") and ($::hostname != "nfs2") {
		package { rsyslog:
			ensure => latest;
		}

		# Remote syslog must be before local syslog (50) so that we can filter out 
		# apache messages before they go to the local log -- TS
		file { "/etc/rsyslog.d/90-remote-syslog.conf":
			ensure => absent;
		}

		file { "/etc/rsyslog.d/30-remote-syslog.conf":
			require => Package[rsyslog],
			owner => root,
			group => root,
			mode => 0444,
			content => "*.info;mail.none;authpriv.none;cron.none	@syslog.${::site}.wmnet\n",
			ensure => present;
		}

		service { rsyslog:
			require => Package[rsyslog],
			subscribe => File["/etc/rsyslog.d/30-remote-syslog.conf"],
			ensure => running;
		}
	}
}

class base::sysctl {
	if ($::lsbdistid == "Ubuntu") and ($::lsbdistrelease != "8.04") {
		exec { "/sbin/start procps":
			path => "/bin:/sbin:/usr/bin:/usr/sbin",
			refreshonly => true;
		}

		file { wikimedia-base-sysctl:
			name => "/etc/sysctl.d/50-wikimedia-base.conf",
			owner => root,
			group => root,
			mode => 0444,
			notify => Exec["/sbin/start procps"],
			source => "puppet:///files/misc/50-wikimedia-base.conf.sysctl"
		}
	}
}

class base::standard-packages {
	$packages = [ "wikimedia-base", "wipe", "tzdata", "zsh-beta", "jfsutils",
				"xfsprogs", "wikimedia-raid-utils", "screen", "gdb", "iperf",
				"atop", "htop", "vim", "sysstat" ]

	if $::lsbdistid == "Ubuntu" {
		package { $packages:
			ensure => latest;
		}

		if $::network_zone == "internal" {
			include nrpe
		}

		# Run lldpd on all >= Lucid hosts
		if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
			package { lldpd: ensure => latest; }
		}
		
		# DEINSTALL these packages
		package { [ "mlocate" ]:
			ensure => absent;
		}
	}
}

class base::resolving {
	if ! $::nameservers {
		error("Variable $::nameservers is not defined!")
	}
	else {
		if $::realm != "labs" {
			file { "/etc/resolv.conf":
				owner => root,
				group => root,
				mode => 0444,
				content => template("base/resolv.conf.erb");
			}
		}
	}
}

class base::motd {
	# Remove the standard help text
	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
		file { "/etc/update-motd.d/10-help-text": ensure => absent; }
	}
}

class base::monitoring::host {
	monitor_host { $hostname: group => $nagios_group }
	monitor_service { "ssh": description => "SSH", check_command => "check_ssh" }

	case $::lsbdistid {
		Ubuntu: {
			# Need NRPE. Define as virtual resources, then the NRPE class can pull them in
			@monitor_service { "dpkg": description => "DPKG", check_command => "nrpe_check_dpkg", tag => nrpe }
		}
	}

	# Need NRPE. Define as virtual resources, then the NRPE class can pull them in
	@monitor_service { "disk space": description => "Disk space", check_command => "nrpe_check_disk_6_3", tag => nrpe }
	@monitor_service { "raid": description => "RAID", check_command => "nrpe_check_raid", tag => nrpe }
}

class base::decommissioned {
	# There has to be a better way to check for array membership!
	define decommissioned_host_role {
		if $::hostname == $title {
			system_role { "base::decommissioned": description => "DECOMMISSIONED server" }
		}
		else {
			debug("${title} is not ${::hostname}, so not decommissioning.")
		}
	}

	# Evaluate for every member in $decommissioned_servers
	decommissioned_host_role { $decommissioned_servers: }
}

class base::instance-upstarts {

	file {"/etc/init/ttyS0.conf":
		owner => root,
		group => root,
		mode => 0444,
		source => 'puppet:///files/upstart/ttyS0.conf';
	}

}

class base::instance-finish {

	if $::realm == "labs" {
		Class["base::remote-syslog"] -> Class["base::instance-finish"]
		file {
			"/etc/init/runonce-fixpuppet.conf":
				ensure => absent;
			"/etc/rsyslog.d/60-puppet.conf":
				ensure => absent,
				notify => Service[rsyslog];
		}
	}

}

class base::vimconfig {
	file { "/etc/vim/vimrc.local": 
		owner => root,
		group => root,
		mode => 0444,
		source => "puppet:///files/misc/vimrc.local",
		ensure => present;
	}

	if $::lsbdistid == "Ubuntu" {
		# Joe is for pussies
		file { "/etc/alternatives/editor":
			ensure => "/usr/bin/vim"
		}
	}
}

class base::environment {
	case $::realm {
		'production': {
			exec { "uncomment root bash aliases":
				path => "/bin:/usr/bin",
				command => "sed -i '
						/^#alias ll=/ s/^#//
						/^#alias la=/ s/^#//
					' /root/.bashrc",
				onlyif => "grep -q '^#alias ll' /root/.bashrc"
			}
		}
		'labs': {
			file {
				"/etc/bash.bashrc":
					content => template('environment/bash.bashrc'),
					owner => root,
					group => root,
					mode => 0444;
				"/etc/skel/.bashrc":
					content => template('environment/skel/bashrc'),
					owner => root,
					group => root,
					mode => 0644;
			}
		}
	}
}

#	Class: base::platform
#
#	This class implements hardware platform specific configuration
class base::platform {
	class common($lom_serial_port, $lom_serial_speed) {
		$console_upstart_file = "
# ${lom_serial_port} - getty
#
# This service maintains a getty on ${lom_serial_port} from the point the system is
# started until it is shut down again.

start on stopped rc RUNLEVEL=[2345]
stop on runlevel [!2345]

respawn
exec /sbin/getty -L ${lom_serial_port} ${$lom_serial_speed} vt102
"

		if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "10.04") >= 0 {
			file { "/etc/init/${lom_serial_port}.conf":
				owner => root,
				group => root,
				mode => 0444,
				content => $console_upstart_file;
			}
			upstart_job { "${lom_serial_port}": require => File["/etc/init/${lom_serial_port}.conf"] }
		}
	}
	
	class generic {
		class dell {
			$lom_serial_port = "ttyS1"
		}

		class cisco {
			$lom_serial_port = "ttyS0"
			$lom_serial_speed = "115200"
		}

		class sun {
			$lom_serial_port = "ttyS0"
			$lom_serial_speed = "9600"

			# Udev rules for Solaris-style disk names
			@file {
				"/etc/udev/scripts":
					ensure => directory,
					tag => "thumper-udev";
				"/etc/udev/scripts/solaris-name.sh":
					source => "puppet:///files/udev/solaris-name.sh",
					owner => root,
					group => root,
					mode => 0555,
					tag => "thumper-udev";
				"/etc/udev/rules.d/99-thumper-disks.rules":
					require => File["/etc/udev/scripts/solaris-name.sh"],
					source => "puppet:///files/udev/99-thumper-disks.rules",
					owner => root,
					group => root,
					mode => 0444,
					notify => Exec["reload udev"],
					tag => "thumper-udev";
			}
			
			exec { "reload udev":
				command => "/sbin/udevadm control --reload-rules",
				refreshonly => true
			}
		}
	}

	class dell-c2100 inherits base::platform::generic::dell {
		$lom_serial_speed = "115200"
		
		class { "common": lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }		
	}

	class dell-r300 inherits base::platform::generic::dell {
		$lom_serial_speed = "57600"
		
		class { "common": lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }		
	}

	class sun-x4500 inherits base::platform::generic::sun {

		File <| tag == "thumper-udev" |>

		class { "common": lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }
	}

	class sun-x4540 inherits base::platform::generic::sun {
		File <| tag == "thumper-udev" |>

		class { "common": lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }
	}

	class cisco-C250-M1 inherits base::platform::generic::cisco {
		class { "common": lom_serial_port => $lom_serial_port, lom_serial_speed => $lom_serial_speed }		
	}

	case $::productname {
		"PowerEdge C2100": {
			$startup_drives = [ "/dev/sda", "/dev/sdb" ]
		}
		"PowerEdge R300": {
			$startup_drives = [ "/dev/sda", "/dev/sdb"]
			include dell-r300
		}
		"Sun Fire X4500": {
			$startup_drives = [ "/dev/sdy", "/dev/sdac" ]
			include sun-x4500
		}
		"Sun Fire X4540": {
			$startup_drives = [ "/dev/sda", "/dev/sdi" ]
			include sun-x4540
		}
		"R250-2480805": {
			$startup_drives = [ "/dev/sda", "/dev/sdb" ]
			include cisco-C250-M1
		}
		default: {
			# set something so the logic doesn't puke
			$startup_drives = [ "/dev/sda", "/dev/sdb" ]
		}
	}
}

class base {

	case $::operatingsystem {
		Ubuntu,Debian: {
			include openstack::nova_config
			
			include	base::apt,
				base::apt::update

			class { base::puppet:
				server => $::realm ? {
					'labs' => $openstack::nova_config::nova_puppet_host,
					default => "puppet"
				}
			}
		}
		Solaris: {
		}
	}

	include	passwords::root,
		base::decommissioned,
		base::grub,
		base::resolving,
		base::remote-syslog,
		base::sysctl,
		base::motd,
		base::vimconfig,
		base::standard-packages,
		base::monitoring::host,
		base::environment,
		base::platform,
		base::access::dc-techs,
		ssh

	if $::realm == "labs" {
		include base::instance-upstarts,
			generic::gluster

		# Add directory for data automounts
		file { "/data":
			ensure => directory,
			owner => root,
			group => root,
			mode => 0755;
		}
	}

}
