# The `gnomish` class is used to configure application icons and settings that are valid for both desktops.
# Besides that, you can also manage wallpaper, packages, and which file to be used to save user settings.
#
# @param applications
#   Specify applications icons that will be passed to the `gnomish::applications` defined type.
#   For a full description please read on at the application defined type.
#   Hint: if you want to pass parameters from manifests, you will need to set `$gnomish::applications_hiera_merge` to false.
#
# @param applications_hiera_merge
#   If set to true hiera_merge will be used to collect and concatenate applications settings from all applicable hiera levels.
#   If set to false only the most specific hiera data will be used.
#   Hint: if you want to pass parameters from manifests you will need to set it to false.
#
# @param desktop
#   Used to decide which desktop should be configured. Valid values are gnome and mate.
#   Depending on this setting the module will include the subclass `gnomish::gnome` or `gnomish::mate`.
#
# @param gconf_name
#   This setting allows you to define system-wide which file should be used to save user settings. With this you can
#   completely separate the settings between desktops and even OS families to avoid spillover effects.
#
# @param packages_add
#   Name of package(s) you want to add. Use to add packages that are needed. Useful to add desktop specific packages.
#
# @param packages_remove
#   Name of package(s) you want to remove. Use to remove packages that are unwanted on a terminal server for example.
#
# @param settings_xml
#   Specify desktop settings that will be passed to the `gnomish::gnome::gconftool_2` or `gnomish::mate::mateconftool_2`
#   defined types, depending on the value of `$gnomish::desktop`. For a full description please read on at the
#   gconftool_2 or mateconftools_2 defined types.
#   Hint: if you want to pass parameters from manifests you will need to set `$settings_xml_hiera_merge` to false.
#
# @param settings_xml_hiera_merge
#   If set to true hiera_merge will be used to collect and concatenate desktop settings from all applicable hiera levels.
#   If set to false only the most specific hiera data will be used.
#   Hint: if you want to pass parameters from manifests you will need to set $settings_xml_hiera_merge to false.
#
# @param wallpaper_path
#   Specify an absolute path to an image file that should be used as system default background.
#
# @param wallpaper_source
#   When set, the module will copy the file from the given source to the path defined in `$gnomish::wallpaper_path`
#   (which obviously become mandatory then). Takes all values that are valid for the source attribute of a file resource.
#
class gnomish (
  Hash                                   $applications             = {},
  Boolean                                $applications_hiera_merge = true,
  Enum['gnome', 'mate']                  $desktop                  = 'gnome',
  Optional[String[1]]                    $gconf_name               = undef,
  Array                                  $packages_add             = [],
  Array                                  $packages_remove          = [],
  Hash                                   $settings_xml             = {},
  Boolean                                $settings_xml_hiera_merge = true,
  Optional[Stdlib::Absolutepath]         $wallpaper_path           = undef,
  Optional[Optional[Stdlib::Filesource]] $wallpaper_source         = undef,
) {
  # variable preparations
  $conftool = $desktop ? {
    'mate'  => 'mateconftool_2',
    default => 'gconftool_2',
  }

  if $wallpaper_path != undef {
    $settings_xml_wallpaper = {
      'set wallpaper' => {
        key     => "/desktop/${desktop}/background/picture_filename",
        value   => $wallpaper_path,
      },
    }
  }
  else {
    $settings_xml_wallpaper = {}
  }

  if $applications_hiera_merge == true {
    $applications_real = hiera_hash(gnomish::applications, {})
  }
  else {
    $applications_real = $applications
  }

  if $settings_xml_hiera_merge == true {
    $settings_xml_hiera = hiera_hash(gnomish::settings_xml, {})
  }
  else {
    $settings_xml_hiera = $settings_xml
  }

  # conditional checks
  if $wallpaper_source != undef and $wallpaper_path == undef {
    fail('gnomish::wallpaper_path is needed but undefiend. Please define a valid path.')
  }

  # functionality
  package { $packages_add:
    ensure => present,
  }

  package { $packages_remove:
    ensure => absent,
  }

  include "::gnomish::${desktop}"
  create_resources('gnomish::application', $applications_real)

  $settings_xml_real = merge($settings_xml_wallpaper,  $settings_xml_hiera)
  create_resources("gnomish::${desktop}::${conftool}", $settings_xml_real)

  if $gconf_name != undef {
    file_line { 'set_gconf_name':
      ensure => present,
      path   => '/etc/gconf/2/path',
      line   => "xml:readwrite:${gconf_name}",
      match  => '^xml:readwrite:',
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
      before => "Gnomish::${(capitalize($desktop))}::${(capitalize($conftool))}[set wallpaper]",
    }
  }
}
