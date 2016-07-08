require 'spec_helper'
describe 'gnomish' do
  describe 'with defaults for all parameters' do
    it { should compile.with_all_deps }
    it { should contain_class('gnomish') }
    it { should contain_class('gnomish::gnome') }
    it { should have_package_resource_count(0) }
    it { should have_gnomish__application_resource_count(0) }
    it { should have_gnomish__gnome__gconf_resource_count(0) }
    it { should have_gnomish__mate__mateconf_resource_count(0) }
  end

  describe 'with applications set to valid hash' do
    context 'when applications_hiera_merge set to <true>' do
      let(:params) do
        {
          :applications => {
            'from_param' => {
              'ensure'           => 'file',
              'entry_categories' => 'from_param',
              'entry_exec'       => 'exec',
              'entry_icon'       => 'icon',
            }
          },
          :applications_hiera_merge => true,
        }
      end
      it { should have_gnomish__application_resource_count(0) }
    end

    context 'when applications_hiera_merge set to <false>' do
      let(:params) do
        {
          :applications => {
            'from_param' => {
              'ensure'           => 'file',
              'entry_categories' => 'from_param',
              'entry_exec'       => 'exec',
              'entry_icon'       => 'icon',
            }
          },
          :applications_hiera_merge => false,
        }
      end
      it { should have_gnomish__application_resource_count(1) }

      it do
        should contain_gnomish__application('from_param').with({
          'ensure'           => 'file',
          'entry_categories' => 'from_param',
          'entry_exec'       => 'exec',
          'entry_icon'       => 'icon',
        })
      end
    end
  end

  describe 'with applications provided from hiera' do
    let(:facts) do
      {
        :fqdn  => 'desktop.example.local',
        :class => 'desktop',
      }
    end

    context 'when applications_hiera_merge set to <true>' do
      let(:params) { { :applications_hiera_merge => true } }

      it { should have_gnomish__application_resource_count(2) }

      it do
        should contain_gnomish__application('from_hiera_class').with({
          'ensure'           => 'file',
          'entry_categories' => 'from_hiera',
          'entry_exec'       => 'exec',
          'entry_icon'       => 'icon',
        })
      end

      it do
        should contain_gnomish__application('from_hiera_fqdn').with({
          'ensure'           => 'file',
          'entry_categories' => 'from_hiera',
          'entry_exec'       => 'exec',
          'entry_icon'       => 'icon',
        })
      end
    end

    context 'with data provided from hiera & applications_hiera_merge set to <false>' do
      let(:params) { { :applications_hiera_merge => false } }

      it { should have_gnomish__application_resource_count(1) }
      it { should_not contain_gnomish__application('from_hiera__parameter') }

      it do
        should contain_gnomish__application('from_hiera_fqdn').with({
          'ensure'           => 'file',
          'entry_categories' => 'from_hiera',
          'entry_exec'       => 'exec',
          'entry_icon'       => 'icon',
        })
      end
    end
  end

  describe 'with desktop set to valid string <gnome>' do
    let(:params) { { :desktop => 'gnome' } }
    it { should compile.with_all_deps }
    it { should contain_class('gnomish::gnome') }
    it { should_not contain_class('gnomish::mate') }

    context 'with settings set to valid hash' do
      context 'when settings_hiera_merge set to <true>' do
        let(:params) do
          {
            :settings => {
              'from_param' => {
                'value'  => 'from_param',
              }
            },
            :settings_hiera_merge => true,
            :desktop              => 'gnome',
          }
        end
        it { should have_gnomish__gnome__gconf_resource_count(0) }
      end
      context 'when settings_hiera_merge set to <false>' do
        let(:params) do
          {
            :settings => {
              'from_param' => {
                'value'  => 'from_param',
              }
            },
            :settings_hiera_merge => false,
            :desktop              => 'gnome',
          }
        end
        it { should have_gnomish__gnome__gconf_resource_count(1) }

        it do
          should contain_gnomish__gnome__gconf('from_param').with({
            'value' => 'from_param',
          })
        end
      end
    end

    context 'with settings provided from hiera' do
      let(:facts) do
        {
          :fqdn  => 'desktop.example.local',
          :class => 'desktop',
        }
      end

      context 'when settings_hiera_merge set to <true>' do
        let(:params) do
          {
            :settings_hiera_merge => true,
            :desktop              => 'gnome',
          }
        end

        it { should have_gnomish__gnome__gconf_resource_count(2) }

        it do
          should contain_gnomish__gnome__gconf('from_hiera_class').with({
            'key'    => '/rspec_from_hiera_class',
            'value'  => 'test',
            'config' => 'mandatory',
          })
        end

        it do
          should contain_gnomish__gnome__gconf('from_hiera_fqdn').with({
            'key'    => '/rspec_from_hiera_fqdn',
            'value'  => 'test',
            'config' => 'mandatory',
          })
        end
      end

      context 'when settings_hiera_merge set to <false>' do
        let(:params) do
          {
            :settings_hiera_merge => false,
            :desktop              => 'gnome',
          }
        end

        it { should have_gnomish__gnome__gconf_resource_count(1) }

        it do
          should contain_gnomish__gnome__gconf('from_hiera_fqdn').with({
            'key'    => '/rspec_from_hiera_fqdn',
            'value'  => 'test',
            'config' => 'mandatory',
          })
        end
      end
    end
  end

  describe 'with desktop set to valid string <mate>' do
    let(:params) { { :desktop => 'mate' } }
    it { should compile.with_all_deps }
    it { should contain_class('gnomish::mate') }
    it { should_not contain_class('gnomish::gnome') }
  end

  describe 'with packages_add set to valid array %w(rspec testing)' do
    let(:params) { { :packages_add => %w(rspec testing) } }

    %w(rspec testing).each do |package|
      it do
        should contain_package(package).with({
          'ensure' => 'present',
        })
      end
    end
  end

  describe 'with packages_remove set to valid array %w(rspec testing)' do
    let(:params) { { :packages_remove => %w(rspec testing) } }

    %w(rspec testing).each do |package|
      it do
        should contain_package(package).with({
          'ensure' => 'absent',
        })
      end
    end
  end

  describe 'variable type and content validations' do
    # set needed custom facts and variables
    let(:facts) do
      {
        #:fact => 'value',
      }
    end
    let(:mandatory_params) do
      {
        #:param => 'value',
      }
    end

    validations = {
      'array' => {
        :name    => %w(packages_add packages_remove),
        :valid   => [%w(array)],
        :invalid => ['string', { 'ha' => 'sh' }, 3, 2.42, true, false],
        :message => 'is not an Array',
      },
      'boolean' => {
        :name    => %w(applications_hiera_merge settings_hiera_merge),
        :valid   => [true, false],
        :invalid => ['true', 'false', 'string', %w(array), { 'ha' => 'sh' }, 3, 2.42, nil],
        :message => '(is not a boolean|Unknown type of boolean given)',
      },
      'hash' => {
        :name    => %w(applications settings),
        :params  => { :applications_hiera_merge => false, :settings_hiera_merge => false },
        :valid   => [], # valid hashes are to complex to block test them here. Subclasses have their own specific spec tests anyway.
        :invalid => ['string', 3, 2.42, %w(array), true, false, nil],
        :message => 'is not a Hash',
      },
      'regex desktop' => {
        :name    => %w(desktop),
        :valid   => %w(gnome mate),
        :invalid => [%w(array), { 'ha' => 'sh' }, 3, 2.42, true, false],
        :message => 'must be <gnome> or <mate> and is set to',
      },
    }

    validations.sort.each do |type, var|
      var[:name].each do |var_name|
        var[:params] = {} if var[:params].nil?
        var[:valid].each do |valid|
          context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => valid, }].reduce(:merge) }
            it { should compile }
          end
        end

        var[:invalid].each do |invalid|
          context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => invalid, }].reduce(:merge) }
            it 'should fail' do
              expect { should contain_class(subject) }.to raise_error(Puppet::Error, /#{var[:message]}/)
            end
          end
        end
      end # var[:name].each
    end # validations.sort.each
  end # describe 'variable type and content validations'
end
