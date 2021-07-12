require 'spec_helper'
describe 'gnomish' do
  describe 'with defaults for all parameters' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('gnomish') }
    it { is_expected.to contain_class('gnomish::gnome') }
    it { is_expected.to have_package_resource_count(0) }
    it { is_expected.to have_gnomish__application_resource_count(0) }
    it { is_expected.to have_gnomish__gnome__gconftool_2_resource_count(0) }
    it { is_expected.to have_gnomish__mate__mateconftool_2_resource_count(0) }
  end

  describe 'with applications set to valid hash' do
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

  describe 'with desktop set to valid string <gnome> (default)' do
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

  describe 'with desktop set to valid string <mate>' do
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

  describe 'with gconf_name set to valid string <$(HOME)/.gconf-rspec>' do
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

  describe 'with packages_add set to valid array %w(rspec testing)' do
    let(:params) { { packages_add: ['rspec', 'testing'] } }

    ['rspec', 'testing'].each do |package|
      it { is_expected.to contain_package(package).with_ensure('present') }
    end
  end

  describe 'with packages_remove set to valid array %w(rspec testing)' do
    let(:params) { { packages_remove: ['rspec', 'testing'] } }

    ['rspec', 'testing'].each do |package|
      it { is_expected.to contain_package(package).with_ensure('absent') }
    end
  end

  describe 'with settings_xml set to valid hash' do
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

  describe 'with wallpaper_path set to valid string </usr/share/wallpapers/rspec.png>' do
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

  describe 'with wallpaper_source set to valid string </src/rspec.png>' do
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

  describe 'with hiera providing data from multiple levels' do
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

  describe 'variable type and content validations' do
    validations = {
      'absolute_path' => {
        name:    ['wallpaper_path'],
        valid:   ['/absolute/filepath', '/absolute/directory/'],
        invalid: ['string', ['array'], { 'ha' => 'sh' }, 3, 2.42, true, false, nil],
        message: 'is not an absolute path',
      },
      'array' => {
        name:    ['packages_add', 'packages_remove'],
        valid:   [['array']],
        invalid: ['string', { 'ha' => 'sh' }, 3, 2.42, true, false],
        message: 'is not an Array',
      },
      'boolean' => {
        name:    ['applications_hiera_merge', 'settings_xml_hiera_merge'],
        valid:   [true, false],
        invalid: ['true', 'false', 'string', ['array'], { 'ha' => 'sh' }, 3, 2.42, nil],
        message: '(is not a boolean|Unknown type of boolean given)',
      },
      'hash' => {
        name:    ['applications', 'settings_xml'],
        params:  { applications_hiera_merge: false, settings_xml_hiera_merge: false },
        valid:   [], # valid hashes are to complex to block test them here.
        invalid: ['string', 3, 2.42, ['array'], true, false, nil],
        message: 'is not a Hash',
      },
      'regex desktop' => {
        name:    ['desktop'],
        valid:   ['gnome', 'mate'],
        invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, true, false],
        message: 'must be <gnome> or <mate> and is set to',
      },
      'string' => {
        name:    ['gconf_name'],
        valid:   ['string'],
        invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, true, false],
        message: 'is not a string',
      },
      'string wallpaper_source' => {
        name:    ['wallpaper_source'],
        params:  { wallpaper_path: '/dst/rspec.png' },
        valid:   ['/src/rspec.png'],
        invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, true, false],
        message: 'is not a string',
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
