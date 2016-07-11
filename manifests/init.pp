# == Class: gnomish
#
class gnomish (
  $applications             = {},
  $applications_hiera_merge = true,
  $desktop                  = 'gnome',
  $packages_add             = [],
  $packages_remove          = [],
  $settings_xml             = {},
  $settings_xml_hiera_merge = true,
) {

  # variable preparations
  if $applications_hiera_merge == true {
    $applications_real = hiera_hash(gnomish::applications, {} )
  }
  else {
    $applications_real = $applications
  }

  if $settings_xml_hiera_merge == true {
    $settings_xml_real = hiera_hash(gnomish::settings_xml, {} )
  }
  else {
    $settings_xml_real = $settings_xml
  }

  # variable validations
  validate_array(
    $packages_add,
    $packages_remove,
  )

  validate_bool(
    $applications_hiera_merge,
    $settings_xml_hiera_merge,
  )

  validate_hash(
    $applications_real,
    $settings_xml_real,
  )

  validate_re($desktop, '^(gnome|mate)$', "gnomish::desktop must be <gnome> or <mate> and is set to ${desktop}")

  # functionality
  package { $packages_add:
    ensure => present,
  }

  package { $packages_remove:
    ensure => absent,
  }

  create_resources('gnomish::application', $applications_real)

  case $desktop {
    'gnome': {
      include ::gnomish::gnome
      create_resources('gnomish::gnome::gconftool_2', $settings_xml_real)
    }
    'mate': {
      include ::gnomish::mate
      create_resources('gnomish::mate::mateconftool_2', $settings_xml_real)
    }
    default: {
      # nothing to do, have a cup of good tea
    }
  }
}
