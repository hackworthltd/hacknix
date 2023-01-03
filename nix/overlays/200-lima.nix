final: prev:
let
  lima = final.callPackage ../pkgs/lima {
    inherit (final.darwin) sigtool;
  };

  lima-binary = final.callPackage ../pkgs/lima/binary.nix { };

  colima-lima = if final.stdenv.isDarwin then final.lima-binary else final.lima;

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
  inherit lima;
  inherit lima-binary;
  inherit colima;
}
