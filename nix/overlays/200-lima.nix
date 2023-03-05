final: prev:
let
  lima-bin = final.callPackage ../pkgs/lima/bin.nix { };

  colima-lima = if final.stdenv.isDarwin then final.lima-bin else final.lima;

  colima = prev.colima.overrideAttrs (old: {
    postInstall = ''
      wrapProgram $out/bin/colima \
        --prefix PATH : ${final.lib.makeBinPath [ colima-lima final.qemu ]}

      installShellCompletion --cmd colima \
        --bash <($out/bin/colima completion bash) \
        --fish <($out/bin/colima completion fish) \
        --zsh <($out/bin/colima completion zsh)
    '';
  });
in
{
  inherit lima-bin;
  inherit colima;
}
