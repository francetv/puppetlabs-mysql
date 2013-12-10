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
      file { "${options['mysqld']['datadir']}/old_innodb_log_file":
        ensure  => directory,
        mode    => '0755',
        owner   => 'mysql',
        group   => 'mysql',
      }

      augeas{ 'backup_old_innodb_log_file_size':
        context => $mysql::server::config_file,
        changes => "mv ${options['mysqld']['datadir']}/ib_logfile* ${options['mysqld']['datadir']}/old_innodb_log_file/",
        onlyif  => "get mysqld/innodb_log_file_size != ${options['mysqld']['innodb_log_file_size']}",
        require => File["${options['mysqld']['datadir']}/old_innodb_log_file"],
        before  => File[$mysql::server::config_file],
      }
    }

    file { $mysql::server::config_file:
      content => template('mysql/my.cnf.erb'),
      mode    => '0644',
    }
  }
}
