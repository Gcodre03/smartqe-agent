# SmartQE — Agent Copilot CLI (TNR SAP Pricing SD/MM -> Squash TM)

SmartQE est un agent Copilot CLI + une skill projet pour concevoir des TNR SAP Pricing SD/MM
et publier dans Squash TM via API REST.

- Agent: `.github/agents/SmartQE.agent.md`
- Skill: `.github/skills/doctest/`

> Important: aucun login/mot de passe/token n'est versionne dans ce repo.
> Chaque utilisateur configure ses propres secrets localement.

---

## 1) Installation rapide (copier-coller)

```powershell
git clone https://github.com/Gcodre03/smartqe-agent.git
cd smartqe-agent
pwsh .github/skills/doctest/scripts/setup-smartqe.ps1
code .
```

Le script de setup:
- cree `.secrets/squash.env` (token personnel)
- peut generer `.vscode/mcp.json` a partir du template ARC1
- ne commit rien de sensible

---

## 2) Prompt pret a coller dans Copilot (option)

Si un collegue veut que Copilot fasse le setup guide:

```text
Clone ce repo, execute le setup SmartQE, puis demande-moi mes valeurs de secrets (Squash token, et eventuels parametres ARC1) avant de les ecrire en local:
https://github.com/Gcodre03/smartqe-agent.git
```

---

## 3) Secrets locaux (obligatoire)

Le fichier local `.secrets/squash.env` doit contenir:

```env
SQUASH_BASE=https://saas-decathlon01.henix.com/squash
SQUASH_API_TOKEN=<votre_token_personnel>
```

Chaque utilisateur genere son propre token Squash TM (Mon compte > API Token).
Ne jamais partager un token entre plusieurs personnes.

---

## 4) MCP ARC1 (optionnel)

Template fourni:
- `.github/skills/doctest/templates/mcp.arc1.template.json`

Pour l'utiliser localement:
1. copier le template vers `.vscode/mcp.json`
2. remplacer les placeholders (`<...>`)
3. garder `.vscode/mcp.json` local (ignore par git)

Aucun user/password ARC1 n'est stocke dans le repo.

---

## 5) Verification rapide

```powershell
pwsh .github/skills/doctest/scripts/squash-list.ps1 -Projects
```

Si la liste des projets s'affiche, Squash est OK.

---

## 6) Partage et mises a jour

- Pour partager: donner simplement le lien du repo.
- Pour recuperer les mises a jour:

```powershell
git pull
```

---

## 7) Securite

- Aucun secret en dur dans le repo
- `.secrets/` et `.vscode/mcp.json` exclus du versionnage
- Ne jamais commiter credentials, tokens, cookies, captures sensibles
