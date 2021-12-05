{ lib
, buildGoModule
, fetchFromGitHub
, installShellFiles
, docker
, kubectl
, lima
, makeWrapper
}:

buildGoModule rec {
  pname = "colima";
  version = "0.3.0-pre";

  src = fetchFromGitHub {
    owner = "abiosoft";
    repo = pname;
    rev = "57469b9e8c02404498e134f1afb0f824424fa768";
    sha256 = "sha256-uKMuFXNW1/SWXVs9pIFgeyf6rfeZYNZv8YTlcEv35XI=";
  };

  vendorSha256 = "sha256-Dl638NSrBP9jDceQQeeRz+Re1M8z2+AagIDVm+wo+48=";

  nativeBuildInputs = [ makeWrapper installShellFiles ];

  project = "github.com/abiosoft/colima";

  ldFlags = [
    "-X ${project}/config/appVersion=${version}"
    "-X ${project}/config/revision=${src.rev}"
  ];

  postInstall = ''
    wrapProgram $out/bin/colima \
      --prefix PATH : ${lib.makeBinPath [ lima docker kubectl ]}
    installShellCompletion --cmd colima \
      --bash <($out/bin/colima completion bash) \
      --fish <($out/bin/colima completion fish) \
      --zsh <($out/bin/colima completion zsh)
  '';

  meta = with lib; {
    homepage = "https://github.com/abiosoft/colima";
    description = "Container runtimes on macOS with minimal setup.";
    license = licenses.mit;
    platforms = platforms.darwin;
    maintainers = with maintainers; [ dhess ];
  };
}
