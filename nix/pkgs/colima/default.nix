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
    rev = "519a3722a03807d878dd8ddc21b2d188a982ba42";
    sha256 = "sha256-npXdx1Qw0NLGJEtt7DP2L0uNdbYVm3AOazoWyFx8Nso=";
  };

  vendorSha256 = "sha256-F1ym88JrJWzsBg89Y1ufH4oefIRBwTGOw72BrjtpvBw=";

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
