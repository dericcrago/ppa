#!/usr/bin/env bash

export DEB_SIGN_PROGRAM="gpg --pinentry-mode loopback --passphrase-file ${HOME}/signing.passphrase"
export TARBALL_BASE_URL="https://files.pythonhosted.org/packages/source"

# handle different release types better in the changelog
DEB_VERSION_EXTRA=$(echo "${DEB_VERSION}" | grep -Po '[a-z]+.*' || true)

if [[ -n "${DEB_VERSION_EXTRA}" ]]; then
  DEB_VERSION_BASE=$(echo "${DEB_VERSION}" | grep -Po '^[\d+\.]+')
  export DEB_CHANGELOG_VERSION="${DEB_VERSION_BASE}"~"${DEB_VERSION_EXTRA}"
else
  export DEB_CHANGELOG_VERSION="${DEB_VERSION}"
fi

rm -rf "${HOME:?}"/"${DEB_NAME:?}"
mkdir -p "${HOME}"/"${DEB_NAME}" && cd "$_" || exit
wget "${TARBALL_BASE_URL}"/"${DEB_NAME:0:1}"/"${DEB_NAME}"/"${DEB_NAME}"-"${DEB_VERSION}".tar.gz

DATE=$(date -Ru)
export DATE

for DIST in ${DEB_DIST}; do
  export DIST

  mkdir -p "${DIST}"
  tar -C "${DIST}" -xzf "${DEB_NAME}"-"${DEB_VERSION}".tar.gz
  cp -av "${DEB_NAME}"-"${DEB_VERSION}".tar.gz "${DIST}"/"${DEB_NAME}"_"${DEB_CHANGELOG_VERSION}".orig.tar.gz

  cd "${DIST}"/"${DEB_NAME}"-"${DEB_VERSION}" || exit

  # restore debian dir from this repo
  cp -a "${HOME}"/work/ppa/ppa/"${DEB_NAME}"/packaging/debian ./
  envsubst < "${HOME}"/work/ppa/ppa/"${DEB_NAME}"/packaging/templates/changelog > ./debian/changelog

  debuild -S -k"${DEBSIGN_KEYID}" -p"${DEB_SIGN_PROGRAM}"
  cd - || exit
  dput "${LAUNCHPAD_PPA}" "${DIST}"/"${DEB_NAME}"_"${DEB_CHANGELOG_VERSION}"-"${DEB_RELEASE}"~"${DIST}"_source.changes
done
