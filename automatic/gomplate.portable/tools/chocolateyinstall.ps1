$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation  = $toolsDir
  softwareName   = 'gomplate.portable*'
  fileType       = 'exe'
  url            = 'https://github.com/hairyhenderson/gomplate/releases/download/v3.4.0/gomplate_windows-386.exe'
  url64bit       = 'https://github.com/hairyhenderson/gomplate/releases/download/v3.4.0/gomplate_windows-amd64.exe'
  checksum       = 'b6f6a62e4e43cfd867221cc1323e6cfd96646ba7de444571b2370eb427f47156'
  checksumType   = 'sha256'
  checksum64     = 'ed7afa225ec73b846ed8d743743d338a1b58519513b8730ceb7ec12f0e34e830'
  checksumType64 = 'sha256'
}

Install-ChocolateyPackage @packageArgs
