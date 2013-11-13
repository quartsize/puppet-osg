require 'spec_helper'

describe 'osg::bestman' do
  include_context :defaults

  let(:facts) { default_facts }

  let(:params) {{ }}

  let :pre_condition do
    [
      "class { 'osg::lcmaps': gums_hostname => 'gums.foo' }",
    ]
  end

  it { should create_class('osg::bestman') }
  it { should contain_class('osg::params') }
  it { should include_class('osg::repo') }
  it { should include_class('osg::cacerts::empty') }
  it { should include_class('osg::lcmaps') }

  it do
    should contain_firewall('100 allow SRMv2 access').with({
      'port'    => '8443',
      'proto'   => 'tcp',
      'action'  => 'accept',
    })
  end

  it { should contain_sudo__conf('bestman').with_priority('10') }

  it do
    content = subject.resource('file', '10_bestman').send(:parameters)[:content]
    content.split("\n").reject { |c| c =~ /(^#|^$)/ }.should == [
      'Defaults:bestman !requiretty',
      'Cmnd_Alias SRM_CMD = /bin/rm,/bin/mkdir,/bin/rmdir,/bin/mv,/bin/cp,/bin/ls',
      'Runas_Alias SRM_USR = ALL,!root',
      'bestman ALL=(SRM_USR) NOPASSWD: SRM_CMD'
    ]
  end

  it do
    should contain_package('osg-se-bestman').with({
      'ensure'  => 'installed',
      'require' => ['Yumrepo[osg]', 'Package[empty-ca-certs]'],
      'before'  => [ 'File[/etc/sysconfig/bestman2]', 'File[/etc/bestman2/conf/bestman2.rc]' ],
    })
  end

  it do
    should contain_file('/etc/sysconfig/bestman2').with({
      'ensure'  => 'present',
      'owner'   => 'root',
      'group'   => 'root',
      'mode'    => '0644',
    })
  end

  it do
    content = subject.resource('file', '/etc/sysconfig/bestman2').send(:parameters)[:content]
    content.split("\n").reject { |c| c =~ /(^#|^$)/ }.should == [
      'SRM_HOME=/etc/bestman2',
      'BESTMAN_SYSCONF=/etc/sysconfig/bestman2',
      'BESTMAN_SYSCONF_LIB=/etc/sysconfig/bestman2lib',
      'BESTMAN2_CONF=/etc/bestman2/conf/bestman2.rc',
      'JAVA_HOME=/etc/alternatives/java_sdk',
      'BESTMAN_LOG=/var/log/bestman2/bestman2.log',
      'BESTMAN_PID=/var/run/bestman2.pid',
      'BESTMAN_LOCK=/var/lock/bestman2',
      'SRM_OWNER=bestman',
      'BESTMAN_LIB=/usr/share/java/bestman2',
      'X509_CERT_DIR=/etc/grid-security/certificates',
      'GLOBUS_HOSTNAME=foo.example.tld',
      'BESTMAN_MAX_JAVA_HEAP=1024',
      'BESTMAN_GUMSCERTPATH=/etc/grid-security/bestman/bestmancert.pem',
      'BESTMAN_GUMSKEYPATH=/etc/grid-security/bestman/bestmankey.pem',
      'BESTMAN_GUMS_ENABLED=yes',
      'JETTY_DEBUG_ENABLED=no',
      'BESTMAN_GATEWAYMODE_ENABLED=yes',
      'BESTMAN_FULLMODE_ENABLED=no',
      'JAVA_CLIENT_MAX_HEAP=512',
      'JAVA_CLIENT_MIN_HEAP=32',
    ]
  end

  it do
    should contain_file('/etc/bestman2/conf/bestman2.rc').with({
      'ensure'  => 'present',
      'owner'   => 'root',
      'group'   => 'root',
      'mode'    => '0644',
    })
  end

  it do
    content = subject.resource('file', '/etc/bestman2/conf/bestman2.rc').send(:parameters)[:content]
    content.split("\n").reject { |c| c =~ /(^#|^$)/ }.should == [
      'EventLogLocation=/var/log/bestman2',
      'eventLogLevel=INFO',
      'securePort=8443',
      'CertFileName=/etc/grid-security/bestman/bestmancert.pem',
      'KeyFileName=/etc/grid-security/bestman/bestmankey.pem',
      'pathForToken=true',
      'fsConcurrency=40',
      'checkSizeWithFS=true',
      'checkSizeWithGsiftp=false',
      'accessFileSysViaSudo=true',
      'noSudoOnLs=true',
      'accessFileSysViaGsiftp=false',
      'MaxMappedIDCached=1000',
      'LifetimeSecondsMappedIDCached=1800',
      'GUMSProtocol=XACML',
      'GUMSserviceURL=https://gums.foo:8443/gums/services/GUMSXACMLAuthorizationServicePort',
      'disableSpaceMgt=true',
      'useBerkeleyDB=false',
      'noCacheLog=true',
      'Concurrency=40',
      'FactoryID=srm/v2/server',
      'noEventLog=false',
    ]
  end

  it do
    should contain_service('bestman2').with({
      'ensure'      => 'running',
      'enable'      => 'true',
      'hasstatus'   => 'true',
      'hasrestart'  => 'true',
      'subscribe'   => [ 'File[/etc/sysconfig/bestman2]', 'File[/etc/bestman2/conf/bestman2.rc]' ]
    })
  end

  context "with ca_certs_type => 'osg'" do
    let(:params) {{ :ca_certs_type => 'osg' }}
    it { should include_class('osg::cacerts') }
    it { should contain_package('osg-se-bestman').with_require(['Yumrepo[osg]', 'Package[osg-ca-certs]']) }
  end

  context "with ca_certs_type => 'igtf'" do
    let(:params) {{ :ca_certs_type => 'igtf' }}
    it { should include_class('osg::cacerts::igtf') }
    it { should contain_package('osg-se-bestman').with_require(['Yumrepo[osg]', 'Package[igtf-ca-certs]']) }
  end

  context "with localPathListAllowed => ['/tmp','/home']" do
    let(:params) {{ :localPathListAllowed => ['/tmp', '/home'] }}
    it { verify_contents(subject, '/etc/bestman2/conf/bestman2.rc', ['localPathListAllowed=/tmp;/home']) }
  end

  context "with localPathListToBlock => ['/etc','/root']" do
    let(:params) {{ :localPathListToBlock => ['/etc', '/root'] }}
    it { verify_contents(subject, '/etc/bestman2/conf/bestman2.rc', ['localPathListToBlock=/etc;/root']) }
  end

  context "with supportedProtocolList => ['gsiftp://gridftp1.example.com','gsiftp://gridftp2.example.com']" do
    let(:params) {{ :supportedProtocolList => ['gsiftp://gridftp1.example.com','gsiftp://gridftp2.example.com'] }}
    it { verify_contents(subject, '/etc/bestman2/conf/bestman2.rc', ['supportedProtocolList=gsiftp://gridftp1.example.com;gsiftp://gridftp2.example.com']) }
  end

  context "with gums_CurrHostDN => '/CN=foo'" do
    let(:params) {{ :gums_CurrHostDN => '/CN=foo' }}
    it { verify_contents(subject, '/etc/bestman2/conf/bestman2.rc', ['GUMSCurrHostDN=/CN=foo']) }
  end

  context "with globus_hostname => 'foo.example.com'" do
    let(:params) {{ :globus_hostname => 'foo.example.com' }}
    it { verify_contents(subject, '/etc/sysconfig/bestman2', ['GLOBUS_HOSTNAME=foo.example.com']) }
  end

  context 'with sudo_srm_commands => ["/foo/bar"]' do
    let(:params){{ :sudo_srm_commands => ['/foo/bar'] }}
    it do
      content = subject.resource('file', '10_bestman').send(:parameters)[:content]
      content.split("\n").reject { |c| c =~ /(^#|^$)/ }.should == [
        'Defaults:bestman !requiretty',
        'Cmnd_Alias SRM_CMD = /foo/bar',
        'Runas_Alias SRM_USR = ALL,!root',
        'bestman ALL=(SRM_USR) NOPASSWD: SRM_CMD'
      ]
    end
  end

  context 'with sudo_srm_commands => "/bin/rm, /bin/mkdir, /bin/rmdir, /bin/mv, /bin/cp, /bin/ls"' do
    let(:params){{ :sudo_srm_commands => '/bin/rm, /bin/mkdir, /bin/rmdir, /bin/mv, /bin/cp, /bin/ls' }}
    it do
      content = subject.resource('file', '10_bestman').send(:parameters)[:content]
      content.split("\n").reject { |c| c =~ /(^#|^$)/ }.should == [
        'Defaults:bestman !requiretty',
        'Cmnd_Alias SRM_CMD = /bin/rm, /bin/mkdir, /bin/rmdir, /bin/mv, /bin/cp, /bin/ls',
        'Runas_Alias SRM_USR = ALL,!root',
        'bestman ALL=(SRM_USR) NOPASSWD: SRM_CMD'
      ]
    end
  end

  context 'with sudo_srm_runas => "ALL, !root"' do
    let(:params){{ :sudo_srm_runas => 'ALL, !root' }}
    it do
      content = subject.resource('file', '10_bestman').send(:parameters)[:content]
      content.split("\n").reject { |c| c =~ /(^#|^$)/ }.should == [
        'Defaults:bestman !requiretty',
        'Cmnd_Alias SRM_CMD = /bin/rm,/bin/mkdir,/bin/rmdir,/bin/mv,/bin/cp,/bin/ls',
        'Runas_Alias SRM_USR = ALL, !root',
        'bestman ALL=(SRM_USR) NOPASSWD: SRM_CMD'
      ]
    end
  end

  context 'with service_ensure => stopped' do
    let(:params){{ :service_ensure => 'stopped' }}

    it { should contain_service('bestman2').with_ensure('stopped') }
  end

  context 'with service_ensure => "undef"' do
    let(:params) {{ :service_ensure => "undef" }}
    it { should contain_service('bestman2').with_ensure(nil) }
  end

  context 'with service_enable => "undef"' do
    let(:params) {{ :service_enable => "undef" }}
    it { should contain_service('bestman2').with_enable(nil) }
  end

  context 'with service_autorestart => false' do
    let(:params) {{ :service_autorestart => false }}
    it { should contain_service('bestman2').with_subscribe(nil) }
  end

  context 'with manage_firewall => false' do
    let(:params) {{ :manage_firewall => false }}
    it { should_not contain_firewall('100 allow bestman2 access') }
  end

  context 'with manage_sudo => false' do
    let(:params) {{ :manage_sudo => false }}
    it { should_not contain_sudo__conf('bestman') }
  end

  [
    'with_gridmap_auth',
    'with_gums_auth',
    'manage_firewall',
    'manage_sudo',
  ].each do |bool_param|
    context "with #{bool_param} => 'foo'" do
      let(:params) {{ bool_param.to_sym => 'foo' }}
      it { expect { should create_class('osg::cacerts::updater') }.to raise_error(Puppet::Error, /is not a boolean/) }
    end
  end
end
