# squash-lib.ps1
# Bibliotheque partagee pour l'API REST Squash TM.
# Le token est lu depuis .secrets\squash.env (jamais en dur, jamais affiche).

function Get-SquashConfig {
    # Ordre de recherche du fichier de secrets (portable, ne depend pas de la machine/utilisateur) :
    # 1. Variable d'environnement SQUASH_ENV_FILE (chemin explicite)
    # 2. .secrets\squash.env a la racine du repo (4 niveaux au-dessus de ce script)
    # 3. .secrets\squash.env dans le repertoire courant
    # 4. ~\.copilot\.secrets\squash.env (compatibilite historique)
    $candidates = @()
    if ($env:SQUASH_ENV_FILE) { $candidates += $env:SQUASH_ENV_FILE }
    $candidates += (Join-Path $PSScriptRoot '..\..\..\..\.secrets\squash.env')
    $candidates += (Join-Path (Get-Location) '.secrets\squash.env')
    $candidates += (Join-Path $HOME '.copilot\.secrets\squash.env')

    $envFile = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $envFile) {
        throw "Fichier introuvable: squash.env (creer avec SQUASH_BASE et SQUASH_API_TOKEN). Chemins testes: $($candidates -join ', ')"
    }
    $cfg = @{}
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#=]+)=(.*)$') { $cfg[$matches[1].Trim()] = $matches[2].Trim() }
    }
    if (-not $cfg.SQUASH_BASE -or -not $cfg.SQUASH_API_TOKEN) {
        throw "squash.env incomplet: SQUASH_BASE et SQUASH_API_TOKEN requis."
    }
    $cfg.SQUASH_BASE = $cfg.SQUASH_BASE.TrimEnd('/')
    return $cfg
}

function Get-SquashHeaders {
    param([switch]$Json)
    $cfg = Get-SquashConfig
    $h = @{ Authorization = "Bearer $($cfg.SQUASH_API_TOKEN)"; Accept = 'application/json' }
    if ($Json) { $h['Content-Type'] = 'application/json' }
    return $h
}

function Invoke-Squash {
    param(
        [Parameter(Mandatory)][string]$Path,   # ex: /api/rest/latest/projects
        [string]$Method = 'Get',
        $Body = $null
    )
    $cfg = Get-SquashConfig
    $uri = "$($cfg.SQUASH_BASE)$Path"
    $headers = Get-SquashHeaders -Json:($null -ne $Body)
    try {
        if ($Body) {
            $json = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 12 }
            return Invoke-RestMethod -Uri $uri -Headers $headers -Method $Method -Body $json
        } else {
            return Invoke-RestMethod -Uri $uri -Headers $headers -Method $Method
        }
    } catch {
        $detail = $_.ErrorDetails.Message
        throw "Squash API $Method $Path -> $($_.Exception.Message) $detail"
    }
}
