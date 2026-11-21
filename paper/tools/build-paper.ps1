param([switch]$Rebuild)
$ErrorActionPreference = 'Stop'
$paperDirectory = Split-Path -Parent $PSScriptRoot
$candidate = Get-Item -LiteralPath $paperDirectory
$texDirectory = $null
while ($null -ne $candidate) {
    $possible = Join-Path $candidate.FullName '.tools\texlive\bin\windows'
    if (Test-Path -LiteralPath (Join-Path $possible 'latexmk.exe')) {
        $texDirectory = $possible
        break
    }
    $candidate = $candidate.Parent
}
if (-not $texDirectory) {
    throw 'Project portable TeX Live was not found (.tools/texlive/bin/windows).'
}
$texRoot = Split-Path -Parent (Split-Path -Parent $texDirectory)
$env:PATH = $texDirectory + ';' + (Join-Path $texRoot 'tlpkg\tlperl\bin') + ';' + $env:PATH
$env:LC_ALL = 'C'
$env:LANG = 'C'
Push-Location -LiteralPath $paperDirectory
try {
    New-Item -ItemType Directory -Path 'build' -Force | Out-Null
    $buildArguments = @('-pdf', '-synctex=1', '-interaction=nonstopmode', '-halt-on-error', '-file-line-error', '-outdir=build')
    if ($Rebuild) { $buildArguments += '-g' }
    $buildArguments += 'main.tex'
    & (Join-Path $texDirectory 'latexmk.exe') @buildArguments
    $buildExit = $LASTEXITCODE
    if ($buildExit -ne 0) { exit $buildExit }
    Write-Host ('PDF: ' + (Join-Path $paperDirectory 'build\main.pdf'))
} finally {
    Pop-Location
}
