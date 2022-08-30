# The `gnomish::application` define is used to manage application icons on both desktops, Gnome and Mate.
# The minimum set of entries for application icons (Name, Icon, Exec, Categories, Type and Terminal) have
# to be set with the corresponding parameters. All others entries can be managed as an array of free text
# lines via the $entry_lines parameter. The module will ensure that there are no duplicate entries and fail
# if found one.
#
# When applications get added or removed, it will call update-desktop-database. This will update the cache
# database of MIME types handled by desktop files.
#
# Instead of calling this define directly, it is recommended to specify `$gnomish::applications`,
# `$gnomish::gnome::applications` or `$gnomish::mate::applications` from hiera as a hash of group resources.
# `create_resources()` will create resources out of your hash.
#
# @example Hiera Example
#   gnomish::applications:
#     'mc':
#       ensure:           'file'
#       entry_categories: 'System;FileManager;'
#       entry_exec:       'mc'
#       entry_icon:       'mc'
#       entry_name:       'Midnight Commander'
#       entry_terminal:   false
#
#   gnomish::gnome::applications:
#     'gnome-network-properties':
#       ensure: 'absent'
#
#   gnomish::mate::applications:
#     'mate-network-properties':
#       ensure: 'absent'
#
# The above will add a application icon for Midnight Commander in the file /usr/share/applications/mc.desktop
# on both desktops. Only on Gnome it will remove the icon for gnome-network-properties and only on Mate the
# equivalent called mate-network-properties.
#
# @summary
#   The `gnomish::application` definition is used to manage application icons on both desktops, Gnome and Mate.
#
# @param ensure
#   This setting can be used to add or remove application icons. Valid values are file and absent. Use the
#   default of file to add/manage them or set it to absent to remove them. If set to absent
#   $entry_categories, $entry_exec and $entry_icon become unused and optional.
#
# @param path
#   Specify an absolute path to the desktop file containing the application icon. If not explicitly set,
#   '/usr/share/applications/' plus the resource title you have chosen while calling the defined type
#   plus '.desktop' will be used.
#
# @param entry_categories
#   Specify the application icons Categories entry.
#   Hint: becomes optional and unused when $ensure is set to absent.
#
# @param entry_exec
#   Specify the application icons Exec entry.
#   Hint: becomes optional and unused when $ensure is set to absent.
#
# @param entry_icon
#   Specify the application icons Icon entry.
#   Hint: becomes optional and unused when $ensure is set to absent.
#
# @param entry_lines
#   You can add additional and free text entries line by line with this array. If your input includes one
#   of the other named entries the defined type will fail to avoid double entries to appear.
#
# @param entry_name
#   Specify the application icons Name entry. If not explicitly set, the resource title you have chosen
#   while calling the defined type will be used.
#
# @param entry_terminal
#   Specify the application icons Terminal entry. Valid values are false and true.
#
# @param entry_type
#   Specify the application icons Type entry.
#
# @param entry_mimetype
#   Specify the mime types supported by the application.
#
define gnomish::application (
  # desktop file resource attributes:
  Enum['absent', 'file']    $ensure           = 'file',
  Stdlib::Absolutepath      $path             = "/usr/share/applications/${name}.desktop",
  # desktop file metadata:
  Optional[String[1]]       $entry_categories = undef,
  Optional[String[1]]       $entry_exec       = undef,
  Optional[String[1]]       $entry_icon       = undef,
  Array                     $entry_lines      = [],
  Optional[String[1]]       $entry_name       = $title,
  Boolean                   $entry_terminal   = false,
  String[1]                 $entry_type       = 'Application',
  Optional[Variant[Array, String[1]]] $entry_mimetype   = undef,
) {
  # validate mandatory application settings only when needed
  if $ensure == 'file' {
    case type3x($entry_mimetype) {
      []:       { $entry_mimetype_string = undef }
      'string': { $entry_mimetype_string = $entry_mimetype }
      'array':  { $entry_mimetype_string = join($entry_mimetype, ';') }
      default:  { fail('gnomish::application::entry_mimetype is not a string nor an array.') }
    }

    # check if mandatory metadata is given
    if $entry_categories == undef or $entry_categories == '' {
      fail('when gnomish::application::ensure is set to <file> entry_categories, entry_exec, entry_icon, entry_name and entry_type needs to have valid values.') #lint:ignore:140chars
    }
    if $entry_exec == undef or $entry_exec == '' {
      fail('when gnomish::application::ensure is set to <file> entry_categories, entry_exec, entry_icon, entry_name and entry_type needs to have valid values.') #lint:ignore:140chars
    }
    if $entry_icon == undef or $entry_icon == '' {
      fail('when gnomish::application::ensure is set to <file> entry_categories, entry_exec, entry_icon, entry_name and entry_type needs to have valid values.') #lint:ignore:140chars
    }
    if $entry_name == undef or $entry_name == '' {
      fail('when gnomish::application::ensure is set to <file> entry_categories, entry_exec, entry_icon, entry_name and entry_type needs to have valid values.') #lint:ignore:140chars
    }
    if $entry_type == undef or $entry_type == '' {
      fail('when gnomish::application::ensure is set to <file> entry_categories, entry_exec, entry_icon, entry_name and entry_type needs to have valid values.') #lint:ignore:140chars
    }
  }

  # functionality
  # ensure that no basic settings sneaked in with $entry_lines to avoid duplicates
  if size($entry_lines) != size(reject($entry_lines, '^(?i:Name|Icon|Exec|Categories|Type|Terminal)=.*')) {
    fail('gnomish::application::entry_lines does contain one of the basic settings. Please use the specific $entry_* parameter instead.')
  }

  if $ensure == 'file' {
    $_categories = ["Categories=${entry_categories}"]
    $_exec       = ["Exec=${entry_exec}"]
    $_icon       = ["Icon=${entry_icon}"]
    $_name       = ["Name=${entry_name}"]
    $_terminal   = ["Terminal=${entry_terminal}"]
    $_type       = ["Type=${entry_type}"]
    $_mimetype   = $entry_mimetype_string ? {
      undef   => [],
      default => ["MimeType=${entry_mimetype_string}"],
    }
    $entry_lines_real = union($_categories, $_exec, $_icon, $_name, $_terminal, $_type, $_mimetype, $entry_lines)
  }
  else {
    $entry_lines_real = []
  }

  file { "desktop_app_${title}" :
    ensure  => $ensure,
    path    => $path,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Exec['update-desktop-database'],
    content => template('gnomish/application.erb'),
  }
}
