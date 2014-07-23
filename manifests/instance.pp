define memcached::instance (
  $ensure          = 'present',
  $manage_firewall = false,
  $max_memory      = 64,
  $listen_ip       = '0.0.0.0',
  $tcp_port        = 11211,
  $udp_port        = 11211,
  $user            = $::memcached::params::user,
  $max_connections = '8192',
  $processorcount  = $::processorcount,
  $service_restart = true ) {

  # validate type and convert string to boolean if necessary
  if type($manage_firewall) == 'String' {
    $manage_firewall_bool = str2bool($manage_firewall)
  } else {
    $manage_firewall_bool = $manage_firewall
  }
  validate_bool($manage_firewall_bool)
  validate_bool($service_restart)

  if $package_ensure == 'absent' {
    $service_ensure = 'stopped'
  } else {
    $service_ensure = 'running'
  }

  if $manage_firewall_bool == true {
    firewall { "100_tcp_${tcp_port}_for_${name}_memcached":
      port   => $tcp_port,
      proto  => 'tcp',
      action => 'accept',
    }

    firewall { "100_udp_${udp_port}_for_${name}_memcached":
      port   => $udp_port,
      proto  => 'udp',
      action => 'accept',
    }
  }

  file { "/etc/init/memcached_${name}.conf":
    ensure  => $ensure,
    mode    => 0644,
    owner   => root,
    group   => root,
    content => template('memcached/memcached_instance.conf.erb'),
    notify  => Service["memcached_${name}"],
    require => Package['memcached'],
  }

  service { "memcached_${name}":
    ensure     => $service_ensure,
    hasstatus  => true,
    hasrestart => true,
    start      => "/sbin/start memcached_${name}",
    stop       => "/sbin/stop memcached_${name}",
    status     => "/sbin/status memcached_${name} | grep '/running' 1>/dev/null 2>&1",
    require    => [ Package['memcached'], File['/etc/init/solr.conf']],
  }
}
