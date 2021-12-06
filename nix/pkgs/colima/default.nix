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
    rev = "e1df01257a5aa73a373e04f965d803697df41564";
    sha256 = "sha256-HineaXtLXdsOAG7TRct+OCQmXI2FWWDGYflOlcxiIvk=";
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
