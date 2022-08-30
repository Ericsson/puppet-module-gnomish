# Used to configure application icons and settings that are valid for Mate desktops only.
#
# @param applications
#   Specify applications icons that will be passed to the `gnomish::applications` defined type.
#   For a full description please read on at the application defined type.
#   Hint: if you want to pass parameters from manifests, you will need to set
#   `$gnomish::mate::applications_hiera_merge` to false.
#
# @example Hiera Example
#   gnomish::mate::applications:
#     'mc':
#       ensure:           'file'
#       entry_categories: 'System;FileManager;'
#       entry_exec:       'mc'
#       entry_icon:       'mc'
#       entry_name:       'Midnight Commander'
#       entry_terminal:   false
#
#   gnomish::mate::applications:
#     'mate-network-properties':
#       ensure: 'absent'
#
#   The above will add a application icon for Midnight Commander in the file
#   /usr/share/applications/mc.desktop and remove the icon for mate-network-properties.
#
# @param applications_hiera_merge
#   If set to true hiera_merge will be used to collect and concatenate applications settings from
#   all applicable hiera levels. If set to false only the most specific hiera data will be used.
#   Hint: if you want to pass parameters from manifests you will need to set it to false.
#
# @param settings_xml
#   Specify desktop settings that will be passed to the `gnomish::mate::mateconftool_2` defined type.
#   For a full description please read on at the `mateconftools_2` defined type.
#   Hint: if you want to pass parameters from manifests you will need to set `$settings_xml_hiera_merge` to false.
#
# @param settings_xml_hiera_merge
#   If set to true hiera_merge will be used to collect and concatenate desktop settings from all
#   applicable hiera levels. If set to false only the most specific hiera data will be used.
#   Hint: if you want to pass parameters from manifests you will need to set `$settings_xml_hiera_merge` to false.
#
class gnomish::mate (
  Hash    $applications             = {},
  Boolean $applications_hiera_merge = true,
  Hash    $settings_xml             = {},
  Boolean $settings_xml_hiera_merge = true,
) {
  # variable preparations
  if $applications_hiera_merge == true {
    $applications_real = hiera_hash(gnomish::mate::applications, {})
  }
  else {
    $applications_real = $applications
  }

  if $settings_xml_hiera_merge == true {
    $settings_xml_real = hiera_hash(gnomish::mate::settings_xml, {})
  }
  else {
    $settings_xml_real = $settings_xml
  }

  # functionality
  exec { 'update-desktop-database' :
    command     => '/usr/bin/update-desktop-database',
    path        => $facts['path'],
    refreshonly => true, # notified by gnomish::application file {"desktop_app_${title}"}
  }

  create_resources('gnomish::application', $applications_real)
  create_resources('gnomish::mate::mateconftool_2', $settings_xml_real)
}
