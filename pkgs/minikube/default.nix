{ source, stdenv, lib, buildGoModule, fetchFromGitHub, pkgconfig, makeWrapper
, go-bindata, bash, libvirt, qemu, gpgme, Foundation, Security, libobjc, vmnet
, xpc, hyperkit, extraDrivers ? [ ] }:

let

  drivers = stdenv.lib.filter (d: d != null) extraDrivers;

  binPath = drivers ++ stdenv.lib.optionals stdenv.isLinux ([ libvirt qemu ])
    ++ stdenv.lib.optionals stdenv.isDarwin ([ hyperkit ]);

in buildGoModule rec {
  pname = "minikube";
  version = "1.9.2";

  goPackagePath = "k8s.io/minikube";
  subPackages = [ "cmd/minikube" ]
    ++ stdenv.lib.optional stdenv.hostPlatform.isLinux "cmd/drivers/kvm"
    ++ stdenv.lib.optional stdenv.hostPlatform.isDarwin "cmd/drivers/hyperkit";
  modSha256 = "1pxs6myszgma3rzz0nhfjbnylv6m0xzlinvmlg0c4ijvkkzxg3v5";

  src = fetchFromGitHub { inherit (source) repo owner sha256 rev; };

  nativeBuildInputs = [ pkgconfig go-bindata makeWrapper ];
  buildInputs = [ gpgme ] ++ stdenv.lib.optionals stdenv.isLinux [ libvirt ]
    ++ stdenv.lib.optionals stdenv.isDarwin [
      Foundation
      Security
      libobjc
      vmnet
    ];

  postPatch = ''
    substituteInPlace pkg/minikube/command/exec_runner.go \
      --replace "/bin/bash" ${bash}/bin/bash
  '';

  preBuild = ''
    ${go-bindata}/bin/go-bindata -nomemcopy -o pkg/minikube/assets/assets.go -pkg assets deploy/addons/...
    ${go-bindata}/bin/go-bindata -nomemcopy -o pkg/minikube/translate/translations.go -pkg translate translations/...

    VERSION_MAJOR=$(grep "^VERSION_MAJOR" Makefile | sed "s/^.*\s//")
    VERSION_MINOR=$(grep "^VERSION_MINOR" Makefile | sed "s/^.*\s//")
    ISO_VERSION=v$VERSION_MAJOR.$VERSION_MINOR.0
    ISO_BUCKET=$(grep "^ISO_BUCKET" Makefile | sed "s/^.*\s//")

    export buildFlagsArray="-ldflags=\
      -X ${goPackagePath}/pkg/version.version=v${version} \
      -X ${goPackagePath}/pkg/version.isoVersion=$ISO_VERSION \
      -X ${goPackagePath}/pkg/version.isoPath=$ISO_BUCKET \
      -X ${goPackagePath}/pkg/version.gitCommitID=${source.rev} \
      -X ${goPackagePath}/pkg/drivers/kvm.version=v${version} \
      -X ${goPackagePath}/pkg/drivers/kvm.gitCommitID=${source.rev} \
      -X ${goPackagePath}/pkg/drivers/hyperkit.version=v${version} \
      -X ${goPackagePath}/pkg/drivers/hyperkit.gitCommitID=${source.rev}"
  '';

  postInstall = ''
    wrapProgram $out/bin/${pname} --prefix PATH : $out/bin:${
      stdenv.lib.makeBinPath binPath
    }
    mkdir -p $out/share/bash-completion/completions/
    MINIKUBE_WANTUPDATENOTIFICATION=false MINIKUBE_WANTKUBECTLDOWNLOADMSG=false HOME=$PWD $out/bin/minikube completion bash > $out/share/bash-completion/completions/minikube

    mkdir -p $out/share/zsh/site-functions/
    MINIKUBE_WANTUPDATENOTIFICATION=false MINIKUBE_WANTKUBECTLDOWNLOADMSG=false HOME=$PWD $out/bin/minikube completion zsh > $out/share/zsh/site-functions/_minikube
  '' + stdenv.lib.optionalString stdenv.hostPlatform.isDarwin ''
    mv $out/bin/hyperkit $out/bin/docker-machine-driver-hyperkit
  '' + stdenv.lib.optionalString stdenv.hostPlatform.isLinux ''
    mv $out/bin/kvm $out/bin/docker-machine-driver-kvm2
  '';

  meta = with lib; {
    homepage = "https://github.com/kubernetes/minikube";
    description = "A tool that makes it easy to run Kubernetes locally";
    license = licenses.asl20;
    maintainers = with maintainers; [ dhess ];
    platforms = with platforms; unix;
  };
}
