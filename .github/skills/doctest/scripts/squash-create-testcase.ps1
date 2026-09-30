# squash-create-testcase.ps1
# Cree un cas de test dans Squash a partir d'un fichier JSON.
#
# Le JSON attendu (voir references/format-squash.md) :
# {
#   "name": "SD - Y400 - Marge 50% sur reference CZ",
#   "reference": "TNR-PRC-001",
#   "parentFolderId": 209,
#   "importance": "HIGH",              // VERY_HIGH | HIGH | MEDIUM | LOW
#   "status": "WORK_IN_PROGRESS",     // WORK_IN_PROGRESS | UNDER_REVIEW | APPROVED | OBSOLETE
#   "nature": "NAT_FUNCTIONAL_TESTING",
#   "type": "TYP_UNDEFINED",
#   "prerequisite": "<p>...</p>",
#   "description": "<p>...</p>",
#   "steps": [
#     { "action": "<p>...</p>", "expected_result": "<p>...</p>" }
#   ]
# }
#
# Exemple :
#   pwsh squash-create-testcase.ps1 -JsonFile ".\mon-cas.json"
#   pwsh squash-create-testcase.ps1 -JsonFile ".\lot.json"   # (fichier = tableau de cas)
param(
    [Parameter(Mandatory)][string]$JsonFile,
    [switch]$WhatIf
)
. "$PSScriptRoot\squash-lib.ps1"

if (-not (Test-Path $JsonFile)) { throw "Fichier JSON introuvable: $JsonFile" }
$raw = Get-Content $JsonFile -Raw | ConvertFrom-Json

# Accepte soit un objet unique soit un tableau de cas
$cases = if ($raw -is [System.Array]) { $raw } else { @($raw) }

function New-TestCasePayload($c) {
    if (-not $c.name)           { throw "Champ 'name' manquant." }
    if (-not $c.parentFolderId) { throw "Champ 'parentFolderId' manquant pour '$($c.name)'." }
    $steps = @()
    foreach ($s in $c.steps) {
        $steps += @{
            _type           = 'action-step'
            action          = [string]$s.action
            expected_result = [string]$s.expected_result
        }
    }
    $payload = @{
        _type        = 'test-case'
        name         = $c.name
        parent       = @{ _type = 'test-case-folder'; id = [int]$c.parentFolderId }
        importance   = ($c.importance | ForEach-Object { $_ }) ?? 'HIGH'
        status       = ($c.status      | ForEach-Object { $_ }) ?? 'WORK_IN_PROGRESS'
        nature       = @{ code = (($c.nature) ?? 'NAT_FUNCTIONAL_TESTING') }
        type         = @{ code = (($c.type)   ?? 'TYP_UNDEFINED') }
        steps        = $steps
    }
    if ($c.reference)    { $payload.reference    = $c.reference }
    if ($c.prerequisite) { $payload.prerequisite = $c.prerequisite }
    if ($c.description)  { $payload.description   = $c.description }
    return $payload
}

foreach ($c in $cases) {
    $payload = New-TestCasePayload $c
    if ($WhatIf) {
        Write-Output "[WHATIF] Creerait: $($c.name) (dossier $($c.parentFolderId), $($payload.steps.Count) etapes)"
        continue
    }
    $r = Invoke-Squash -Path "/api/rest/latest/test-cases" -Method Post -Body $payload
    Write-Output ("CREE  id={0}  {1}" -f $r.id, $r.path)
}
