# The `gnomish::gnome` class is used to configure application icons and settings that are valid
# for Mate desktops only. Additional you can manage the system items menu file.
#
# @param applications
#   Specify applications icons that will be passed to the gnomish::applications defined type.
#   For a full description please read on at the application defined type.
#   Hint: if you want to pass parameters from manifests, you will need to set
#   `$gnomish::gnome::applications_hiera_merge` to false.
#
# @param applications_hiera_merge
#   If set to true hiera_merge will be used to collect and concatenate applications settings
#   from all applicable hiera levels. If set to false only the most specific hiera data will be used.
#   Hint: if you want to pass parameters from manifests you will need to set it to false.
#
# @param settings_xml
#   Specify desktop settings that will be passed to the `gnomish::gnome::gconftool_2` defined type.
#   For a full description please read on at the gconftools_2 defined type.
#   Hint: if you want to pass parameters from manifests you will need to set $settings_xml_hiera_merge to false.
#
# @param settings_xml_hiera_merge
#   If set to true hiera_merge will be used to collect and concatenate desktop settings from all applicable
#   hiera levels. If set to false only the most specific hiera data will be used.
#   Hint: if you want to pass parameters from manifests you will need to set $settings_xml_hiera_merge to false.
#
# @param system_items_modify
#   If set to true it will activate the modification of the system items menu file in
#   /usr/share/gnome-main-menu/system-items.xbel. The module delivers an example for SLE11 with a typical
#   reduction useful for terminal servers.
#
# @param system_items_path
#   Specify an absolute path to the system-items.xbel file which should get managed.
#   Hint: if you want to pass parameters from manifests you will need to set $settings_xml_hiera_merge to false.
#
# @param system_items_source
#   Specify the source of the file to be copied to $system_items_path. Takes all values that are valid for the
#   source attribute of a file resource.
#
class gnomish::gnome (
  Hash                 $applications             = {},
  Boolean              $applications_hiera_merge = true,
  Hash                 $settings_xml             = {},
  Boolean              $settings_xml_hiera_merge = true,
  Boolean              $system_items_modify      = false,
  Stdlib::Absolutepath $system_items_path        = '/usr/share/gnome-main-menu/system-items.xbel',
  Stdlib::Filesource   $system_items_source      = 'puppet:///modules/gnomish/gnome/SLE11-system-items.xbel.erb',
) {
  # variable preparations
  if $applications_hiera_merge == true {
    $applications_real = hiera_hash(gnomish::gnome::applications, {})
  }
  else {
    $applications_real = $applications
  }

  if $settings_xml_hiera_merge == true {
    $settings_xml_real = hiera_hash(gnomish::gnome::settings_xml, {})
  }
  else {
    $settings_xml_real = $settings_xml
  }

  # functionality
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

  exec { 'update-desktop-database' :
    command     => '/usr/bin/update-desktop-database',
    path        => $facts['path'],
    refreshonly => true, # notified by gnomish::application file {"desktop_app_${title}"}
  }

  create_resources('gnomish::application', $applications_real)
  create_resources('gnomish::gnome::gconftool_2', $settings_xml_real)
}
