{ lib
, stdenvNoCC
, fetchurl
, installShellFiles
, qemu
, makeWrapper
}:

let
  pname = "lima";
  version = "0.14.2";
  platform =
    if stdenvNoCC.system == "aarch64-darwin" then "Darwin-arm64"
    else if stdenvNoCC.system == "x86_64-darwin" then "Darwin-x86_64"
    else throw "Unsupported system ${stdenvNoCC.system}, use the `lima` package instead";
  sha256 =
    if stdenvNoCC.system == "aarch64-darwin" then "8334d83ca9555271b9843040066057dd8462a774f60dfaedbe97fae3834c3894"
    else if stdenvNoCC.system == "x86_64-darwin" then "3866113c92619f0041ff6fc68fef2bf16e751058b9237289b2bea8fb960bdab0"
    else throw "Unsupported system ${stdenvNoCC.system}, use the `lima` package instead";
  distName = "lima-${version}-${platform}";
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  src = fetchurl
    {
      url = "https://github.com/lima-vm/lima/releases/download/v${version}/${distName}.tar.gz";
      inherit sha256;
    };

  nativeBuildInputs = [ makeWrapper installShellFiles ];

  unpackPhase = ''
    mkdir -p ${distName}
    tar -C ${distName} -xf $src
  '';

  # It attaches entitlements with codesign and strip removes those,
  # voiding the entitlements and making it non-operational.
  dontStrip = stdenvNoCC.isDarwin;

  installPhase = ''
    mkdir -p $out
    cp -r ${distName}/* $out
    wrapProgram $out/bin/limactl \
      --prefix PATH : ${lib.makeBinPath [ qemu ]}
    installShellCompletion --cmd limactl \
      --bash <($out/bin/limactl completion bash) \
      --fish <($out/bin/limactl completion fish) \
      --zsh <($out/bin/limactl completion zsh)
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    USER=nix $out/bin/limactl validate $out/share/lima/examples/default.yaml
  '';

  meta = with lib; {
    homepage = "https://github.com/lima-vm/lima";
    description = "Linux virtual machines (on macOS, in most cases)";
    license = licenses.asl20;
    maintainers = with maintainers; [ dhess ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-darwin" "aarch64-darwin" ];
    mainProgram = "limactl";
    changelog = "https://github.com/lima-vm/lima/releases/tag/v${version}";
  };
}
