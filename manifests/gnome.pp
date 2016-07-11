# == Class: gnomish::gnome
#
class gnomish::gnome (
  $applications             = {},
  $applications_hiera_merge = true,
  $gconf_name               = undef,
  $settings_xml             = {},
  $settings_xml_hiera_merge = true,
  $system_items_modify      = false,
  $system_items_path        = '/usr/share/gnome-main-menu/system-items.xbel',
  $system_items_source      = 'puppet:///modules/gnomish/gnome/SLE11-system-items.xbel.erb',
) {

  # variable preparations
  if $applications_hiera_merge == true {
    $applications_real = hiera_hash(gnomish::gnome::applications, {} )
  }
  else {
    $applications_real = $applications
  }

  if $settings_xml_hiera_merge == true {
    $settings_xml_real = hiera_hash(gnomish::gnome::settings_xml, {} )
  }
  else {
    $settings_xml_real = $settings_xml
  }

  # variable validations
  validate_absolute_path($system_items_path)

  validate_bool(
    $system_items_modify,
    $applications_hiera_merge,
    $settings_xml_hiera_merge,
  )

  validate_hash(
    $applications_real,
    $settings_xml_real,
  )

  validate_string(
    $gconf_name,
    $system_items_source,
  )

  # functionality
  if $gconf_name != undef {
    file_line { 'set_gconf_name':
      ensure => present,
      path   => '/etc/gconf/2/path',
      line   => "xml:readwrite:${gconf_name}",
      match  => '^xml:readwrite:',
    }
  }

  if $system_items_modify == true {
    file { 'modified system items' :
      ensure => file,
      path   => $system_items_path,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => $system_items_source,
    }
  }

  create_resources('gnomish::application', $applications_real)
  create_resources('gnomish::gnome::gconftool_2', $settings_xml_real)
}
