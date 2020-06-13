{ stdenv, lib, callPackage, fetchurl, isInsiders ? false }:
let
  inherit (stdenv.hostPlatform) system;

  plat = {
    x86_64-linux = "linux-x64";
    x86_64-darwin = "darwin";
  }.${system};

  archive_fmt = if system == "x86_64-darwin" then "zip" else "tar.gz";

  sha256 = {
    x86_64-linux = "0zdg6z6h0h8vvwdrnihwd76bik41spv6xbw7cdh7hz97sjsh15zq";
    x86_64-darwin = "1c5c24vj8nqsxx8hwfj04as7vsl9gnl97yniw36pdfgv88v8qzin";
  }.${system};
in
callPackage ./generic.nix rec {
  # The update script doesn't correctly change the hash for darwin, so please:
  # nixpkgs-update: no auto update

  # Please backport all compatible updates to the stable release.
  # This is important for the extension ecosystem.
  version = "1.45.1";
  pname = "vscode";

  executableName = "code" + lib.optionalString isInsiders "-insiders";
  longName = "Visual Studio Code" + lib.optionalString isInsiders " - Insiders";
  shortName = "Code" + lib.optionalString isInsiders " - Insiders";

  src = fetchurl {
    name = "VSCode_${version}_${plat}.${archive_fmt}";
    url = "https://vscode-update.azurewebsites.net/${version}/${plat}/stable";
    inherit sha256;
  };

  sourceRoot = "";

  meta = with lib; {
    description = ''
      Open source source code editor developed by Microsoft for Windows,
      Linux and macOS
    '';
    longDescription = ''
      Open source source code editor developed by Microsoft for Windows,
      Linux and macOS. It includes support for debugging, embedded Git
      control, syntax highlighting, intelligent code completion, snippets,
      and code refactoring. It is also customizable, so users can change the
      editor's theme, keyboard shortcuts, and preferences
    '';
    homepage = "https://code.visualstudio.com/";
    downloadPage = "https://code.visualstudio.com/Updates";
    license = licenses.unfree;
    maintainers = with maintainers; [ dhess ];
    platforms = [ "x86_64-linux" "x86_64-darwin" ];
  };
}