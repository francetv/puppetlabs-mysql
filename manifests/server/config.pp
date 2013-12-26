# See README.me for options.
class mysql::server::config {

  $options = $mysql::server::options

  File {
    owner  => 'root',
    group  => $mysql::server::root_group,
    mode   => '0400',
    notify => Class['mysql::server::service'],
  }

  file { '/etc/mysql':
    ensure => directory,
    mode   => '0755',
  }

  file { '/etc/mysql/conf.d':
    ensure  => directory,
    mode    => '0755',
    recurse => $mysql::server::purge_conf_dir,
    purge   => $mysql::server::purge_conf_dir,
  }

  if $mysql::server::manage_config_file  {
    if has_key($options['mysqld'], 'innodb_log_file_size') {
      file { '/tmp/old_innodb_log_dir':
        ensure  => directory,
        mode    => '0755',
        owner   => 'mysql',
        group   => 'mysql',
      }

      exec{ 'mv_old_innodb_log_file' :
        command => "grep innodb_log_file_size ${mysql::server::config_file}|grep ${options['mysqld']['innodb_log_file_size']} || mv -f ${options['mysqld']['datadir']}/ib_logfile* /tmp/old_innodb_log_dir/",
        path    => ['/bin', '/usr/bin'],
        require => File['/tmp/old_innodb_log_dir'],
        before  => File[$mysql::server::config_file],
      }
    }

    file { $mysql::server::config_file:
      content => template('mysql/my.cnf.erb'),
      mode    => '0644',
    }
  }
}
