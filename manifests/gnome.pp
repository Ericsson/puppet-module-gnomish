# == Class: gnomish::gnome
#
class gnomish::gnome (
  $applications             = {},
  $applications_hiera_merge = true,
  $gconf_name               = undef,
  $settings                 = {},
  $settings_hiera_merge     = true,
  $system_items_modify      = false,
  $system_items_path        = '/usr/share/gnome-main-menu/system-items.xbel',
  $system_items_source      = 'puppet:///modules/gnomish/gnome/SLE11-system-items.xbel.erb',
  $wallpaper_path           = undef,
  $wallpaper_source         = undef,
) {

  # variable preparations
  if $applications_hiera_merge == true {
    $applications_real = hiera_hash(gnomish::gnome::applications, {} )
  }
  else {
    $applications_real = $applications
  }

  if $settings_hiera_merge == true {
    $settings_real = hiera_hash(gnomish::gnome::settings, {} )
  }
  else {
    $settings_real = $settings
  }

  # variable validations
  validate_absolute_path($system_items_path)

  if $wallpaper_path != undef {
    validate_absolute_path($wallpaper_path)
  }

  validate_bool(
    $system_items_modify,
    $applications_hiera_merge,
    $settings_hiera_merge,
  )

  validate_hash(
    $applications_real,
    $settings_real,
  )

  validate_string(
    $gconf_name,
    $system_items_source,
    $wallpaper_source,
  )

  # conditional checks
  if $wallpaper_source != undef and $wallpaper_path == undef {
    fail('gnomish::gnome::settings::wallpaper_path is needed but undefiend. Please define a valid path.')
  }

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
  create_resources('gnomish::gnome::gconf', $settings_real)

  if $wallpaper_path != undef {
    gnomish::gnome::gconf { 'set wallpaper':
      key    => '/desktop/gnome/background/picture_filename',
      value  => $wallpaper_path,
      type   => 'string',
      config => 'defaults',
    }
  }

  if $wallpaper_source != undef {
    file { 'wallpaper':
      ensure => file,
      path   => $wallpaper_path,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => $wallpaper_source,
      before => Gnomish::Gnome::Gconf['set wallpaper'],
    }
  }
}
