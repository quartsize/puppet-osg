require 'spec_helper'

describe 'osg::bestman' do
  before { skip("Not supported by OSG 3.4") }
  on_supported_os({
    :supported_os => [
      {
        "operatingsystem" => "CentOS",
        "operatingsystemrelease" => ["6", "7"],
      }
    ]
  }).each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({
          :concat_basedir => '/dne',
          :puppetversion => Puppet.version,
        })
      end

      let(:params) {{ }}

      it { should compile.with_all_deps }
      it { should create_class('osg::bestman') }
      it { should contain_class('osg::params') }

      it { should contain_anchor('osg::bestman::start').that_comes_before('Class[osg]') }
      it { should contain_class('osg').that_comes_before('Class[osg::cacerts]') }
      it { should contain_class('osg::cacerts').that_comes_before('Class[osg::bestman::install]') }
      it { should contain_class('osg::bestman::install').that_comes_before('Class[osg::auth]') }
      it { should contain_class('osg::auth').that_comes_before('Class[osg::bestman::config]') }
      it { should contain_class('osg::bestman::config').that_notifies('Class[osg::bestman::service]') }
      it { should contain_class('osg::bestman::service').that_comes_before('Anchor[osg::bestman::end]') }
      it { should contain_anchor('osg::bestman::end') }

      it do
        should contain_firewall('100 allow SRMv2 access').with({
          :port    => '8443',
          :proto   => 'tcp',
          :action  => 'accept',
        })
      end

      context 'osg::bestman::install' do
        it do
          should contain_package('osg-se-bestman').with({
            :ensure  => 'installed',
          })
        end
      end

      context 'osg::bestman::config' do

        it { should contain_sudo__conf('bestman').with_priority('10') }

        it do
          verify_exact_contents(catalogue, '10_bestman', [
            'Defaults:bestman !requiretty',
            'Cmnd_Alias SRM_CMD = /bin/rm,/bin/mkdir,/bin/rmdir,/bin/mv,/bin/cp,/bin/ls',
            'Runas_Alias SRM_USR = ALL,!root',
            'bestman ALL=(SRM_USR) NOPASSWD: SRM_CMD'
          ])
        end

        it do
          should contain_file('/etc/grid-security/hostcert.pem').with({
            :ensure => 'file',
            :owner  => 'root',
            :group  => 'root',
            :mode   => '0444',
            :source => nil,
          })
        end

        it do
          should contain_file('/etc/grid-security/hostkey.pem').with({
            :ensure => 'file',
            :owner  => 'root',
            :group  => 'root',
            :mode   => '0400',
            :source => nil,
          })
        end

        it do
          should contain_file('/etc/grid-security/bestman').with({
            :ensure => 'directory',
            :owner  => 'root',
            :group  => 'root',
            :mode   => '0755',
          })
        end

        it do
          should contain_file('/etc/grid-security/bestman/bestmancert.pem').with({
            :ensure   => 'file',
            :owner    => 'bestman',
            :group    => 'bestman',
            :mode     => '0444',
            :source   => nil,
            :require  => 'File[/etc/grid-security/bestman]',
          })
        end

        it do
          should contain_file('/etc/grid-security/bestman/bestmankey.pem').with({
            :ensure   => 'file',
            :owner    => 'bestman',
            :group    => 'bestman',
            :mode     => '0400',
            :source   => nil,
            :require  => 'File[/etc/grid-security/bestman]',
          })
        end

        if Gem::Version.new(Gem.loaded_specs['puppet'].version.to_s) >= Gem::Version.new('3.2.0')
          it { should contain_file('/etc/grid-security/hostcert.pem').with_show_diff('false') }
          it { should contain_file('/etc/grid-security/hostkey.pem').with_show_diff('false') }
          it { should contain_file('/etc/grid-security/bestman/bestmancert.pem').with_show_diff('false') }
          it { should contain_file('/etc/grid-security/bestman/bestmankey.pem').with_show_diff('false') }
        else
          it { should contain_file('/etc/grid-security/hostcert.pem').without_show_diff }
          it { should contain_file('/etc/grid-security/hostkey.pem').without_show_diff }
          it { should contain_file('/etc/grid-security/bestman/bestmancert.pem').without_show_diff }
          it { should contain_file('/etc/grid-security/bestman/bestmankey.pem').without_show_diff }
        end

        it do
          should contain_file('/etc/sysconfig/bestman2').with({
            :ensure  => 'file',
            :owner   => 'root',
            :group   => 'root',
            :mode    => '0644',
          })
        end

        it do
          verify_exact_contents(catalogue, '/etc/sysconfig/bestman2', [
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
            "GLOBUS_HOSTNAME=#{facts[:fqdn]}",
            'BESTMAN_MAX_JAVA_HEAP=1024',
            'BESTMAN_EVENT_LOG_COUNT=10',
            'BESTMAN_EVENT_LOG_SIZE=20971520',
            'BESTMAN_GUMSCERTPATH=/etc/grid-security/bestman/bestmancert.pem',
            'BESTMAN_GUMSKEYPATH=/etc/grid-security/bestman/bestmankey.pem',
            'BESTMAN_GUMS_ENABLED=yes',
            'JETTY_DEBUG_ENABLED=no',
            'BESTMAN_GATEWAYMODE_ENABLED=yes',
            'BESTMAN_FULLMODE_ENABLED=no',
            'JAVA_CLIENT_MAX_HEAP=512',
            'JAVA_CLIENT_MIN_HEAP=32',
          ])
        end

        it do
          should contain_file('/etc/bestman2/conf/bestman2.rc').with({
            :ensure  => 'file',
            :owner   => 'root',
            :group   => 'root',
            :mode    => '0644',
          })
        end

        it do
          verify_exact_contents(catalogue, '/etc/bestman2/conf/bestman2.rc', [
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
            "GUMSserviceURL=https://gums.#{facts[:domain]}:8443/gums/services/GUMSXACMLAuthorizationServicePort",
            "GUMSCurrHostDN=/DC=com/DC=DigiCert-Grid/O=Open Science Grid/OU=Services/CN=#{facts[:fqdn]}",
            'disableSpaceMgt=true',
            'useBerkeleyDB=false',
            'noCacheLog=true',
            'Concurrency=40',
            'FactoryID=srm/v2/server',
            'noEventLog=false',
          ])
        end


        it do
          should contain_file('/var/log/bestman2').with({
            :ensure  => 'directory',
            :owner   => 'bestman',
            :group   => 'bestman',
            :mode    => '0755',
          })
        end

        context 'when bestmancert_source and bestmankey_source defined' do
          let(:params) {{ :bestmancert_source => 'file:///foo/hostcert.pem', :bestmankey_source => 'file:///foo/hostkey.pem' }}

          it { should contain_file('/etc/grid-security/hostcert.pem').without_source }
          it { should contain_file('/etc/grid-security/hostkey.pem').without_source }
          it { should contain_file('/etc/grid-security/bestman/bestmancert.pem').with_source('file:///foo/hostcert.pem') }
          it { should contain_file('/etc/grid-security/bestman/bestmankey.pem').with_source('file:///foo/hostkey.pem') }
        end

        context 'when hostcert_source and hostkey_source defined' do
          let(:params) {{ :hostcert_source => 'file:///foo/hostcert.pem', :hostkey_source => 'file:///foo/hostkey.pem' }}

          it { should contain_file('/etc/grid-security/hostcert.pem').with_source('file:///foo/hostcert.pem') }
          it { should contain_file('/etc/grid-security/hostkey.pem').with_source('file:///foo/hostkey.pem') }
          it { should contain_file('/etc/grid-security/bestman/bestmancert.pem').without_source }
          it { should contain_file('/etc/grid-security/bestman/bestmankey.pem').without_source }
        end
      end

      context 'osg::bestman::service' do
        it do
          should contain_service('bestman2').with({
            :ensure      => 'running',
            :enable      => 'true',
            :hasstatus   => 'true',
            :hasrestart  => 'true',
          })
        end
      end

      context "with localPathListAllowed => ['/tmp','/home']" do
        let(:params) {{ :local_path_list_allowed => ['/tmp', '/home'] }}
        it { verify_contents(catalogue, '/etc/bestman2/conf/bestman2.rc', ['localPathListAllowed=/tmp;/home']) }
      end

      context "with localPathListToBlock => ['/etc','/root']" do
        let(:params) {{ :local_path_list_to_block => ['/etc', '/root'] }}
        it { verify_contents(catalogue, '/etc/bestman2/conf/bestman2.rc', ['localPathListToBlock=/etc;/root']) }
      end

      context "with supportedProtocolList => ['gsiftp://gridftp1.example.com','gsiftp://gridftp2.example.com']" do
        let(:params) {{ :supported_protocol_list => ['gsiftp://gridftp1.example.com','gsiftp://gridftp2.example.com'] }}
        it { verify_contents(catalogue, '/etc/bestman2/conf/bestman2.rc', ['supportedProtocolList=gsiftp://gridftp1.example.com;gsiftp://gridftp2.example.com']) }
      end

      context "with host_dn => '/CN=foo'" do
        let(:params) {{ :host_dn => '/CN=foo' }}
        it { verify_contents(catalogue, '/etc/bestman2/conf/bestman2.rc', ['GUMSCurrHostDN=/CN=foo']) }
      end

      context "with globus_hostname => 'foo.example.com'" do
        let(:params) {{ :globus_hostname => 'foo.example.com' }}
        it { verify_contents(catalogue, '/etc/sysconfig/bestman2', ['GLOBUS_HOSTNAME=foo.example.com']) }
      end

      context 'with sudo_srm_commands => ["/foo/bar"]' do
        let(:params){{ :sudo_srm_commands => ['/foo/bar'] }}
        it do
          verify_exact_contents(catalogue, '10_bestman', [
            'Defaults:bestman !requiretty',
            'Cmnd_Alias SRM_CMD = /foo/bar',
            'Runas_Alias SRM_USR = ALL,!root',
            'bestman ALL=(SRM_USR) NOPASSWD: SRM_CMD'
          ])
        end
      end

      context 'with sudo_srm_commands => "/bin/rm, /bin/mkdir, /bin/rmdir, /bin/mv, /bin/cp, /bin/ls"' do
        let(:params){{ :sudo_srm_commands => '/bin/rm, /bin/mkdir, /bin/rmdir, /bin/mv, /bin/cp, /bin/ls' }}
        it do
          verify_exact_contents(catalogue, '10_bestman', [
            'Defaults:bestman !requiretty',
            'Cmnd_Alias SRM_CMD = /bin/rm, /bin/mkdir, /bin/rmdir, /bin/mv, /bin/cp, /bin/ls',
            'Runas_Alias SRM_USR = ALL,!root',
            'bestman ALL=(SRM_USR) NOPASSWD: SRM_CMD'
          ])
        end
      end

      context 'with sudo_srm_runas => "ALL, !root"' do
        let(:params){{ :sudo_srm_runas => 'ALL, !root' }}
        it do
          verify_exact_contents(catalogue, '10_bestman', [
            'Defaults:bestman !requiretty',
            'Cmnd_Alias SRM_CMD = /bin/rm,/bin/mkdir,/bin/rmdir,/bin/mv,/bin/cp,/bin/ls',
            'Runas_Alias SRM_USR = ALL, !root',
            'bestman ALL=(SRM_USR) NOPASSWD: SRM_CMD'
          ])
        end
      end

      context "with event_log_count => 20" do
        let(:params) {{ :event_log_count => 20 }}
        it { verify_contents(catalogue, '/etc/sysconfig/bestman2', ['BESTMAN_EVENT_LOG_COUNT=20']) }
      end

      context "with event_log_size => 50000000" do
        let(:params) {{ :event_log_size => 50000000 }}
        it { verify_contents(catalogue, '/etc/sysconfig/bestman2', ['BESTMAN_EVENT_LOG_SIZE=50000000']) }
      end

      context 'with manage_firewall => false' do
        let(:params) {{ :manage_firewall => false }}
        it { should_not contain_firewall('100 allow SRMv2 access') }
      end

      context 'with manage_sudo => false' do
        let(:params) {{ :manage_sudo => false }}
        it { should_not contain_sudo__conf('bestman') }
      end

      # Test validate_bool parameters
      [
        'manage_firewall',
        'manage_sudo',
      ].each do |param|
        context "with #{param} => 'foo'" do
          let(:params) {{ param.to_sym => 'foo' }}
          it { expect { should create_class('osg::bestman') }.to raise_error(Puppet::Error, /is not a boolean/) }
        end
      end

      # Test validate_array parameters
      [
        'local_path_list_to_block',
        'local_path_list_allowed',
        'supported_protocol_list',
      ].each do |param|
        context "with #{param} => 'foo'" do
          let(:params) {{ param.to_sym => 'foo' }}
          it { expect { should create_class('osg::bestman') }.to raise_error(Puppet::Error, /is not an Array/) }
        end
      end

    end
  end
end
