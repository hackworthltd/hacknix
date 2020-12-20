{ lib
, python3
, groff
, less
, fetchFromGitHub
}:
let
  py = python3.override {
    packageOverrides = self: super: {
      botocore = super.botocore.overridePythonAttrs
        (oldAttrs: rec {
          version = "2.0.0dev71";
          src = fetchFromGitHub
            {
              owner = "boto";
              repo = "botocore";
              rev = "f8b31e2a01a8797f8331c6af2c93a26ff82b2b4b";
              sha256 = "0dzi92gzbprjapp4kmcy9y6m8ir92lan76frmfjr2pjghkmrb5fv";
            };
        });
      colorama = super.colorama.overridePythonAttrs (oldAttrs: rec {
        version = "0.4.3";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "189n8hpijy14jfan4ha9f5n06mnl33cxz7ay92wjqgkr639s0vg9";
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
  pname = "awscli2";
  version = "2.1.3"; # N.B: if you change this, change botocore to a matching version too

  src = fetchFromGitHub {
    owner = "aws";
    repo = "aws-cli";
    rev = version;
    sha256 = "0pfiyczjldsvz0f041n09gbp0ivm4nxr5jp8r26dd9nd6br4qjgf";
  };

  postPatch = ''
    substituteInPlace setup.py --replace "cryptography>=2.8.0,<=2.9.0" "cryptography>=2.8.0"
    substituteInPlace setup.py --replace "docutils>=0.10,<0.16" "docutils>=0.10"
    substituteInPlace setup.py --replace "ruamel.yaml>=0.15.0,<0.16.0" "ruamel.yaml>=0.15.0"
    substituteInPlace setup.py --replace "wcwidth<0.2.0" "wcwidth"
  '';

  # No tests included
  doCheck = false;

  propagatedBuildInputs = [
    bcdoc
    botocore
    colorama
    cryptography
    distro
    docutils
    groff
    less
    prompt_toolkit
    pyyaml
    rsa
    ruamel_yaml
    s3transfer
    six
    wcwidth
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
    homepage = "https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html";
    changelog = "https://github.com/aws/aws-cli/blob/${version}/CHANGELOG.rst";
    description = "Unified tool to manage your AWS services";
    license = licenses.asl20;
    maintainers = with maintainers; [ bhipple davegallant ];
  };
}
