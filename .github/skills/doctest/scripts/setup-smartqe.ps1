# setup-smartqe.ps1
# Setup partageable SmartQE (sans credentials en repo)
#
# Ce script:
# - cree .secrets/squash.env local (token perso)
# - propose de generer .vscode/mcp.json depuis le template ARC1
# - n'ecrit aucun secret dans git

param(
    [string]$DefaultSquashBase = "https://saas-decathlon01.henix.com/squash",
    [switch]$SkipArc1
)

$ErrorActionPreference = 'Stop'

function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }

$repoRoot = (Get-Location).Path
$secretsDir = Join-Path $repoRoot '.secrets'
$secretsFile = Join-Path $secretsDir 'squash.env'

New-Item -ItemType Directory -Path $secretsDir -Force | Out-Null

if (Test-Path $secretsFile) {
    Write-Info "$secretsFile existe deja (non ecrase)."
} else {
    $base = Read-Host "SQUASH_BASE" 
    if ([string]::IsNullOrWhiteSpace($base)) { $base = $DefaultSquashBase }

    $tokenSecure = Read-Host "SQUASH_API_TOKEN (personnel)" -AsSecureString
    $tokenBstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($tokenSecure)
    try {
        $token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($tokenBstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($tokenBstr)
    }

    if ([string]::IsNullOrWhiteSpace($token)) {
        throw "Token vide. Setup interrompu."
    }

    @(
        "SQUASH_BASE=$base"
        "SQUASH_API_TOKEN=$token"
    ) | Out-File -FilePath $secretsFile -Encoding utf8

    Write-Ok "Secrets Squash ecrits dans $secretsFile"
}

if (-not $SkipArc1) {
    $template = Join-Path $repoRoot '.github/skills/doctest/templates/mcp.arc1.template.json'
    $vscodeDir = Join-Path $repoRoot '.vscode'
    $mcpFile = Join-Path $vscodeDir 'mcp.json'

    if (-not (Test-Path $template)) {
        Write-Warn "Template ARC1 introuvable: $template"
    } else {
        if (Test-Path $mcpFile) {
            Write-Info "$mcpFile existe deja (non ecrase)."
        } else {
            New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null
            Copy-Item $template $mcpFile
            Write-Ok "Template MCP ARC1 copie vers $mcpFile"
            Write-Warn "Remplacez les placeholders <...> dans $mcpFile avec vos infos locales."
        }
    }
}

Write-Host ""
Write-Ok "Setup termine."
Write-Info "Verification Squash: pwsh .github/skills/doctest/scripts/squash-list.ps1 -Projects"
