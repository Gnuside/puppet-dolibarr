
# install apache
# ensure it runs
# enable mod_rewrite
# enable mod_php5

## CONFIG

class dolibarr {
}

define dolibarr::install (
  $root,
  $version = "3.4.0"
) {
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
    command => "tar -xzf ${archive_tmp} && mv ${src_path}/dolibarr-${version} ${dolibarr_path} && chown -R www-data:www-data ${dolibarr_path} && find ${dolibarr_path} -type f -exec chmod 644 {} \; && find ${dolibarr_path} -type d -exec chmod 755 {} \;",
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
    recurse => true,
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
    ensure    => exist,
    owner     => "www-data",
    group     => "www-data",
    mode      => 0644,
    require   => File["${root}/erp/configuration"]
  }

  file { "${root}/erp/root":
    ensure    => "link",
    target    => "${dolibarr_path}",
    owner     => "www-data",
    group     => "www-data",
    mode      => 0644,
    require   => File["${dolibarr_path}", "${root}/erp"]
  }

  file { "${root}/erp/root/htdocs/conf/conf.php":
    ensure    => "link",
    target    => "${root}/erp/configuration/conf.php",
    owner     => "www-data",
    group     => "www-data",
    mode      => 0644,
    require   => File["${dolibarr_path}", "${root}/erp/configuration/conf.php"]
  }

}

define dolibarr::configure (
  $http_root,
  $db_name,
  $db_user,
  $db_pswd
) {

}
