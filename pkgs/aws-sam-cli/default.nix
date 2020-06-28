{ lib
, python3
, fetchFromGitHub
, enableTelemetry ? false
}:
let
  py = python3.override {
    packageOverrides = self: super: {
      flask = super.flask.overridePythonAttrs (oldAttrs: rec {
        version = "1.0.2";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "0j6f4a9rpfh25k1gp7azqhnni4mb4fgy50jammgjgddw1l3w0w92";
        };
      });

      aws-lambda-builders = super.aws-lambda-builders.overridePythonAttrs (oldAttrs: rec {
        version = "0.9.0";
        src = fetchFromGitHub {
          owner = "awslabs";
          repo = "aws-lambda-builders";
          rev = "v${version}";
          sha256 = "0cgb0hwf4xg5dmm32wwlxqy7a77jw6gpnj7v8rq5948hsy2sfrcp";
        };
      });

      aws-sam-translator = super.aws-sam-translator.overridePythonAttrs (oldAttrs: rec {
        version = "1.25.0";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "08756yl5lpqgrpr80f2b6bdcgygr37l6q1yygklcg9hz4yfpccav";
        };
      });

      boto3 = super.boto3.overridePythonAttrs (oldAttrs: rec {
        version = "1.13.0";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "0wpzvlxiyhm0m125x2kqdv24f3gaqs39xgwmhb3yb52nh3xnqnc0";
        };
      });

      botocore = super.botocore.overridePythonAttrs (oldAttrs: rec {
        version = "1.16.0";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "1gxm6ja31xx7yzkql84hy5s4flvr2y0w17sxkgn6q7jmgmfnnrsb";
        };
      });

      cookiecutter = super.cookiecutter.overridePythonAttrs (oldAttrs: rec {
        version = "1.6.0";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "0glsvaz8igi2wy1hsnhm9fkn6560vdvdixzvkq6dn20z3hpaa5hk";
        };
      });

      jmespath = super.jmespath.overridePythonAttrs (oldAttrs: rec {
        version = "0.9.5";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "1nf2ipzvigspy17r16dpkhzn1bqdmlak162rm8dy4wri2n6mr9fc";
        };
      });

      python-dateutil = super.python-dateutil.overridePythonAttrs (oldAttrs: rec {
        version = "2.7.5";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "00ngwcdw36w5b37b51mdwn3qxid9zdf3kpffv2q6n9kl05y2iyc8";
        };
      });

      serverlessrepo = super.serverlessrepo.overridePythonAttrs (oldAttrs: rec {
        version = "0.1.9";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "1xf0g97jym4607kikkiassrnmcfniz5syaigxlz09d9p8h70sd0c";
        };
      });

      tomlkit = super.tomlkit.overridePythonAttrs (oldAttrs: rec {
        version = "0.5.8";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "0sf2a4q61kf344hjbw8kb6za1hlccl89j9lzqw0l2zpddp0hrh9j";
        };
      });
    };
  };

in
with py.pkgs;

buildPythonApplication rec {
  pname = "aws-sam-cli";
  version = "0.53.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1w1qwljzr308wv5qmcv843kibcgl7xi6qcd3xc4zg01hw9ns3s52";
  };

  # Tests are not included in the PyPI package
  doCheck = false;

  propagatedBuildInputs = [
    aws-lambda-builders
    aws-sam-translator
    chevron
    click
    cookiecutter
    dateparser
    docker
    flask
    idna
    jmespath
    pathlib2
    requests
    serverlessrepo
    six
    tomlkit
  ];

  postFixup = if enableTelemetry then "echo aws-sam-cli TELEMETRY IS ENABLED" else ''
    # Disable telemetry: https://github.com/awslabs/aws-sam-cli/issues/1272
    wrapProgram $out/bin/sam --set  SAM_CLI_TELEMETRY 0
  '';

  # fix over-restrictive version bounds
  # postPatch = ''
  #   substituteInPlace requirements/base.txt \
  #     --replace "serverlessrepo==0.1.9" "serverlessrepo~=0.1.9" \
  #     --replace "python-dateutil~=2.6, <2.8.1" "python-dateutil~=2.6" \
  #     --replace "tomlkit==0.5.8" "tomlkit~=0.5.8" \
  #     --replace "requests==2.22.0" "requests~=2.22"
  # '';

  meta = with lib; {
    homepage = "https://github.com/awslabs/aws-sam-cli";
    description = "CLI tool for local development and testing of Serverless applications";
    license = licenses.asl20;
    maintainers = with maintainers; [ andreabedini lo1tuma ];
  };
}
