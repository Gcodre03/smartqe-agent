# squash-list.ps1
# Explorer l'arborescence Squash : projets, dossiers, cas de test.
#
# Exemples :
#   pwsh squash-list.ps1 -Projects
#   pwsh squash-list.ps1 -ProjectId 1 -TestCases
#   pwsh squash-list.ps1 -FolderId 209 -Content
#   pwsh squash-list.ps1 -TestCaseId 210            # detail complet d'un cas
param(
    [switch]$Projects,
    [int]$ProjectId,
    [switch]$TestCases,
    [int]$FolderId,
    [switch]$Content,
    [int]$TestCaseId,
    [int]$Size = 50
)
. "$PSScriptRoot\squash-lib.ps1"

if ($Projects) {
    $r = Invoke-Squash -Path "/api/rest/latest/projects?size=100"
    $r._embedded.projects | ForEach-Object { Write-Output ("[{0}] {1}" -f $_.id, $_.name) }
    return
}
if ($ProjectId -and $TestCases) {
    $r = Invoke-Squash -Path "/api/rest/latest/projects/$ProjectId/test-cases?size=$Size"
    $r._embedded.'test-cases' | ForEach-Object { Write-Output ("[{0}] {1} (ref {2})" -f $_.id, $_.name, $_.reference) }
    Write-Output ("--- Total: {0} cas ---" -f $r.page.totalElements)
    return
}
if ($FolderId -and $Content) {
    $r = Invoke-Squash -Path "/api/rest/latest/test-case-folders/$FolderId/content"
    $r._embedded.content | ForEach-Object { Write-Output ("[{0}] {1} <{2}>" -f $_.id, $_.name, $_._type) }
    return
}
if ($TestCaseId) {
    $r = Invoke-Squash -Path "/api/rest/latest/test-cases/$TestCaseId"
    $r | ConvertTo-Json -Depth 8 | Write-Output
    return
}
Write-Output "Usage: -Projects | -ProjectId N -TestCases | -FolderId N -Content | -TestCaseId N"
