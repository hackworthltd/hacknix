{ lib
, stdenvNoCC
, fetchzip
}:

stdenvNoCC.mkDerivation rec {
  pname = "tart";
  version = "1.0.5";

  src = fetchzip {
    url = "https://github.com/cirruslabs/${pname}/releases/download/${version}/${pname}.tar.gz";
    sha256 = "sha256-bajZVudVUxLDPrOUqdeRa6iKUzI9DwxCTlMHCkebqkM=";
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
