
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

  file { "${root}/erp/root":
    ensure    => "link",
    target    => "${dolibarr_path}",
    owner     => "www-data",
    group     => "www-data",
    mode      => 0644,
    require   => File["${dolibarr_path}", "${root}/erp"]
  }

  file { ["${root}/erp"]:
    ensure    => 'directory',
    owner     => "www-data",
    group     => "www-data",
    mode      => 0644
  }

  ## CONFIGURATION files sections

  exec { "Create ${root}/erp/configuration-${version}":
    # Create a new empty directory only if the link configuration doesn't already
    # exist. If it already exist, it is probably because there is a previous
    # version installed, and we need to update it. So we don't execuce this node.
    unless    => "test -d ${root}/erp/configuration",
    cwd       => "${root}/erp",
    command   => "mkdir -p configuration-${version} && chown www-data:www-data configuration-${version} && chmod 0644 configuration-${version}",
    before    => File["${root}/erp/configuration"]
  }

  exec { "COPY old configuration to ${root}/erp/configuration-${version}":
    # Opposite node to copy the content of the old configuration folder.
    onlyif    => "test -d ${root}/erp/configuration -a ! -d ${root}/erp/configuration-${version}",
    cwd       => "${root}/erp",
    command   => "cp -Rp configuration/ configuration-${version}",
    before    => File["${root}/erp/configuration"]
  }

  file { "${root}/erp/configuration":
    # This node must be applied only after creation or copy of
    # configuration-${version} folder.
    ensure    => 'link',
    target    => "${root}/erp/configuration-${version}",
    owner     => "www-data",
    group     => "www-data",
    mode      => 0644
  }

  ## DOCUMENTS files sections

  exec { "Create ${root}/erp/documents-${version}":
    # Create a new empty directory only if the link documents doesn't already
    # exist. If it already exist, it is probably because there is a previous
    # version installed, and we need to update it. So we don't execuce this node.
    unless    => "test -d ${root}/erp/documents",
    cwd       => "${root}/erp",
    command   => "mkdir -p documents-${version} && chown www-data:www-data documents-${version} && chmod 0644 documents-${version}",
    before    => File["${root}/erp/documents"]
  }

  exec { "COPY old documents to ${root}/erp/documents-${version}":
    # Opposite node to copy the content of the old configuration folder.
    onlyif    => "test -d ${root}/erp/documents -a ! -d ${root}/erp/documents-${version}",
    cwd       => "${root}/erp",
    command   => "cp -Rp documents/ documents-${version}",
    before    => File["${root}/erp/documents"]
  }

  file { "${root}/erp/documents":
    # This node must be applied only after creation or copy of
    # configuration-${version} folder.
    ensure    => 'link',
    target    => "${root}/erp/documents-${version}",
    owner     => "www-data",
    group     => "www-data",
    mode      => 0644
  }



}

define dolibarr::configure (
  $root,
  $http_basename,
  $http_root,
  $db_name,
  $db_user,
  $db_pswd
) {
  $data_folder = "/vagrant/data/dolibarr"


  ## Configuration file part.
  exec { "COPY ${root}/erp/configuration/conf.php from Data":
    # This node is to restore a configuration script placed in data_folder.
    onlyif    => "test -e ${data_folder}/${db_name}.conf.php",
    cwd       => "${root}/erp/configuration",
    command   => "cp ${data_folder}/${db_name}.conf.php conf.php",
    before    => File["${root}/erp/configuration/conf.php"]
  }

  file { "${root}/erp/configuration/conf.php":
    # Create the file empty if it doesn't exist (not copied below), and unsure
    # permissions and ownership.
    ensure    => present,
    owner     => "www-data",
    group     => "www-data",
    mode      => 0644,
    before    => File["${root}/erp/root/htdocs/conf/conf.php"]
  }

  file { "${root}/erp/root/htdocs/conf/conf.php":
    ensure    => "link",
    target    => "${root}/erp/configuration/conf.php",
    owner     => "www-data",
    group     => "www-data",
    mode      => 0644
  }

  ## Restore Database from data folder
  exec { "dolibarr::configure::db_extract_n_push":
    # Push database stored in data folder except if a database already exist.
    onlyif    => "test -e ${data_folder}/${db_name}.sql.bz2",
    unless    => "mysql --user=${db_user} --password=${db_pswd} --execute=\"SHOW TABLES FROM '${db_name}';\" | wc -l | grep -qv '^0$'",
    command   => "cat ${db_name}.sql.bz2 | bunzip2 -d | mysql --user=${db_user} --password=${db_pswd} ${db_name}",
    cwd       => "${data_folder}"
  }


  ## Restore documents from data folder
  exec { "dolibarr::configure::doc_extract_n_copy":
    onlyif    => "test -e ${data_folder}/${db_name}.doc.tar.bz2",
    command   => "tar -xjkf ${data_folder}/${db_name}.doc.tar.bz2",
    cwd       => "${root}/erp"
  }


  ## Upgrade through the interface if needed !
  exec { "dolibarr::configure::upgrade":
    require   => Exec["dolibarr::configure::db_extract_n_push"],
    command   => "/vagrant/puppet/remote-modules/dolibarr/scripts/upgrade.sh ${http_basename}"
  }


  ## Locking installation

  file { "${root}/erp/documents/install.lock":
    ensure    => "present",
    owner     => "www-data",
    group     => "www-data",
    mode      => 0644,
    require   => [
      Exec[
        "dolibarr::configure::upgrade",
        "dolibarr::configure::doc_extract_n_copy"
      ],
      File["${root}/erp/root/htdocs/conf/conf.php"]
    ]
  }

  exec { "dolibarr::configure::configuration/conf.php reset permissions":
    command   => "chmod 0400 ${root}/erp/configuration/conf.php",
    require   => File["${root}/erp/documents/install.lock"]
  }


}
