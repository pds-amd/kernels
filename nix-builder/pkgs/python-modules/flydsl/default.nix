{
  lib,
  buildPythonPackage,
  fetchurl,
  python,
  numpy,
  torch,
  autoPatchelfHook,
  stdenv,
  zlib,
  ncurses,
  libxml2,
  rocmPackages,
}:

let
  wheels = {
    "310" = {
      url = "https://files.pythonhosted.org/packages/3a/98/1be63b435e7116cf076e3bd631d1d7d390b2c2e83aa2fa78be8a70d0e0e0/flydsl-0.4.2-cp310-cp310-manylinux_2_27_x86_64.whl";
      hash = "sha256-fMYRRkQkxpSe98W0g56FwOVnZpAW5lPq6Ijr5KRXoHE=";
    };
    "311" = {
      url = "https://files.pythonhosted.org/packages/9f/ff/d5475348021faae67116c781fd61705b0d3a2bd659e98a5e15ac7018ce1a/flydsl-0.4.2-cp311-cp311-manylinux_2_27_x86_64.whl";
      hash = "sha256-oDWpUYy0RlKxGLMYdOgJZE2Hvx5nfeyHuETnmWBGTJk=";
    };
    "312" = {
      url = "https://files.pythonhosted.org/packages/3f/31/aa58a9f1748902bf9303350917b8f1bad4495edd1c7bd0330329b3c29292/flydsl-0.4.2-cp312-cp312-manylinux_2_27_x86_64.whl";
      hash = "sha256-+prfB1rp3KSM/+6Lx7Xs3i0GC4ptvx2BUoZ/VnZoFr8=";
    };
    "313" = {
      url = "https://files.pythonhosted.org/packages/37/ac/03d2b519c2512e28b631c7ee91913a00209b451ca6d0d051e93f33701e41/flydsl-0.4.2-cp313-cp313-manylinux_2_27_x86_64.whl";
      hash = "sha256-qhKUV4PcyYU71qJckUE0054ZCAQV3tf49S0yy8ZTxcU=";
    };
    "314" = {
      url = "https://files.pythonhosted.org/packages/4c/0d/8d03f00225ad877856a23947b323ebb9d96b2f06d2a4b64f9b34e70e46e8/flydsl-0.4.2-cp314-cp314-manylinux_2_27_x86_64.whl";
      hash = "sha256-9tGrtS2hyoUDjpo39yrOUtDZa6Pc62N1oCzOqMI9sC0=";
    };
  };
  pythonTag = builtins.replaceStrings [ "." ] [ "" ] python.pythonVersion;
in
buildPythonPackage {
  pname = "flydsl";
  version = "0.4.2";
  format = "wheel";
  src = fetchurl wheels.${pythonTag};
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    stdenv.cc.cc.lib
    zlib
    ncurses
    libxml2
    rocmPackages.clr
  ];
  dependencies = [
    numpy
    torch
  ];
  # FlyDSL otherwise searches PATH and silently falls back to gfx942 when the
  # enumerator is absent, including in the kernel CI runner's Python environment.
  postInstall = ''
    substituteInPlace "$out/${python.sitePackages}/flydsl/runtime/device.py" \
      --replace-fail '"rocm_agent_enumerator"' '"${rocmPackages.rocminfo}/bin/rocm_agent_enumerator"'
    # MLIR resolves the linker as <toolkit>/llvm/bin/ld.lld. Give its default
    # serialization pass a Nix toolkit instead of the compiled-in /opt/rocm.
    mkdir -p "$out/rocm/llvm/bin"
    ln -s "${rocmPackages.llvm.clang}/bin/ld.lld" "$out/rocm/llvm/bin/ld.lld"
    substituteInPlace "$out/${python.sitePackages}/flydsl/compiler/backends/rocm.py" \
      --replace-fail 'gpu-module-to-binary{{format=fatbin' "gpu-module-to-binary{{toolkit=$out/rocm format=fatbin"
  '';
  pythonImportsCheck = [
    "flydsl.compiler"
    "flydsl.expr"
  ];
  meta = {
    description = "MLIR-based GPU kernel compiler and DSL for AMD ROCm";
    homepage = "https://github.com/ROCm/FlyDSL";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
  };
}
