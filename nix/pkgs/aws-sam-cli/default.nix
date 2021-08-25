{ lib
, python3
, fetchFromGitHub
, enableTelemetry ? false
}:

let

  py = python3.override {
    packageOverrides = self: super: {
      aws-lambda-builders = super.aws-lambda-builders.overridePythonAttrs (oldAttrs: rec {
        version = "1.3.0";
        src = fetchFromGitHub {
          owner = "awslabs";
          repo = "aws-lambda-builders";
          rev = "v${version}";
          sha256 = "sha256-G5i60jr9t2g3beFIp7zDNVTuFqR6eZbZcErjosBlyrE=";
        };
      });
      watchdog = super.watchdog.overridePythonAttrs (oldAttrs: rec {
        version = "1.0.2";
        src = oldAttrs.src.override {
          inherit version;
          sha256 = "sha256-N2y8KjXAOSsP5/8W+8GzA/2Z1N2ZEatVge6daa3IiYI=";
        };
        patches = [ ];
        doCheck = false;
      });
      docker = super.docker.overridePythonAttrs (oldAttrs: {
        doCheck = false;
      });
    };
  };

in
py.pkgs.buildPythonApplication rec {
  pname = "aws-sam-cli";

  # Note: upstream versions after 1.23.0 require watchdog > 2, which
  # is problematic on macOS and is precisely the reason this version
  # override package exists.
  version = "1.23.0";

  src = py.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "sha256-rgQhxqwGOvAejpBdSQ2U7JB50uHvMcE8+IkOhsA1GEg=";
  };

  # Tests are not included in the PyPI package
  doCheck = false;

  propagatedBuildInputs = with py.pkgs; [
    aws-lambda-builders
    aws-sam-translator
    chevron
    click
    cookiecutter
    dateparser
    python-dateutil
    docker
    flask
    jmespath
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
      --replace "boto3~=1.14.23" "boto3~=1.14" \
      --replace "dateparser~=0.7" "dateparser>=0.7" \
      --replace "docker~=4.2.0" "docker>=4.2.0" \
      --replace "python-dateutil~=2.6, <2.8.1" "python-dateutil~=2.6" \
      --replace "requests==2.23.0" "requests~=2.24" \
      --replace "watchdog==0.10.3" "watchdog" \
      --replace "Flask~=1.1.2" "Flask" \
      --replace "tomlkit==0.7.0" "tomlkit" \
      --replace "click~=7.1" "click" \
      --replace "aws-sam-translator==1.35.0" "aws-sam-translator>=1.35.0"
  '';

  meta = with lib; {
    homepage = "https://github.com/awslabs/aws-sam-cli";
    description = "CLI tool for local development and testing of Serverless applications";
    license = licenses.asl20;
    maintainers = with maintainers; [ dhess ];
  };
}
