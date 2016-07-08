define gnomish::gnome::gconf (
  $value,
  $config = 'defaults',
  $key    = $name,
  $type   = 'auto',
) {

  # variable preparation
  if $type == 'auto' {
    $type_real = type3x($value) ? {
      'boolean' => 'bool',
      'integer' => 'int',
      'float'   => 'float',
      default   => 'string',
    }
  }
  else {
    $type_real = $type
  }

  $config_real = $config ? {
    'mandatory' => '/etc/gconf/gconf.xml.mandatory',
    'defaults'  => '/etc/gconf/gconf.xml.defaults',
    default     => $config,
  }

  $value_string = "${value}" # lint:ignore:only_variable_string

  # variable validation
  validate_string($value_string)
  validate_absolute_path($config_real)
  validate_string($key)
  validate_re($type_real, '^(bool|int|float|string)', "gnomish::gnome::gconf::type must be one of <bool>, <int>, <float>, <string> or <auto> and is set to ${type_real}")

  # functionality
  exec { "gconftool-2 ${key}" :
    command => "gconftool-2 --direct --config-source xml:readwrite:${config_real} --type ${type_real} --set '${key}' '${value_string}'",
    unless  => "test \"$(gconftool-2 --get ${key})\" == \"${value_string}\"",
#   test is faster than grep
#    unless  => "gconftool-2 --direct --config-source xml:readonly:${config_real} --get ${key} | grep '^${value_string}$'",
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
  }
}
