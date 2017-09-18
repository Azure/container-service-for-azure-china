#reference https://gist.github.com/micw/e80d739c6099078ce0f3
#!/usr/bin/env bash

set -e
set -o pipefail

plugin_repo_url="https://mirrors.tuna.tsinghua.edu.cn/jenkins/plugins"
plugin_dir="/var/lib/jenkins/plugins"
include_optionals=false

showUsage() {
	echo "\
$0 [OPTIONS] plugin@version ...

OPTIONS:
-d,--dir DIR    Install dir. Default is $plugin_dir
-a,--all        Install also optional dependencies
-u,--url URL    Change to plugin repo URL. Default is $plugin_repo_url
-h,--help       Print this help"
}

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -u|--url)
    plugin_repo_url="$2"
    shift
    ;;
    -d|--dir)
    plugin_dir="$2"
    shift
    ;;
    -a|--all)
    include_optionals=true
    ;;
    -h|--help)
    showUsage
    exit
    ;;
    -*|--*)
    echo "Unknown Option"
    exit 1
    ;;
    *)
    break
    ;;
esac
shift
done

download_plugin() {
  url="${plugin_repo_url}/${1}/${2}/${1}.hpi"
  echo "Downloading: $1@$2"
  curl -L --silent --output "${plugin_dir}/${1}.hpi" "$url"
}

get_dependencies() {
  hpi_file=$1
  manifest="$(unzip -p "${hpi_file}" META-INF/MANIFEST.MF | tr -d '\r' | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n //g' )"
  if line=$( echo "$manifest" | grep -e "^Plugin-Dependencies" ); then
    deps=$( echo "$line" | awk '{ print $2 }' | tr ',' '\n' )
    if ! $include_optionals; then
      deps=$( echo "$deps" | grep -v "resolution:=optional" )
    fi
    sed 's/;.*$//' <<< "$deps"
  else
    echo ""
  fi
}

vercomp () {
    if [[ "$1" == "$2" ]]
    then
        echo 0
        return
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            echo 1
            return
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            echo -1
            return
        fi
    done
    echo 0
}

installed_plugins=()

install_plugin() {
  plugin_id="$1"
  plugin_version="$2"

  if grep -q "$plugin_id" <<< "$installed_plugins[*]"; then
  	return 0
  fi

  dest="${plugin_dir}/${1}.hpi"

  if [ -f "$dest" ]; then
  	installed_version=$(unzip -p "${dest}" META-INF/MANIFEST.MF | tr -d '\r' | grep "^Plugin-Version" | awk '{ print $2 }' | tr -d '\n' )

  	if [ "$(vercomp "$installed_version" "$plugin_version")" -lt "0" ]; then
  		echo "Updating $plugin_id from $installed_version to $plugin_version"
  		download_plugin "$plugin_id" "$plugin_version" "$plugin_dir"
  	fi
  else
    download_plugin "$plugin_id" "$plugin_version" "$plugin_dir"
  fi

  installed_plugins+=("$plugin_id")

  deps="$(get_dependencies "$dest")"
	echo "$deps" | tr ' ' '\n' |
	while IFS=: read -r plugin version; do
	  install_plugin "$plugin" "$version"
	done
}

for plugin in "$@"; do
  IFS="@" read -r plugin version <<< "$plugin"
  #escape comments
  if [[ "$plugin" =~ ^# ]]; then
     continue
  fi

  #install the plugin
  install_plugin "$plugin" "$version"
done

echo "Done"

