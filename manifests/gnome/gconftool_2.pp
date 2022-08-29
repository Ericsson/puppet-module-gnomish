# Defined type that is used to configure Gnome system settings utilizing `gconftool-2`.
#
# Instead of calling these defines directly, it is recommended to specify `$gnomish::settings_xml` or
# `$gnomish::gnome::settings_xml` from hiera as a hash of group resources.
# `create_resources()` will create resources out of your hash.
#
# @example Hiera Example
#   gnomish::settings_xml:
#     '/desktop/gnome/background/picture_filename':
#       value:  'wallpaper.png'
#
#   gnomish::gnome::settings_xml:
#     'set GTK theme':
#       key:    '/desktop/mate/interface/gtk_theme'
#       value:  'Theme'
#       config: 'mandatory'#
#
#   The above will set a wallpaper for mate desktops and change the GTK theme.
#
# @summary Defined type that is used to configure Gnome system settings utilizing `gconftool-2`.
#
# @param value
#   Used to pass the content of the setting you want to change.
#
# @param config
#   You can specify which configuration source should get managed. For convenient usage, it allows to use defaults
#   and mandatory as acronyms for /etc/gconf/gconf.xml.defaults and /etc/gconf/gconf.xml.mandatory. If you want to
#   specify another configuration source, please specify the complete absolute path for it.
#
# @param key
#   To specify which key you want to manage. If not explicitly set, it will use the resource title you have chosen
#   while calling the defined type. See the example above for an example of both ways to pass the key name.
#
# @param type
#   The default of auto will analyze and use the data type you have used when specifying $value. You can override
#   this by setting type to one of the other valid values of bool, int, float or string.
#
define gnomish::gnome::gconftool_2 (
  Variant[Boolean, Float, Integer, String[1]]                  $value,
  Variant[Stdlib::Absolutepath, Enum['defaults', 'mandatory']] $config = 'defaults',
  String[1]                                                    $key    = $title,
  Enum['auto', 'bool', 'int', 'float', 'string']               $type   = 'auto',
) {
  # variable preparation
  case type3x($value) {
    'boolean':         {
      $value_string = bool2str($value)
      $value_type = 'bool'
    }
    'integer': {
      $value_string = sprintf('%g', $value)
      $value_type = 'int'
    }
    'float': {
      $value_string = sprintf('%g', $value)
      $value_type = 'float'
    }
    'string': {
      if $value =~ /^(true|false)$/ {
        $value_string = $value
        $value_type = 'bool'
      }
      else {
        $value_string = $value
        $value_type = 'string'
      }
    }
    default: { fail('gnomish::gnome::gconftool_2::value is not a string.') }
  }

  if $type == 'auto' {
    $type_real = $value_type
  }
  else {
    $type_real = $type
  }

  $config_real = $config ? {
    'mandatory' => '/etc/gconf/gconf.xml.mandatory',
    'defaults'  => '/etc/gconf/gconf.xml.defaults',
    default     => $config,
  }

  # variable validation
  validate_string($value_string)
  validate_absolute_path($config_real)
  if is_string($key) == false {
    fail('gnomish::gnome::gconftool_2::key is not a string.')
  }
  validate_re($type_real, '^(bool|int|float|string)$', "gnomish::gnome::gconftool_2::type must be one of <bool>, <int>, <float>, <string> or <auto> and is set to ${type_real}") #lint:ignore:140chars

  # functionality
  exec { "gconftool-2 ${key}" :
    command => "gconftool-2 --direct --config-source xml:readwrite:${config_real} --set '${key}' --type ${type_real} '${value_string}'",
    # "2>&1" is needed to catch cases where we want to write an empty string when no value is set (yet)
    unless  => "test \"$(gconftool-2 --direct --config-source xml:readwrite:${config_real} --get ${key} 2>&1 )\" == \"${value_string}\"",
    path    => $facts['path'],
  }
}
