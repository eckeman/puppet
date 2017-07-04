# server running "Request Tracker"
# https://bestpractical.com/request-tracker
class profile::requesttracker::server {

    include ::passwords::misc::rt

    class { '::requesttracker':
        apache_site => 'rt.wikimedia.org',
        dbhost      => 'm1-master.eqiad.wmnet',
        dbport      => '',
        dbuser      => $passwords::misc::rt::rt_mysql_user,
        dbpass      => $passwords::misc::rt::rt_mysql_pass,
    }

    class { 'exim4':
        variant => 'heavy',
        config  => template('role/exim/exim4.conf.rt.erb'),
        filter  => template('role/exim/system_filter.conf.erb'),
    }

    include exim4::ganglia

    include ::base::firewall

    ferm::service { 'rt-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$PRODUCTION_NETWORKS',
    }
}
