#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/hookdeck/hookdeck-cli"
TOOL_NAME="hookdeck"
TOOL_TEST="hookdeck version"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

# compare_versions compares two version strings (given as arguments). It prints
# -1, 0, or 1 if the first version is lower than, equivalent to, or higher than
# the second version.
compare_versions() {
	if [ "$1" = "$2" ]; then
		echo 0
		return
	fi

	lower=$( (
		echo "$1"
		echo "$2"
	) | sort_versions | head -n 1)
	[ "$lower" = "$1" ] && echo -1 || echo 1
}

list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/.*' |
		cut -d/ -f3- |
		grep '^v' |
		sed 's/^v//' |
		grep -v '0.34' # v0.34 was a mistag of v0.3.4.
}

list_all_versions() {
	list_github_tags
}

# The Hookdeck CLI has grown support for additional architectures over time:
#
# +--------------+--------------------------+------------------+
# |              |          Linux           |      Darwin      |
# +   Versions   +--------------------------+------------------+
# | (inclusive)  | x86_64 | AArch64 | ARMv6 | x86_64 | AArch64 |
# +--------------+--------+---------+-------+--------+---------+
# | 0.1–0.4*     | yes    |         |       | yes    |         |
# +--------------+--------+---------+-------+--------+---------+
# | 0.4.1–0.5*   | yes    |         |       | yes    | yes     |
# +--------------+--------+---------+-------+--------+---------+
# | 0.5.1–0.6*   | yes    |         | yes   | yes    | yes     |
# +--------------+--------+---------+-------+--------+---------+
# | 0.6.2**      | yes    |         | yes   | yes    | yes     |
# +--------------+--------+---------+-------+--------+---------+
# | 0.6.3–0.6.4  | yes    |         | yes   | yes    | yes     |
# +--------------+--------+---------+-------+--------+---------+
# | 0.6.5        | yes    | yes     | yes   | yes    | yes     |
# +--------------+--------+---------+-------+--------+---------+
# | 0.6.6        | yes    | yes     |       | yes    | yes     |
# +--------------+--------+---------+-------+--------+---------+
# | 0.6.7–       | yes    | yes     | yes   | yes    | yes     |
# +--------------+--------+---------+-------+--------+---------+
#
# Release archives are consistently named
#
#     ${TOOL_NAME}_${version}_${platform}_${arch}.tar.gz
#
# E.g.,
#
#     hookdeck_0.6.7_linux_amd64.tar.gz
#
# - For release versions not denoted by an asterisk,
#   - ${platform} is one of “linux” or “darwin”, and
#   - ${arch} is one of “amd64”, “arm64”, or “armv6”.
# - For release versions denoted by one asterisk,
#   - ${platform} is one of “linux” or “mac-os”, and
#   - ${arch} is one of “x86_64”, “arm64”, or “armv6”.
# - For release versions denoted by two asterisks,
#   - ${platform} is one of “linux” or “mac-os”;
#   - for “linux”, ${arch} is one of “amd64”, or “armv6”, and
#   - for “mac-os”, ${arch} is one of “x86_64”, or “arm64”.
#
# We expect to be able to use Darwin x86_64 binaries on Darwin AArch64 thanks
# to Rosetta 2. And we expect to be able to use Linux ARMv6 binaries on Linux
# AArch64. Otherwise, the host platform and architecture must match the release
# artifact.
#
# We completely ignore Windows, for which i386 and x86_64 builds are
# consistently available, but which is not supported by asdf.
download_release() {
	local version filename url
	local version="$1"
	local filename="$2"

	local platform="$(uname -s | tr '[:upper:]' '[:lower:]')"
	local detected_arch="$(uname -m)"
	local selected_arch=""

	# Broad platform/arch detection. We'll handle version-specific stuff
	# afterward so we can give more specific error messages.
	case "$platform" in
	linux)
		case "$detected_arch" in
		x86_64) selected_arch="amd64" ;;
		aarch64) selected_arch="arm64" ;;
		armv6l | armv7l) selected_arch="armv6" ;;
		esac
		;;
	darwin)
		case "$detected_arch" in
		x86_64) selected_arch="amd64" ;;
		arm64) selected_arch="$detected_arch" ;;
		esac
		;;
	*)
		echo "Platform $platform not supported!" 2>&1
		exit 1
		;;
	esac

	if [ -z "$selected_arch" ]; then
		echo "Machine architecture $detected_arch not supported!" 2>&1
		exit 1
	fi

	if [ "$platform" = "darwin" ] &&
		[ "$selected_arch" = "arm64" ] &&
		[ "$(compare_versions "$version" "0.4.1")" -lt 0 ]; then
		echo "Darwin AArch64 builds are only available for v0.4.1+; using x86_64." 2>&1
		selected_arch="amd64"
	fi

	if [ "$platform" = "linux" ] &&
		([ "$selected_arch" = "arm64" ] || [ "$selected_arch" = "armv6" ]) &&
		[ "$(compare_versions "$version" "0.5.1")" -lt 0 ]; then
		echo "Linux ARMv6 builds are only available for v0.5.1+!" 2>&1
		exit 1
	fi

	if [ "$platform" = "linux" ] &&
		[ "$selected_arch" = "armv6" ] &&
		[ "$(compare_versions "$version" "0.6.6")" -eq 0 ]; then
		echo "A Linux ARMv6 build is not available for v0.6.6!" 2>&1
		exit 1
	fi

	if ([ "$platform" = "linux" ] && [ "$(compare_versions "$version" "0.6")" -le 0 ]) ||
		([ "$platform" = "darwin" ] && [ "$(compare_versions "$version" "0.6.2")" -le 0 ]); then
		if [ "$platform" = "darwin" ]; then
			platform="mac-os"
		fi

		if [ "$selected_arch" = "amd64" ]; then
			selected_arch="x86_64"
		fi
	fi

	local url="$GH_REPO/releases/download/v${version}/${TOOL_NAME}_${version}_${platform}_${selected_arch}.tar.gz"

	echo "* Downloading $TOOL_NAME release $version..."
	curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}/bin"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "$install_path"
		cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

		local tool_cmd
		tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
