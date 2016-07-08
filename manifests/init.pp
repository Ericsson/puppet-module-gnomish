# == Class: gnomish
#
class gnomish (
  $applications             = {},
  $applications_hiera_merge = true,
  $desktop                  = 'gnome',
  $packages_add             = [],
  $packages_remove          = [],
  $settings                 = {},
  $settings_hiera_merge     = true,
) {

  # variable preparations
  if $applications_hiera_merge == true {
    $applications_real = hiera_hash(gnomish::applications, {} )
  }
  else {
    $applications_real = $applications
  }

  if $settings_hiera_merge == true {
    $settings_real = hiera_hash(gnomish::settings, {} )
  }
  else {
    $settings_real = $settings
  }

  # variable validations
  validate_array(
    $packages_add,
    $packages_remove,
  )

  validate_bool(
    $applications_hiera_merge,
    $settings_hiera_merge,
  )

  validate_hash(
    $applications_real,
    $settings_real,
  )

  validate_re($desktop, '^gnome$', "gnomish::gnome must be <gnome> or <mate> and is set to ${desktop}")

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
      create_resources('gnomish::gnome::gconf', $settings_real)
    }
    default: {
      # nothing to do, have a cup of good tea
    }
  }
}
