#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
matlab_bin="${MATLAB:-/Applications/MATLAB_R2026a.app/bin/matlab}"
bundle_dir="$root/dist/yunlink-sunray-matlab-1.1.0-bundle"
zip_file="$root/dist/yunlink-sunray-matlab-1.1.0-bundle.zip"
binding_dir="$root/dist/bindings"
sdk_wheel="$root/dist/yunlink_python-1.1.0-py3-none-any.whl"
python_bin="${PYTHON:-python3.12}"

cd "$root"
mkdir -p "$root/dist"

if [[ ! -f "$sdk_wheel" ]]; then
  "$python_bin" -m pip install -q build
  "$python_bin" -m build --wheel
fi
if [[ ! -f "$sdk_wheel" ]]; then
  echo "missing $sdk_wheel" >&2
  exit 1
fi

rm -rf "$binding_dir"
mkdir -p "$binding_dir"
gh release download v2.0.1 --repo YunDrone-Team/yunlink --dir "$binding_dir" --pattern 'yunlink-2.0.1-*.whl'

"$matlab_bin" -batch "addpath('$root/matlab'); addpath('$root/matlab/developer'); build_release_bundle('$bundle_dir','$binding_dir')"

rm -f "$zip_file"
(
  cd "$root/dist"
  zip -r "yunlink-sunray-matlab-1.1.0-bundle.zip" "yunlink-sunray-matlab-1.1.0-bundle"
)

echo "Created $zip_file"
