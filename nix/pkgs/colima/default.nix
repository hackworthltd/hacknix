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
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "abiosoft";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-vWNkYsT2XF+oMOQ3pb1+/a207js8B+EmVanRQrYE/2A=";
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
