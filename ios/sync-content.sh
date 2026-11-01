#!/usr/bin/env bash
# Synchronise les fiches sources (docs/articles/*.json, à la racine du dépôt)
# vers les ressources du module GuaWanCore, embarquées dans l'app.
#
# Ajouter une fiche = ajouter un fichier JSON dans docs/articles/ (même schéma
# que les fichiers existants), relancer ce script, recompiler. Rien d'autre.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

SRC="../docs/articles"
DEST="Packages/GuaWanCore/Sources/GuaWanCore/Resources/Content"

mkdir -p "$DEST"
rm -f "$DEST"/*.json
cp "$SRC"/*.json "$DEST"/

echo "$(ls "$DEST"/*.json | wc -l | tr -d ' ') fiche(s) JSON synchronisée(s) vers $DEST"
