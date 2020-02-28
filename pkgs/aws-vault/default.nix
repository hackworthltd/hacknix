{ buildGoModule, fetchFromGitHub, lib }:
buildGoModule rec {
  pname = "aws-vault";
  version = "4.6.4";

  src = fetchFromGitHub {
    owner = "99designs";
    repo = pname;
    #rev = "v${version}";
    rev = "d5df81a5f396a30babaeb66f7c16f940fa724c43";
    sha256 = "0k69i6j0h7kqb5yazwdc6idww8w4kd5hyimrsjxyqs5wmf3k1nfl";
  };

  modSha256 = "155nhxmwyjm0046kmjaxcxvzv8hs9pakxrs5j8dg5np6gdxydiil";

  # set the version. see: aws-vault's Makefile
  buildFlagsArray = ''
    -ldflags=
    -X main.Version=v${version}
  '';

  postInstall = ''
    # install shell completions
    install -v -m644 -D completions/bash/aws-vault $out/share/bash-completion/completions/aws-vault
    install -v -m644 -D completions/zsh/_aws-vault $out/share/zsh/site-functions/_aws-vault
    install -v -m644 -D completions/fish/aws-vault.fish $out/share/fish/vendor_completions.d/aws-vault.fish
  '';

  meta = with lib; {
    description = "A vault for securely storing and accessing AWS credentials in development environments";
    homepage = "https://github.com/99designs/aws-vault";
    license = licenses.mit;
    maintainers = with lib.maintainers; [ dhess ];
  };

}



# buildGoModule rec {
#   pname = "jump";
#   version = "0.23.0";

#   src = fetchFromGitHub {
#     owner = "gsamokovarov";
#     repo = pname;
#     rev = "v${version}";
#     sha256 = "1acpvg3adcjnxnz9vx7q99cvnkkvkxfdjkbh2rb6iwakx7ksaakv";
#   };

#   modSha256 = "1fzsm85c31vkdw80kijxmjhk8jyhjz8b21npgks2qrnizhm6iaf8";

#   outputs = [ "out" "man"];
#   postInstall = ''
#     install -D --mode=444 man/j.1 man/jump.1 -t $man/man/man1/

#     # generate completion scripts for jump
#     export HOME="$NIX_BUILD_TOP"
#     mkdir -p $out/share/{bash-completion/completions,fish/vendor_completions.d,zsh/site-functions}
#     $out/bin/jump shell bash > "$out/share/bash-completion/completions/jump"
#     $out/bin/jump shell fish > $out/share/fish/vendor_completions.d/jump.fish
#     $out/bin/jump shell zsh > $out/share/zsh/site-functions/_jump
#   '';

#   meta = with lib; {
#     description = "Jump helps you navigate faster by learning your habits.";
#     longDescription = ''
#       Jump integrates with the shell and learns about your
#       navigational habits by keeping track of the directories you visit. It
#       strives to give you the best directory for the shortest search term.
#     '';
#     homepage = https://github.com/gsamokovarov/jump;
#     license = licenses.mit;
#     platforms = platforms.all;
#     maintainers = with maintainers; [ sondr3 ];
#   };
# }
  
