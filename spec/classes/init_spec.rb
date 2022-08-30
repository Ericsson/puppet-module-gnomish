require 'spec_helper'
describe 'gnomish' do
  on_supported_os.sort.each do |os, os_facts|
    describe "on #{os} with default values for parameters" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('gnomish') }
      it { is_expected.to contain_class('gnomish::gnome') }
      it { is_expected.to have_package_resource_count(0) }
      it { is_expected.to have_gnomish__application_resource_count(0) }
      it { is_expected.to have_gnomish__gnome__gconftool_2_resource_count(0) }
      it { is_expected.to have_gnomish__mate__mateconftool_2_resource_count(0) }
    end

    describe "on #{os} with applications set to valid hash" do
      let(:applications_hash) do
        {
          applications: {
            'from_param' => {
              'ensure'           => 'file',
              'entry_categories' => 'from_param',
              'entry_exec'       => 'exec',
              'entry_icon'       => 'icon',
            }
          }
        }
      end

      context 'when applications_hiera_merge set to <true> (default)' do
        let(:params) { applications_hash.merge({ applications_hiera_merge: true }) }

        it { is_expected.to have_gnomish__application_resource_count(0) }
      end

      context 'when applications_hiera_merge set to <false>' do
        let(:params) { applications_hash.merge({ applications_hiera_merge: false }) }

        it { is_expected.to have_gnomish__application_resource_count(1) }

        it do
          is_expected.to contain_gnomish__application('from_param').with(
            {
              'ensure'           => 'file',
              'entry_categories' => 'from_param',
              'entry_exec'       => 'exec',
              'entry_icon'       => 'icon',
            },
          )
        end
      end
    end

    describe "on #{os} with desktop set to valid string <gnome> (default)" do
      let(:params) do
        {
          desktop:          'gnome',
          wallpaper_path:   '/test/desktop/dst',
          wallpaper_source: '/test/desktop/src',
        }
      end

      it { is_expected.to contain_class('gnomish::gnome') }
      it { is_expected.to contain_gnomish__gnome__gconftool_2('set wallpaper').with_key('/desktop/gnome/background/picture_filename') }

      it do
        is_expected.to contain_file('wallpaper').with(
          {
            'before' => 'Gnomish::Gnome::Gconftool_2[set wallpaper]',
          },
        )
      end
    end

    describe "on #{os} with desktop set to valid string <mate>" do
      let(:params) do
        {
          desktop:          'mate',
          wallpaper_path:   '/test/desktop/dst',
          wallpaper_source: '/test/desktop/src',
        }
      end

      it { is_expected.to contain_class('gnomish::mate') }
      it { is_expected.to contain_gnomish__mate__mateconftool_2('set wallpaper').with_key('/desktop/mate/background/picture_filename') }
      it { is_expected.to contain_file('wallpaper').with_before('Gnomish::Mate::Mateconftool_2[set wallpaper]') }
    end

    describe "on #{os} with gconf_name set to valid string <$(HOME)/.gconf-rspec>" do
      let(:params) { { gconf_name: '$(HOME)/.gconf-rspec' } }

      it do
        is_expected.to contain_file_line('set_gconf_name').with(
          {
            'ensure' => 'present',
            'path'   => '/etc/gconf/2/path',
            'line'   => 'xml:readwrite:$(HOME)/.gconf-rspec',
            'match'  => '^xml:readwrite:',
          },
        )
      end
    end

    describe "on #{os} with packages_add set to valid array %w(rspec testing)" do
      let(:params) { { packages_add: ['rspec', 'testing'] } }

      ['rspec', 'testing'].each do |package|
        it { is_expected.to contain_package(package).with_ensure('present') }
      end
    end

    describe "on #{os} with packages_remove set to valid array %w(rspec testing)" do
      let(:params) { { packages_remove: ['rspec', 'testing'] } }

      ['rspec', 'testing'].each do |package|
        it { is_expected.to contain_package(package).with_ensure('absent') }
      end
    end

    describe "on #{os} with settings_xml set to valid hash" do
      let(:settings_xml_hash) do
        {
          settings_xml: {
            'from_param' => {
              'value' => 'from_param',
            }
          }
        }
      end

      context 'when settings_xml_hiera_merge set to <true> (default)' do
        let(:params) { settings_xml_hash.merge({ settings_xml_hiera_merge: true }) }

        it { is_expected.to have_gnomish__gnome__gconftool_2_resource_count(0) }
      end

      context 'when settings_xml_hiera_merge set to <false>' do
        let(:params) { settings_xml_hash.merge({ settings_xml_hiera_merge: false }) }

        it { is_expected.to have_gnomish__gnome__gconftool_2_resource_count(1) }
        it { is_expected.to contain_gnomish__gnome__gconftool_2('from_param').with_value('from_param') }
      end
    end

    describe "on #{os} with wallpaper_path set to valid string </usr/share/wallpapers/rspec.png>" do
      let(:params) { { wallpaper_path: '/usr/share/wallpapers/rspec.png' } }

      it { is_expected.to have_gnomish__gnome__gconftool_2_resource_count(1) }

      it do
        is_expected.to contain_gnomish__gnome__gconftool_2('set wallpaper').with(
          {
            'key'    => '/desktop/gnome/background/picture_filename',
            'value'  => '/usr/share/wallpapers/rspec.png',
          },
        )
      end
    end

    describe "on #{os} with wallpaper_source set to valid string </src/rspec.png>" do
      let(:params) { { wallpaper_source: '/src/rspec.png' } }

      it 'fail' do
        expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{gnomish::wallpaper_path is needed but undefiend\. Please define a valid path})
      end

      context 'when wallpaper_path is set to valid string </dst/rspec.png>' do
        let(:params) do
          {
            wallpaper_source: '/src/rspec.png',
            wallpaper_path:   '/dst/rspec.png',
          }
        end

        it do
          is_expected.to contain_file('wallpaper').with(
            {
              'ensure' => 'file',
              'path'   => '/dst/rspec.png',
              'owner'  => 'root',
              'group'  => 'root',
              'mode'   => '0644',
              'source' => '/src/rspec.png',
              'before' => 'Gnomish::Gnome::Gconftool_2[set wallpaper]',
            },
          )
        end
      end
    end

    describe "on #{os} with hiera providing data from multiple levels" do
      let(:facts) do
        {
          fqdn:  'gnomish.example.local',
          class: 'gnomish',
        }
      end

      context 'with defaults for all parameters' do
        it { is_expected.to have_gnomish__application_resource_count(4) }
        it { is_expected.to contain_gnomish__application('from_hiera_class') }
        it { is_expected.to contain_gnomish__application('from_hiera_fqdn') }
        it { is_expected.to contain_gnomish__application('from_hiera_class_gnome_specific') }
        it { is_expected.to contain_gnomish__application('from_hiera_fqdn_gnome_specific') }

        it { is_expected.to have_gnomish__gnome__gconftool_2_resource_count(4) }
        it { is_expected.to contain_gnomish__gnome__gconftool_2('from_hiera_class') }
        it { is_expected.to contain_gnomish__gnome__gconftool_2('from_hiera_fqdn') }
        it { is_expected.to contain_gnomish__gnome__gconftool_2('from_hiera_class_gnome_specific') }
        it { is_expected.to contain_gnomish__gnome__gconftool_2('from_hiera_fqdn_gnome_specific') }

        it { is_expected.to have_gnomish__mate__mateconftool_2_resource_count(0) }
      end

      context 'with applications_hiera_merge set to valid <false>' do
        let(:params) { { applications_hiera_merge: false } }

        it { is_expected.to have_gnomish__application_resource_count(3) }
        it { is_expected.to contain_gnomish__application('from_hiera_fqdn') }
        it { is_expected.to contain_gnomish__application('from_hiera_class_gnome_specific') }
        it { is_expected.to contain_gnomish__application('from_hiera_fqdn_gnome_specific') }

        it { is_expected.to have_gnomish__gnome__gconftool_2_resource_count(4) }
        it { is_expected.to contain_gnomish__gnome__gconftool_2('from_hiera_class') }
        it { is_expected.to contain_gnomish__gnome__gconftool_2('from_hiera_fqdn') }
        it { is_expected.to contain_gnomish__gnome__gconftool_2('from_hiera_class_gnome_specific') }
        it { is_expected.to contain_gnomish__gnome__gconftool_2('from_hiera_fqdn_gnome_specific') }

        it { is_expected.to have_gnomish__mate__mateconftool_2_resource_count(0) }
      end

      context 'with settings_xml_hiera_merge set to valid <false>' do
        let(:params) { { settings_xml_hiera_merge: false } }

        it { is_expected.to have_gnomish__application_resource_count(4) }
        it { is_expected.to contain_gnomish__application('from_hiera_class') }
        it { is_expected.to contain_gnomish__application('from_hiera_fqdn') }
        it { is_expected.to contain_gnomish__application('from_hiera_class_gnome_specific') }
        it { is_expected.to contain_gnomish__application('from_hiera_fqdn_gnome_specific') }

        it { is_expected.to have_gnomish__gnome__gconftool_2_resource_count(3) }
        it { is_expected.to contain_gnomish__gnome__gconftool_2('from_hiera_fqdn') }
        it { is_expected.to contain_gnomish__gnome__gconftool_2('from_hiera_class_gnome_specific') }
        it { is_expected.to contain_gnomish__gnome__gconftool_2('from_hiera_fqdn_gnome_specific') }

        it { is_expected.to have_gnomish__mate__mateconftool_2_resource_count(0) }
      end
    end
  end

  describe 'variable type and content validations' do
    # The following tests are OS independent, so we only test one supported OS
    redhat = {
      supported_os: [
        {
          'operatingsystem'        => 'RedHat',
          'operatingsystemrelease' => ['7'],
        },
      ],
    }

    on_supported_os(redhat).each do |_os, os_facts|
      let(:facts) { os_facts }

      validations = {
        'Array' => {
          name:    ['packages_add', 'packages_remove'],
          valid:   [['array']],
          invalid: ['string', { 'ha' => 'sh' }, 3, 2.42, false],
          message: 'expects an Array',
        },
        'Boolean' => {
          name:    ['applications_hiera_merge', 'settings_xml_hiera_merge'],
          valid:   [true, false],
          invalid: ['false', 'string', ['array'], { 'ha' => 'sh' }, 3, 2.42],
          message: 'expects a Boolean',
        },
        'Enum[gnome, mate]' => {
          name:    ['desktop'],
          valid:   ['gnome', 'mate'],
          invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, false],
          message: 'expects a match for Enum',
        },
        'Hash' => {
          name:    ['applications', 'settings_xml'],
          params:  { applications_hiera_merge: false, settings_xml_hiera_merge: false },
          valid:   [], # valid hashes are to complex to block test them here.
          invalid: ['string', 3, 2.42, ['array'], false],
          message: 'expects a Hash',
        },
        'Optional[Stdlib::Filesource]' => {
          name:    ['wallpaper_source'],
          params:  { wallpaper_path: '/test/ing' },
          valid:   ['puppet:///test', '/test/ing', 'file:///test/ing'],
          invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, false],
          message: 'expects a Stdlib::Filesource',
        },
        'Stdlib::Absolutepath' => {
          name:    ['wallpaper_path'],
          valid:   ['/absolute/filepath', '/absolute/directory/'],
          invalid: ['../invalid', ['/in/valid'], { 'ha' => 'sh' }, 3, 2.42, false],
          message: 'expects a Stdlib::Absolutepath',
        },
        'String[1]' => {
          name:    ['gconf_name'],
          valid:   ['string'],
          invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, false],
          message: '(expects a String value|value of type Undef or String)',
        },
      }

      validations.sort.each do |type, var|
        var[:name].each do |var_name|
          var[:params] = {} if var[:params].nil?
          var[:valid].each do |valid|
            context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
              let(:params) { [var[:params], { "#{var_name}": valid, }].reduce(:merge) }

              it { is_expected.to compile }
            end
          end

          var[:invalid].each do |invalid|
            context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
              let(:params) { [var[:params], { "#{var_name}": invalid, }].reduce(:merge) }

              it 'fail' do
                expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{#{var[:message]}})
              end
            end
          end
        end # var[:name].each
      end # validations.sort.each
    end # describe 'variable type and content validations'
  end
end
