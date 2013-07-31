
# install apache
# ensure it runs
# enable mod_rewrite
# enable mod_php5

## CONFIG

class dolibarr {
}

define dolibarr::install (
  $root,
  $db_name,
  $version = "3.4.0"
) {
  $data_folder = "/vagrant/data/dolibarr"
  $src_path = "/usr/local/src"
  $archive_name = "dolibarr-${version}.tgz"
  $archive_url = "http://www.dolibarr.org/files/stable/standard/${archive_name}"
  $dolibarr_path = "${root}/dolibarr/${version}"
  $archive_tmp = "${src_path}/${archive_name}"

  file {["${root}/dolibarr"]:
    ensure => 'directory',
    owner => "www-data",
    group => "www-data",
    mode => 0644
  }

  exec { "dolibarr::install::download ${version}":
    require => File["${root}"],
    unless => "test -f ${archive_tmp}",
    command => "wget '${archive_url}' -O '${archive_tmp}' || \
                (rm '${archive_tmp}' && false)",
    user => "root",
    group => "root"
  }

  exec { "dolibarr::install::extract ${version} to ${dolibarr_path}":
    unless  => "test -d ${dolibarr_path}",
    cwd     => "${src_path}",
    command => "tar -xzf ${archive_tmp} && mv ${src_path}/dolibarr-${version} ${dolibarr_path} && chown -R www-data:www-data ${dolibarr_path} && find ${dolibarr_path} -type f -exec chmod 644 {} \\; && find ${dolibarr_path} -type d -exec chmod 755 {} \\;",
    require => [
      Exec["dolibarr::install::download ${version}"],
      File["${root}/dolibarr"]
    ]
  }

  file { "${dolibarr_path}":
    ensure => 'directory',
    owner => "www-data",
    group => "www-data",
    #owner => "root",
    #group => "root",
    mode => 644,
    require => Exec["dolibarr::install::extract ${version} to ${dolibarr_path}"]
  }

  file { ["${root}/erp", "${root}/erp/documents", "${root}/erp/configuration"]:
    ensure    => 'directory',
    owner     => "www-data",
    group     => "www-data",
    mode      => 0644
  }

  file { "${root}/erp/configuration/conf.php":
    ensure    => present,
    owner     => "www-data",
    group     => "www-data",
    mode      => 0644,
    content => template("${data_folder}/${db_name}.conf.php"),
    require   => File["${root}/erp/configuration"]
  }

  file { "${root}/erp/root":
    ensure    => "link",
    target    => "${dolibarr_path}",
    owner     => "www-data",
    group     => "www-data",
    mode      => 0644,
    require   => File["${dolibarr_path}", "${root}/erp", "${root}/erp/configuration/conf.php"]
  }

  file { "${root}/erp/root/htdocs/conf/conf.php":
    ensure    => "link",
    target    => "${root}/erp/configuration/conf.php",
    owner     => "www-data",
    group     => "www-data",
    mode      => 0644,
    require   => File["${root}/erp/root", "${dolibarr_path}", "${root}/erp/configuration/conf.php"]
  }

}

define dolibarr::pre_configure (
  $db_root_pwd,
  $http_root,
  $db_name,
  $db_user,
  $db_pswd
) {
  # this "function" allow to check and do what must be done previously to configuration
  $data_folder = "/vagrant/data/dolibarr"

}

define dolibarr::configure (
  $http_basename,
  $http_root,
  $db_name,
  $db_user,
  $db_pswd
) {
  $data_folder = "/vagrant/data/dolibarr"

  exec { "dolibarr::configure::db_extract":
    command   => "cat ${db_name}.sql.bz2 | bunzip2 -d > ${db_name}.sql",
    creates   => "${data_folder}/${db_name}.sql",
    cwd       => "${data_folder}"
  }

  exec { "dolibarr::configure::db_push":
    require   => Exec["dolibarr::configure::db_extract"],
    command   => "mysql --user=${db_user} --password=${db_pswd} ${db_name} < ${db_name}.sql",
    unless    => "mysql --user=${db_user} --password=${db_pswd} --execute='SHOW DATABASES LIKE \'com_gnuside_erp\';' | wc -l | grep -qv '^0$'",
    cwd       => "${data_folder}"
  }

  exec { "dolibarr::configure::db_upgrade":
    require   => Exec["dolibarr::configure::db_push"],
    command   => "/vagrant/puppet/remote-modules/dolibarr/scripts/upgrade_db.sh ${http_basename}"
  }

  file { "${http_root}/../../documents/install.lock":
    ensure    => "present",
    owner     => "www-data",
    group     => "www-data",
    mode      => 0644,
    require   => Exec["dolibarr::configure::db_upgrade"]
  }

  #  file { "${root}/erp/configuration/conf.php":
  #  ensure    => present,
  #  owner     => "www-data",
  #  group     => "www-data",
  #  mode      => 0400,
  #  require   => File["${http_root}/install.lock"]
  #}


}
