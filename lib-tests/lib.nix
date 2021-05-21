let
  test-dir = dir: dirPattern: ''
    echo -n "Checking for ${dirPattern} directory(s)... "
    [[ "$(./bin/dir-exists.sh ${dir} ${dirPattern})" == "yes" ]] || (echo "${dirPattern} does not exist!" && exit 1)
    echo "pass"
  '';

  test-file = dir: filePattern: ''
    echo -n "Checking for ${filePattern} file(s)... "
    [[ "$(./bin/file-exists.sh ${dir} ${filePattern})" == "yes" ]] || (echo "${filePattern} does not exist!" && exit 1)
    echo "pass"
  '';

  test-no-dir = dir: dirPattern: ''
    echo -n "Checking for no ${dirPattern} directory(s)... "
    [[ "$(./bin/dir-exists.sh ${dir} ${dirPattern})" == "no" ]] || (echo "${dirPattern} exists!" && exit 1)
    echo "pass"
  '';

  test-no-file = dir: filePattern: ''
    echo -n "Checking for no ${filePattern} file(s)... "
    [[ "$(./bin/file-exists.sh ${dir} ${filePattern})" == "no" ]] || (echo "${filePattern} exists!" && exit 1)
    echo "pass"
  '';
in
{
  inherit test-dir;
  inherit test-file;
  inherit test-no-dir;
  inherit test-no-file;
}
