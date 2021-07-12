require 'spec_helper'
describe 'gnomish::application' do
  mandatory_params = {
    entry_categories: 'category',
    entry_exec:       'exec',
    entry_icon:       'icon',
  }
  let(:title) { 'rspec-title' }
  let(:params) { mandatory_params }
  let(:pre_condition) do
    "exec { 'update-desktop-database':
       command     => '/usr/bin/update-desktop-database',
       path        => $::path,
       refreshonly => true,
     }"
  end

  describe 'with defaults for all parameters' do
    let(:params) { {} }

    it 'fail' do
      expect { is_expected.to contain_class(:subject) }.to raise_error(
        Puppet::Error, %r{(when gnomish::application::ensure is set to <file> entry_categories, entry_exec, entry_icon, entry_name and entry_type needs to have valid values)}
      )
    end
  end

  describe 'with ensure set to valid string <absent>' do
    let(:params) { { ensure: 'absent' } }

    it do
      is_expected.to contain_file('desktop_app_rspec-title').with(
        {
          'ensure' => 'absent',
          'path'   => '/usr/share/applications/rspec-title.desktop',
          'notify' => 'Exec[update-desktop-database]',
        },
      )
    end
  end

  describe 'with path set to valid string </rspec/testing.desktop>' do
    let(:params) { { path: '/rspec/testing.desktop' } }

    it 'fail' do
      expect { is_expected.to contain_class(:subject) }.to raise_error(
        Puppet::Error, %r{(when gnomish::application::ensure is set to <file> entry_categories, entry_exec, entry_icon, entry_name and entry_type needs to have valid values)}
      )
    end
  end

  describe 'with path set to valid string </rspec/testing.desktop> and ensure set to <absent>' do
    let(:params) do
      mandatory_params.merge(
        {
          path:   '/rspec/testing.desktop',
          ensure: 'absent',
        },
      )
    end

    it do
      is_expected.to contain_file('desktop_app_rspec-title').with(
        {
          'ensure' => 'absent',
          'path'   => '/rspec/testing.desktop',
          'notify' => 'Exec[update-desktop-database]',
        },
      )
    end
  end

  ['categories', 'exec', 'icon', 'name', 'type'].each do |param|
    describe "with entry_#{param} set to valid string <example>" do
      let(:params) { { "entry_#{param}": 'example' } }

      it 'fail' do
        expect { is_expected.to contain_class(:subject) }.to raise_error(
          Puppet::Error, %r{(when gnomish::application::ensure is set to <file> entry_categories, entry_exec, entry_icon, entry_name and entry_type needs to have valid values)}
        )
      end
    end
  end

  context 'with entry_terminal set to valid boolean <true>' do
    let(:params) { { entry_terminal: true } }

    it 'fail' do
      expect { is_expected.to contain_class(:subject) }.to raise_error(
        Puppet::Error, %r{(when gnomish::application::ensure is set to <file> entry_categories, entry_exec, entry_icon, entry_name and entry_type needs to have valid values)}
      )
    end
  end

  describe 'with entry_lines set to valid array %w(Comment=rspec)' do
    let(:params) { { entry_lines: ['Comment=rspec'] } }

    it 'fail' do
      expect { is_expected.to contain_class(:subject) }.to raise_error(
        Puppet::Error, %r{(when gnomish::application::ensure is set to <file> entry_categories, entry_exec, entry_icon, entry_name and entry_type needs to have valid values)}
      )
    end
  end

  describe 'with minimum parameters set when ensure is set to <file>' do
    let(:params) { mandatory_params }

    content_minimum = <<-END.gsub(%r{^\s+\|}, '')
      |[Desktop Entry]
      |Categories=category
      |Exec=exec
      |Icon=icon
      |Name=rspec-title
      |Terminal=false
      |Type=Application
    END

    it do
      is_expected.to contain_file('desktop_app_rspec-title').with(
        {
          'ensure' => 'file',
          'path'   => '/usr/share/applications/rspec-title.desktop',
          'owner'   => 'root',
          'group'   => 'root',
          'mode'    => '0644',
          'notify'  => 'Exec[update-desktop-database]',
          'content' => content_minimum,
        },
      )
    end

    ['categories', 'exec', 'icon', 'name', 'type'].each do |param|
      context "when entry_#{param} is set to valid string <example>" do
        let(:params) { mandatory_params.merge({ "entry_#{param}": 'example' }) }

        it { is_expected.to contain_file('desktop_app_rspec-title').with_content(%r{^#{param.capitalize}=example$}) }
      end
    end

    context 'when entry_terminal is set to valid boolean <true>' do
      let(:params) { mandatory_params.merge({ entry_terminal: true }) }

      it { is_expected.to contain_file('desktop_app_rspec-title').with_content(%r{^Terminal=true$}) }
    end

    context 'when entry_mimetype is set to valid string <application/spec.test>' do
      let(:params) { mandatory_params.merge({ entry_mimetype: 'application/spec.test' }) }

      it { is_expected.to contain_file('desktop_app_rspec-title').with_content(%r{^MimeType=application\/spec.test$}) }
    end

    context 'when entry_mimetype is set to valid array [ <application/spec.test>, <application/rspec.test> ]' do
      let(:params) { mandatory_params.merge({ entry_mimetype: ['application/spec.test', 'application/rspec.test'] }) }

      it { is_expected.to contain_file('desktop_app_rspec-title').with_content(%r{^MimeType=application\/spec.test;application\/rspec.test$}) }
    end

    context 'when entry_lines is set to valid array %w(Comment=example1 Encoding=UTF-8)' do
      let(:params) { mandatory_params.merge({ entry_lines: ['Comment=comment', 'Test=test'] }) }

      content_entry_lines = <<-END.gsub(%r{^\s+\|}, '')
        |[Desktop Entry]
        |Categories=category
        |Comment=comment
        |Exec=exec
        |Icon=icon
        |Name=rspec-title
        |Terminal=false
        |Test=test
        |Type=Application
      END

      it { is_expected.to contain_file('desktop_app_rspec-title').with_content(content_entry_lines) }
    end

    ['Name', 'Icon', 'Exec', 'Categories', 'Type', 'Terminal'].each do |setting|
      context "when entry_lines also contains the basic setting #{setting}" do
        let(:params) { mandatory_params.merge({ entry_lines: ["#{setting}=something"] }) }

        it 'fail' do
          expect { is_expected.to contain_class(:subject) }.to raise_error(
            Puppet::Error, %r{gnomish::application::entry_lines does contain one of the basic settings\. Please use the specific \$entry_\* parameter instead}
          )
        end
      end
    end
  end

  describe 'variable type and content validations' do
    validations = {
      'absolute_path' => {
        name:    ['path'],
        valid:   ['/absolute/filepath', '/absolute/directory/'],
        invalid: ['string', ['array'], { 'ha' => 'sh' }, 3, 2.42, true, false, nil],
        message: 'is not an absolute path',
      },
      'array' => {
        name:    ['entry_lines'],
        valid:   [['array']],
        invalid: ['string', { 'ha' => 'sh' }, 3, 2.42, true, false],
        message: 'is not an Array',
      },
      'boolean' => {
        name:    ['entry_terminal'],
        valid:   [true, false],
        invalid: ['true', 'false', 'string', ['array'], { 'ha' => 'sh' }, 3, 2.42, nil],
        message: '(is not a boolean|Unknown type of boolean given)',
      },
      'string / array' => {
        name:    ['entry_mimetype'],
        valid:   ['string', ['array']],
        invalid: [{ 'ha' => 'sh' }, 3, 2.42, true, false],
        message: 'is not a string nor an array',
      },
      'string' => {
        name:    ['entry_categories', 'entry_exec', 'entry_icon', 'entry_name', 'entry_type'],
        valid:   ['string'],
        invalid: [['array'], { 'ha' => 'sh' }, 3, 2.42, true, false],
        message: 'is not a string',
      },
      'regex ensure' => {
        name:    ['ensure'],
        valid:   ['absent', 'file'],
        invalid: ['string', ['array'], { 'ha' => 'sh' }, 3, 2.42, true, false],
        message: 'gnomish::application::ensure must be <file> or <absent> and is set to',
      },
    }

    validations.sort.each do |type, var|
      var[:name].each do |var_name|
        var[:params] = {} if var[:params].nil?
        var[:valid].each do |valid|
          context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
            let(:params) { [mandatory_params, var[:params], { "#{var_name}": valid, }].reduce(:merge) }

            it { is_expected.to compile }
          end
        end

        var[:invalid].each do |invalid|
          context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { [mandatory_params, var[:params], { "#{var_name}": invalid, }].reduce(:merge) }

            it 'fail' do
              expect { is_expected.to contain_class(:subject) }.to raise_error(Puppet::Error, %r{#{var[:message]}})
            end
          end
        end
      end # var[:name].each
    end # validations.sort.each
  end # describe 'variable type and content validations'
end
