{ buildGoModule
, fetchFromGitHub
, installShellFiles
, lib
, stdenv
, pkg-config
, pcsclite
, PCSC
, withApplePCSC ? stdenv.isDarwin
}:
buildGoModule rec {
  pname = "vervet";
  version = "git-20230219";

  src = fetchFromGitHub {
    owner = "onryo";
    repo = pname;
    rev = "9b674439e14b3e7d14930f2e5229aab662eb992d";
    sha256 = "sha256-qVsAm/yuji3+zLsgsUeXk6UAAf6gFH/762HYwgieh1Y=";
  };

  vendorHash = "sha256-7Hf9gC+/qXyDNc1WNN8ln3k+jPDgWb48RFLn/V/3Aus=";

  patches = [
    ./go-1.20.patch
  ];

  subPackages = [ "." ];

  nativeBuildInputs = [ pkg-config installShellFiles ];

  buildInputs = [ ]
    ++ (if withApplePCSC then [ PCSC ] else [ pcsclite ]);

  meta = with lib; {
    description =
      "Vault YubiKey OpenPGP unseal utility";
    homepage = "https://github.com/onryo/vervet";
    license = licenses.mpl20;
    maintainers = with maintainers; [ dhess ];
  };
}

