# Define version type for asdf
define asdf::version (
  Variant[String[1], Array[String[1], 1]] $versions,
  Enum['present', 'absent'] $ensure = 'present',
  String[1] $plugin = $title,
  Variant[String[1], Undef] $global = undef
) {
  $homedir = $facts['homedirs'][$asdf::owner]

  Exec {
    environment => ["HOME=${homedir}"],
    user        => $asdf::owner,
    group       => $asdf::group
  }

  $version_array = any2array($versions)

  if $global {
    $global_version = $global
  } else {
    $global_version = sort($version_array)[-1]
  }

  $bin = "${asdf::path}/bin/asdf"

  $version_array.each |String $version| {
    if $ensure == 'present' {
      exec { "${bin} install ${plugin} ${version}":
        unless  => "${bin} list ${plugin} | grep ${version}",
        timeout => 0,
        require => Asdf::Plugin[$plugin]
      }
    } else {
      exec { "${bin} uninstall ${plugin} ${version}":
        onlyif => "${bin} list ${plugin} | grep ${version}",
      }
    }
  }

  exec { "${bin} global ${plugin} ${global_version}":
    unless  => "${bin} current ${plugin} | grep ${global_version}",
    require => Exec["${bin} install ${plugin} ${global_version}"]
  }
}
