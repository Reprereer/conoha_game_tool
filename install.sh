#!/bin/bash

readonly server_service_name=minecraft-forge-server
readonly server_directory=/opt/minecraft_forge_server
readonly profile_filepath=/etc/minecraft.d/profile.conf


function init() {
	if ! dpkg -l | grep -q "libxml2-utils"; then
		echo "Installing library ..."
		apt-get -qq update && apt-get -qq install libxml2-utils 
	fi
}

function startServer() {
	echo "Starting Minecraft Forge Server ..."
	if ! systemctl start ${server_service_name}; then
		echo "ERROR: Failed to start Minecraft Forge Server."
	fi
}

function stopServer() {
	service_status=$(systemctl is-active ${server_service_name})
	if [ "$service_status" = "active" ]; then
		echo "Stopping Minecraft Forge Server ..."
		if ! systemctl stop ${server_service_name}; then
        	echo "ERROR: Failed to stop Minecraft Forge Server."
			exit 1
		fi
	fi
}


function downloadFile() {
	echo "Downloading Minecraft Forge Server ..."
 	url="https://maven.minecraftforge.net/net/minecraftforge/forge/1.19.2-43.2.0/forge-1.19.2-43.2.0-installer.jar"
 	temp_jarpath="/tmp/$(basename ${url})"
 
    if ! wget -q -O ${temp_jarpath} ${url}; then
        echo "ERROR: Cannot download file: ${url}"
        exit 1
    fi
}

function installServer() {
	local version=$1
	local base_version=$(echo $version | sed 's/\([0-9]*\.[0-9]*\)\..*/\1/')

	echo "Installing Minecraft Forge Server ..."
	sudo -u minecraft java -jar ${temp_jarpath} --installServer ${server_directory} | grep -E "^[A-Z][a-z]+ing" > /dev/null && \
		sed -i "s/^MINECRAFT_VERSION=.*/MINECRAFT_VERSION=${version}/" "${profile_filepath}" && \
		sed -i "s/^MINECRAFT_EDITION=.*/MINECRAFT_EDITION=forge-${base_version}/" "${profile_filepath}" && \
		echo "Installation has completed."
}


function cleanup() {
    rm ${temp_jarpath}
}

function main() {
    if [ ${#} -eq 1 ]; then
		version=$1

		version_pattern="^[0-9]+(\.[0-9]+)+$"
		if [[ !("$version" =~ $version_pattern) ]]; then
			echo "ERROR: Invalid version format: ${version}"
			exit 1
		fi

		init
		downloadFile
		stopServer
		installServer ${version}
		startServer
		cleanup
    else
		echo "Usage: install.sh"
        exit 1
    fi
}

main "$@"
