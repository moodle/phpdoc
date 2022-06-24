#!/usr/bin/env bash
set -e

SCRIPTSDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$( cd "$( dirname "${SCRIPTSDIR}" )" && pwd )"
PHPDOCROOT="${ROOT}/phpdocs"

VERSIONLIST=(${VERSIONLIST[@]:-master})
BRANCHLIST=(${BRANCHLIST[@]:-master})

mkdir -p build
echo "============================================================================"
echo "= Building for the following versions and branches:"
echo "= Versions: ${VERSIONLIST[*]}"
echo "= Branches: ${BRANCHLIST[*]}"
echo "============================================================================"

htmlbranchlist=""

for index in ${!VERSIONLIST[@]}; do
  version=${VERSIONLIST[$index]}
  moodlebranch=${BRANCHLIST[$index]}
  APIDOCDIR="build/${version}"
  echo "========================================"
  echo "== Generating PHP API Documentation for ${version} using branch ${moodlebranch}"
  echo "== Generated documentation will be placed into ${APIDOCDIR}"
  echo "========================================"

  # Change into the Moodle directory to get some information.
  export INPUT="${ROOT}/.moodle"
  cd "${INPUT}"

  # Checkout the correct branch.
  echo "Checking out remote branch"
  git fetch origin "${moodlebranch}"
  git checkout "remotes/origin/${moodlebranch}"
  HASH=`git log -1 --format="%h"`

  echo "========================================"
  echo "== Building PHP Documentation"
  echo "========================================"
  # Generate the php documentation
  docker run \
      -v "${ROOT}":"${ROOT}" \
      -w "${ROOT}" \
      -e HASH="${HASH}" \
      -e INPUT="${INPUT}" \
      -e VERSION="${version}" \
      -u "${UID}":"${UID}" \
      doxygen

  # Move the built files into the build directory
  echo "========================================"
  echo "== Moving phpdocs into ${APIDOCDIR}"
  echo "========================================"
  cd "${ROOT}"
  mv "build/phpdocs/${version}/html" "${APIDOCDIR}"

  echo "========================================"
  echo "== Completed documentation generation for ${version}"
  echo "========================================"

  htmlbranchlist="${htmlbranchlist}
        <li><a href='./${version}'>Moodle ${version}</a></li>"
done

cat "${ROOT}/index.head.tpl" > "${ROOT}/build/index.html"
echo "${htmlbranchlist}" >> "${ROOT}/build/index.html"
cat "${ROOT}/index.foot.tpl" >> "${ROOT}/build/index.html"

echo "============================================================================"
echo "= Documentation build completed."
echo "============================================================================"
