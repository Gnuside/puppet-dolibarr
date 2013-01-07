
# install apache 
# ensure it runs
# enable mod_rewrite
# enable mod_php5

## CONFIG

class apache2 {
  $apache2_sites = "/etc/apache2/sites"
  $apache2_includes = "/etc/apache2/site-includes"
  $apache2_mods = "/etc/apache2/mods"
  $apache2_conf = "/etc/apache2/conf.d"
  $apache2_root = "/var/www"


  # setup packages
  package {
    "apache2": ensure => installed ;
    "apache2-mpm-prefork": ensure => installed ;
  }

  include apache2::service
}

class apache2::service {
  # setup service
  service { "apache2":
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    require => [Package["apache2"], Package["apache2-mpm-prefork"]],
  }

  # Notify this when apache needs a reload. This is only needed when
  # sites are added or removed, since a full restart then would be
  # a waste of time. When the module-config changes, a force-reload is
  # needed.
  exec { "reload-apache2":
    command => "/usr/sbin/service apache2 reload",
    refreshonly => true,
  }

  exec { "force-reload-apache2":
    command => "/usr/sbin/service apache2 force-reload",
    refreshonly => true,
  }
}

define apache2::vhost ( $domain = "", $documentroot = "" ) {
  include apache2

  if $domain == "" {
    $vhost_domain = $name
    } else {
      $vhost_domain = $domain
    }

    if $documentroot == "" {
      $vhost_root = "${apache2_root}/${name}"
      } else {
        $vhost_root = $documentroot
      }

      file { "${apache2::apache2_sites}-available/${vhost_domain}":
        ensure => 'present',
        content => template("apache2/vhost.erb"),
        require => Package['apache2'],
        ## notify => Exec["enable-${vhost_domain}-vhost"],
        }
}


# Define an apache2 site. Place all site configs into
# /etc/apache2/sites-available and en-/disable them with this type.
#
# You can add a custom require (string) if the site depends on packages
# that aren't part of the default apache2 package. Because of the
# package dependencies, apache2 will automagically be included.
define apache2::site ( $ensure = 'present') {
  include apache2

  case $ensure {
    'present' : {
      exec { "/usr/sbin/a2ensite $name":
        unless => "/bin/readlink -e ${apache2::apache2_sites}-enabled/$name",
        notify => Exec["reload-apache2"],
        require => File["${apache2::apache2_sites}-available/$name"],
      }
    }

    'absent' : {
      exec { "/usr/sbin/a2dissite $name":
        onlyif => "/bin/readlink -e ${apache2::apache2_sites}-enabled/$name",
        notify => Exec["reload-apache2"],
        require => File["${apache2::apache2_sites}-available/$name"],
      }
    }
    default: { err ( "Unknown ensure value: '$ensure'" ) }
  }
}

# Define an apache2 module. Debian packages place the module config
# into /etc/apache2/mods-available.
#
# You can add a custom require (string) if the module depends on 
# packages that aren't part of the default apache2 package. Because of 
# the package dependencies, apache2 will automagically be included.
define apache2::module ( $ensure = 'present', $require = 'apache2' ) {
  case $ensure {
    'present' : {
      #notice("pif : $require")
      exec { "/usr/sbin/a2enmod $name":
        unless => "/bin/readlink -e ${apache2::apache2_mods}-enabled/${name}.load",
        notify => Exec["force-reload-apache2"],
        require => Package[$require],
      }
    }
    'absent': {
      exec { "/usr/sbin/a2dismod $name":
        onlyif => "/bin/readlink -e ${apache2::apache2_mods}-enabled/${name}.load",
        notify => Exec["force-reload-apache2"],
        require => Package["apache2"],
      }
    }
    default: { err ( "Unknown ensure value: '$ensure'" ) }
  }
}


