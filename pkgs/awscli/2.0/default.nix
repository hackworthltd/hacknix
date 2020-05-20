{ lib
, python3
, groff
, less
, fetchurl
}:
let
  py = python3.override {
    packageOverrides = self: super: {
      botocore = super.botocore.overridePythonAttrs (oldAttrs: rec {
        version = "2.0.0dev18";
        src = fetchurl {
          url = "https://github.com/boto/botocore/archive/6fcdef789aac19bd44afde3c3a82b4bd5f0f3067.tar.gz";
          sha256 = "009al6x8a7xn5l1frcmlfx8hp3qb6bqc0jp0px41xphvhd84pc3z";
        };
      });
      prompt_toolkit = super.prompt_toolkit.overridePythonAttrs (oldAttrs: rec {
        version = "2.0.10";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "1nr990i4b04rnlw1ghd0xmgvvvhih698mb6lb6jylr76cs7zcnpi";
        };
      });
    };
  };

in
with py.pkgs; buildPythonApplication rec {
  pname = "awscli";
  version = "2.0.14"; # N.B: if you change this, change botocore to a matching version too

  src = fetchurl {
    url = "https://github.com/aws/aws-cli/archive/2.0.14.tar.gz";
    sha256 = "1m5hl4lss0jk6a8vgkkxmil5kx94416dcmy52w0i024hjgyvjlnr";
  };

  postPatch = ''
    substituteInPlace setup.py --replace ",<0.16" ""
    substituteInPlace setup.py --replace "cryptography>=2.8.0,<=2.9.0" "cryptography>=2.8.0,<2.10"
  '';

  # No tests included
  doCheck = false;

  propagatedBuildInputs = [
    botocore
    bcdoc
    cryptography
    s3transfer
    six
    colorama
    docutils
    rsa
    ruamel_yaml
    prompt_toolkit
    pyyaml
    groff
    less
  ];

  postInstall = ''
    mkdir -p $out/etc/bash_completion.d
    echo "complete -C $out/bin/aws_completer aws" > $out/etc/bash_completion.d/awscli
    mkdir -p $out/share/zsh/site-functions
    mv $out/bin/aws_zsh_completer.sh $out/share/zsh/site-functions
    rm $out/bin/aws.cmd
  '';

  passthru.python = py; # for aws_shell

  meta = with lib; {
    homepage = "https://aws.amazon.com/cli/";
    description = "Unified tool to manage your AWS services";
    license = licenses.asl20;
    maintainers = with maintainers; [ dhess ];
  };
}
