{ lib
, stdenvNoCC
, fetchzip
}:

stdenvNoCC.mkDerivation rec {
  pname = "tart";
  version = "0.36.3";

  src = fetchzip {
    url = "https://github.com/cirruslabs/${pname}/releases/download/${version}/${pname}.tar.gz";
    sha256 = "sha256-yff/HwH3PXljPOIEgxtQG+PasMnwJ7+8mifWqqFKUr4=";
    stripRoot = false;
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 tart -t $out/bin
    runHook postInstall
  '';

  meta = with lib; {
    description = "macOS VMs on Apple Silicon to use in CI and other automations";
    homepage = "https://github.com/cirruslabs/tart";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ dhess ];
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
