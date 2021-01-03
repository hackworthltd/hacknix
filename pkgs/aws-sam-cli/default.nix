{ fetchFromGitHub
, lib
, python3
, enableTelemetry ? false
}:
let
  py = python3.override {
    packageOverrides = self: super: {
      flask = super.flask.overridePythonAttrs (oldAttrs: rec {
        version = "1.1.2";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "sha256-Tvoa4tfJhlr0iYbeiuuFBL8yx/PW/ck1PTSyH0sScGA=";
        };
      });

      aws-sam-translator = super.aws-sam-translator.overridePythonAttrs (oldAttrs: rec {
        version = "1.33.0";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "sha256-nzdnYUdGo4MA7piO9w1vhi5x5Z6lNiUrv5oxnaqsH/8=";
        };
      });

      watchdog = super.watchdog.overridePythonAttrs (oldAttrs: rec {
        version = "0.10.3";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "sha256-QhThN50SiwWIAhiAzK9AMX7hVtRgOsOIua3PKRZeDAQ=";
        };
      });

      dateparser = super.dateparser.overridePythonAttrs (oldAttrs: rec {
        version = "0.7.6";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "sha256-6HXv2MV8hcLQKyOCOYeNtZ/xlx9agjRX/MaeSTv26/o=";
        };
      });

      cookiecutter = super.cookiecutter.overridePythonAttrs (oldAttrs: rec {
        version = "1.7.2";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "sha256-77ay1HgP7aiQioc+OPDmF3jCP2oupYIVcjvM61tRXaw=";
        };
      });

      botocore = super.botocore.overridePythonAttrs (oldAttrs: rec {
        version = "1.17.23";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "sha256-ZxHawwTay0mYHXIu+RvYm9gra8aM8KCJC8MFc9y7GJk=";
        };
      });

      boto3 = super.boto3.overridePythonAttrs (oldAttrs: rec {
        version = "1.14.23";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "sha256-ox2bLWgaDOfbjkdoeSIrJ0VaHMSaYOIRHg3bR8V00Sc=";
        };
      });

      urllib3 = super.urllib3.overridePythonAttrs (oldAttrs: rec {
        version = "1.21.1";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "sha256-sUSGl4UYygkBp2upc9eCEEdAnX9ybyIVayToP9cTgqU=";
        };
      });

      docker = super.docker.overridePythonAttrs (oldAttrs: rec {
        version = "4.2.0";
        doCheck = false;
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "sha256-3a5mYgq19LznafZLzXk0+IDIq+aqUJhimNtWc10Pci4=";
        };
      });

      werkzeug = super.werkzeug.overridePythonAttrs (oldAttrs: rec {
        doCheck = false;
      });
    };
  };

in
with py.pkgs;

buildPythonApplication rec {
  pname = "aws-sam-cli";
  version = "1.15.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-ptS1/ncCLCJZ4wXXsBlYIBcv0VlRyNPyx2dRk6c7n58=";
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
    jmespath
    python-dateutil
    requests
    serverlessrepo
    tomlkit
    watchdog
  ];

  postFixup = if enableTelemetry then "echo aws-sam-cli TELEMETRY IS ENABLED" else ''
    # Disable telemetry: https://github.com/awslabs/aws-sam-cli/issues/1272
    wrapProgram $out/bin/sam --set  SAM_CLI_TELEMETRY 0
  '';

  # fix over-restrictive version bounds
  postPatch = ''
    substituteInPlace requirements/base.txt \
      --replace "jmespath~=0.9.5" "jmespath~=0.10.0" \
      --replace "python-dateutil~=2.6, <2.8.1" "python-dateutil~=2.6" \
      --replace "requests==2.23.0" "requests~=2.24" \
      --replace "serverlessrepo==0.1.9" "serverlessrepo~=0.1.9" \
      --replace "tomlkit==0.5.8" "tomlkit~=0.7.0"
  '';

  meta = with lib; {
    homepage = "https://github.com/awslabs/aws-sam-cli";
    description = "CLI tool for local development and testing of Serverless applications";
    license = licenses.asl20;
    maintainers = with maintainers; [ dhess ];
  };
}
