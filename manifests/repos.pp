# Private class: See README.md.
class osg::repos {

  include osg
  include osg::params

  $repo_baseurl_bit       = $osg::repo_baseurl_bit
  $osg_release            = $osg::osg_release
  $os_releasever          = $osg::params::os_releasever
  $yum_priorities_package = $osg::params::yum_priorities_package

  if $osg::repo_use_mirrors {
    $baseurls   = {
      'osg'                       => 'absent',
      'osg-empty'                 => 'absent',
      'osg-contrib'               => 'absent',
      'osg-development'           => 'absent',
      'osg-testing'               => 'absent',
      'osg-upcoming'              => 'absent',
      'osg-upcoming-development'  => 'absent',
      'osg-upcoming-testing'      => 'absent',
    }

    $mirrorlists = {
      'osg'                       => "http://repo.grid.iu.edu/mirror/osg/${osg_release}/el${os_releasever}/release/${::architecture}",
      'osg-empty'                 => "http://repo.grid.iu.edu/mirror/osg/${osg_release}/el${os_releasever}/empty/${::architecture}",
      'osg-contrib'               => "http://repo.grid.iu.edu/mirror/osg/${osg_release}/el${os_releasever}/contrib/${::architecture}",
      'osg-development'           => "http://repo.grid.iu.edu/mirror/osg/${osg_release}/el${os_releasever}/development/${::architecture}",
      'osg-testing'               => "http://repo.grid.iu.edu/mirror/osg/${osg_release}/el${os_releasever}/testing/${::architecture}",
      'osg-upcoming'              => "http://repo.grid.iu.edu/mirror/osg/upcoming/el${os_releasever}/release/${::architecture}",
      'osg-upcoming-development'  => "http://repo.grid.iu.edu/mirror/osg/upcoming/el${os_releasever}/development/${::architecture}",
      'osg-upcoming-testing'      => "http://repo.grid.iu.edu/mirror/osg/upcoming/el${os_releasever}/testing/${::architecture}",
    }
  } else {
    $baseurls   = {
      'osg'                       => "${repo_baseurl_bit}/osg/${osg_release}/el${os_releasever}/release/${::architecture}",
      'osg-empty'                 => "${repo_baseurl_bit}/osg/${osg_release}/el${os_releasever}/empty/${::architecture}",
      'osg-contrib'               => "${repo_baseurl_bit}/osg/${osg_release}/el${os_releasever}/contrib/${::architecture}",
      'osg-development'           => "${osg::repo_development_baseurl_bit_real}/osg/${osg_release}/el${os_releasever}/development/${::architecture}",
      'osg-testing'               => "${osg::repo_testing_baseurl_bit_real}/osg/${osg_release}/el${os_releasever}/testing/${::architecture}",
      'osg-upcoming'              => "${osg::repo_upcoming_baseurl_bit_real}/osg/upcoming/el${os_releasever}/release/${::architecture}",
      'osg-upcoming-development'  => "${osg::repo_upcoming_baseurl_bit_real}/osg/upcoming/el${os_releasever}/development/${::architecture}",
      'osg-upcoming-testing'      => "${osg::repo_upcoming_baseurl_bit_real}/osg/upcoming/el${os_releasever}/testing/${::architecture}",
    }

    $mirrorlists = {
      'osg'                       => 'absent',
      'osg-empty'                 => 'absent',
      'osg-contrib'               => 'absent',
      'osg-development'           => 'absent',
      'osg-testing'               => 'absent',
      'osg-upcoming'              => 'absent',
      'osg-upcoming-development'  => 'absent',
      'osg-upcoming-testing'      => 'absent',
    }
  }

  ensure_packages([$yum_priorities_package])

  file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-OSG':
    ensure => 'file',
    source => 'puppet:///modules/osg/RPM-GPG-KEY-OSG',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  gpg_key { 'osg':
    path    => '/etc/pki/rpm-gpg/RPM-GPG-KEY-OSG',
  }

  Yumrepo {
    failovermethod  => 'priority',
    gpgcheck        => '1',
    gpgkey          => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-OSG',
    priority        => '98',
    require         => [Yumrepo['epel'], Gpg_key['osg']],
  }

  #TODO : Need consider_as_osg=yes
  yumrepo { 'osg':
    baseurl    => $baseurls['osg'],
    mirrorlist => $mirrorlists['osg'],
    descr      => "OSG Software for Enterprise Linux ${os_releasever} - ${::architecture}",
    enabled    => '1',
  }

  if versioncmp($osg_release, '3.2') >= 0 {
    yumrepo { 'osg-empty':
      baseurl    => $baseurls['osg-empty'],
      mirrorlist => $mirrorlists['osg-empty'],
      descr      => "OSG Software for Enterprise Linux ${os_releasever} - Empty Packages - ${::architecture}",
      enabled    => '1',
    }
  }

  yumrepo { 'osg-contrib':
    baseurl    => $baseurls['osg-contrib'],
    mirrorlist => $mirrorlists['osg-contrib'],
    descr      => "OSG Software for Enterprise Linux ${os_releasever} - Contributed - ${::architecture}",
    enabled    => bool2num($osg::enable_osg_contrib),
  }

  yumrepo { 'osg-development':
    baseurl    => $baseurls['osg-development'],
    mirrorlist => $mirrorlists['osg-development'],
    descr      => "OSG Software for Enterprise Linux ${os_releasever} - Development - ${::architecture}",
    enabled    => '0',
  }

  yumrepo { 'osg-testing':
    baseurl    => $baseurls['osg-testing'],
    mirrorlist => $mirrorlists['osg-testing'],
    descr      => "OSG Software for Enterprise Linux ${os_releasever} - Testing - ${::architecture}",
    enabled    => '0',
  }

  yumrepo { 'osg-upcoming':
    baseurl    => $baseurls['osg-upcoming'],
    mirrorlist => $mirrorlists['osg-upcoming'],
    descr      => "OSG Software for Enterprise Linux ${os_releasever} - Upcoming - ${::architecture}",
    enabled    => '0',
  }

  yumrepo { 'osg-upcoming-development':
    baseurl    => $baseurls['osg-upcoming-development'],
    mirrorlist => $mirrorlists['osg-upcoming-development'],
    descr      => "OSG Software for Enterprise Linux ${os_releasever} - Upcoming Development - ${::architecture}",
    enabled    => '0',
  }

  yumrepo { 'osg-upcoming-testing':
    baseurl    => $baseurls['osg-upcoming-testing'],
    mirrorlist => $mirrorlists['osg-upcoming-testing'],
    descr      => "OSG Software for Enterprise Linux ${os_releasever} - Upcoming Testing - ${::architecture}",
    enabled    => '0',
  }

}
