{ lib
, stdenv
, fetchurl
, runCommand
, unzip
, vscode-utils
, icu
, curl
, openssl
, lttng-ust
, musl
, autoPatchelfHook
, python3
, pythonUseFixed ? true       # When `true`, the python default setting will be fixed to specified.
  # Use version from `PATH` for default setting otherwise.
  # Defaults to `false` as we expect it to be project specific most of the time.
, ctagsUseFixed ? true
, ctags  # When `true`, the ctags default setting will be fixed to specified.
  # Use version from `PATH` for default setting otherwise.
  # Defaults to `true` as usually not defined on a per projet basis.
}:

assert ctagsUseFixed -> null != ctags;
let
  extractNuGet = { name, version, src, ... }: stdenv.mkDerivation {
    inherit name version src;

    buildInputs = [ unzip ];
    dontBuild = true;
    unpackPhase = "unzip $src";
    installPhase = ''
      mkdir -p "$out"
      chmod -R +w .
      find . -mindepth 1 -maxdepth 1 | xargs cp -a -t "$out"
    '';
  };

  pythonDefaultsTo = if pythonUseFixed then "${python3}/bin/python" else "python";
  ctagsDefaultsTo = if ctagsUseFixed then "${ctags}/bin/ctags" else "ctags";

  # The arch tag comes from 'PlatformName' defined here:
  # https://github.com/Microsoft/vscode-python/blob/master/src/client/activation/types.ts
  arch =
    if stdenv.isLinux && stdenv.isx86_64 then "linux-x64"
    else if stdenv.isDarwin then "osx-x64"
    else throw "Only x86_64 Linux and Darwin are supported.";

  languageServerSha256 = {
    linux-x64 = "0x4269swyciwhzlwjrl5fmbli4p9qvycx0cr9ywlyd7q353jz4r7";
    osx-x64 = "1ixkh6kzcbjql4kmpkckbv32423vl6z7jf3j0bdb1705bfyw97xg";
  }.${arch};

  languageServer = extractNuGet rec {
    name = "Python-Language-Server";
    version = "0.5.50";

    src = fetchurl {
      url = "https://pvsc.azureedge.net/python-language-server-stable/${name}-${arch}.${version}.nupkg";
      sha256 = languageServerSha256;
    };
  };

  libcMusl =
    runCommand "libc-musl-x86_64"
      { } ''
      mkdir -p $out/lib
      cp -pdv ${musl}/lib/libc.so $out/lib/libc.musl-x86_64.so.1
      ln -s $out/lib/libc.musl-x86_64.so.1 $out/lib/libc.musl-x86_64.so
    '';
in
vscode-utils.buildVscodeMarketplaceExtension {
  mktplcRef = {
    name = "python";
    publisher = "ms-python";
    version = "2020.5.80290";
    sha256 = "0ybr8f1ki70dqwkh34q3p1liv81jr0jfxhavy79n08l3lalrwkb1";
  };

  buildInputs = [
    icu
    curl
    openssl
  ] ++ lib.optional stdenv.isLinux [
    lttng-ust
    libcMusl
  ];

  nativeBuildInputs = [
    python3.pkgs.wrapPython
  ] ++ lib.optional stdenv.isLinux [
    autoPatchelfHook
  ];

  pythonPath = with python3.pkgs; [
    setuptools
  ];

  postPatch = ''
    # Patch `packages.json` so that nix's *python* is used as default value for `python.pythonPath`.
    substituteInPlace "./package.json" \
      --replace "\"default\": \"python\"" "\"default\": \"${pythonDefaultsTo}\""

    # Patch `packages.json` so that nix's *ctags* is used as default value for `python.workspaceSymbols.ctagsPath`.
    substituteInPlace "./package.json" \
      --replace "\"default\": \"ctags\"" "\"default\": \"${ctagsDefaultsTo}\""
  '';

  postInstall = ''
    mkdir -p "$out/$installPrefix/languageServer.${languageServer.version}"
    cp -R --no-preserve=ownership ${languageServer}/* "$out/$installPrefix/languageServer.${languageServer.version}"
    chmod a+x "$out/$installPrefix/languageServer.${languageServer.version}/Microsoft.Python.LanguageServer"

    patchPythonScript "$out/$installPrefix/pythonFiles/lib/python/isort/main.py"
  '';

  meta = with lib; {
    license = licenses.mit;
    maintainers = [ maintainers.dhess ];
    platforms = with platforms; [ "x86_64-linux" "x86_64-darwin" ];
  };
}
