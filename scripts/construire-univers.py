"""Construit les données de L'Univers, la carte interactive de Guà Wàn (maquette/univers/).

Usage : python3 scripts/construire-univers.py
L'arborescence (blocs, groupes, salons, icônes) est définie dans CARTE ci-dessous.
Les fiches sont les articles de docs/articles/*.json, vérifiés avec les mêmes règles
que scripts/integrer-articles.py. Le résultat est écrit dans maquette/univers/univers-data.js
(window.UNIVERS), lisible même quand la page est ouverte sans serveur.
"""
import importlib.util
import json
import pathlib
import re
import sys
import unicodedata

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "maquette" / "univers" / "univers-data.js"

_spec = importlib.util.spec_from_file_location("integrer_articles", ROOT / "scripts" / "integrer-articles.py")
ia = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(ia)

# Chaque salon : (nom exact du salon dans les articles, icône). Un salon sans article apparaît « à venir ».
CARTE = {
    "titre": "L'Univers",
    "racine": {"mot": "Vous", "sousTitre": "Chaque humain est le centre de son propre univers"},
    "blocs": [
        {"id": "esprit", "label": "L'Esprit", "kanji": "心", "icon": "esprit", "articles": "ESPRIT",
         "salons": [("Philosophies d'Orient et d'Occident", "philo"),
                    ("Spiritualités & religions du monde", "spiritualites"),
                    ("Textes sacrés & sagesses", "textes"),
                    ("Méditation & pleine conscience", "meditation"),
                    ("Mythes, symboles & ésotérisme", "mythes"),
                    ("Éthique & sens de la vie", "ethique")]},
        {"id": "creation", "label": "La Création", "kanji": "創", "icon": "creation", "articles": None,
         "salons": [("Sciences & découvertes", "sciences"),
                    ("Cosmos & physique", "cosmos"),
                    ("Arts visuels", "arts"),
                    ("Musique & son", "musique"),
                    ("Écriture & poésie", "ecriture"),
                    ("Cinéma & image", "cinema"),
                    ("IA & création", "ia")]},
        {"id": "corps", "label": "Le Corps", "kanji": "体", "icon": "corps", "articles": "CORPS",
         "groupes": [
             {"label": "Sensualité", "sousTitre": "Le plaisir des sens", "icon": "sensualite",
              "salons": [("Le Goût", "gout"), ("L'Odorat", "odorat"), ("Le Toucher", "toucher"),
                         ("L'Ouïe", "ouie"), ("La Vue", "vue"), ("Au-delà des cinq sens", "audela"),
                         ("Corps en mouvement", "mouvement"), ("Soin & bien-être", "soin")]},
             {"label": "Sexualité", "sousTitre": "18 ans et plus", "icon": "verrou", "couleur": "sexe",
              "verrou": "Réservé aux 18 ans et plus, avec vérification d'âge. Les salons sont en chantier : contenu à venir."},
         ]},
    ],
}

FILTRES = [
    {"id": "region", "bouton": "Par région", "court": "Région", "titre": "Explorer par région du monde",
     "intro": "Choisissez une région pour mettre en évidence toutes les fiches qui s'y rattachent."},
    {"id": "mission", "bouton": "Par mission", "court": "Mission", "titre": "Informer ou éduquer",
     "intro": "Chaque fiche sert l'une des deux missions de Guà Wàn. Choisissez-en une pour la voir partout sur la carte."},
]

# Mots du « repère » d'une fiche (lieu · époque) qui la rattachent à une région, sans accents ni majuscules.
REGIONS = {
    "Afrique": ["afrique", "algerie", "mali", "senegal", "ghana", "akan", "kongo", "kenya", "ethiopie",
                "egypte", "maghreb", "yoruba", "ife"],
    "Amériques": ["amerique", "etats-unis", "wisconsin", "canadien", "navajo", "lakota", "andes", "perou",
                  "equateur", "bolivie", "bresil", "paraguay", "argentine", "martinique", "guatemala", "mexique"],
    "Asie": ["japon", "inde", "chine", "birmanie", "tibet", "himalaya", "mongolie", "asie", "ouzbekistan",
             "kirghizistan", "siberie", "sakha", "touva", "sri lanka", "cachemire", "pendjab", "gange",
             "tamoul", "iranien", "indien"],
    "Europe": ["grece", "autriche", "france", "angleterre", "royaume-uni", "europe", "russie", "kyiv",
               "islande", "romain", "provinces-unies", "al-andalus", "danube", "byzantin"],
    "Proche-Orient": ["anatolie", "liban", "proche-orient", "babylon", "mesopotamie", "irak", "galilee",
                      "jerusalem", "judee", "arabie", "mecque", "byzantin"],
    "Océanie": ["australie", "maoris", "whanganui"],
    "Le monde entier": ["monde", "neurosciences", "recherche"],
}


def norm(text):
    text = unicodedata.normalize("NFD", text.lower())
    return "".join(c for c in text if unicodedata.category(c) != "Mn")


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", norm(text)).strip("-")[:60].rstrip("-")


def short(title):
    """Titre court pour la bulle : ce qui précède « : » ou la question finissant par « ? »."""
    m = re.match(r"(.{4,}?)(?:\s:\s|(?<=\?)\s)", title)
    return m.group(1) if m else title


def regions_of(repere):
    flat = norm(repere or "")
    return [name for name, words in REGIONS.items() if any(re.search(r"\b" + re.escape(w), flat) for w in words)]


def load(name):
    """Charge et vérifie les articles d'un bloc, avec la typographie française de la maquette."""
    conf = ia.BLOCS[name]
    articles, problems = [], []
    for file in conf["files"]:
        path = ROOT / "docs" / "articles" / file
        if not path.exists():
            problems.append(f"{file} : fichier absent")
            continue
        for i, a in enumerate(json.loads(path.read_text(encoding="utf-8"))):
            problems += ia.check(a, conf, f"{file} n°{i + 1}")
            for k in conf["typo"]:
                a[k] = ia.typo(a[k])
            if a.get("citation"):
                a["citation"] = {**a["citation"], "texte": ia.typo(a["citation"]["texte"])}
            articles.append(a)
    if problems:
        print("\n".join(problems))
        sys.exit(1)
    return articles


def card(a, icon, ids):
    base = slug(a["title"])
    cid, n = base, 2
    while cid in ids:
        cid, n = f"{base}-{n}", n + 1
    ids.add(cid)
    out = {"id": cid, "label": a["title"], "court": short(a["title"]), "icon": icon,
           "resume": a["excerpt"], "mission": a["tag"],
           "corps": a["body"], "pratique": a["pratique"], "sources": a["sources"],
           "tags": {"mission": [a["tag"]]}}
    if a.get("repere"):
        out["repere"] = a["repere"]
        out["tags"]["region"] = regions_of(a["repere"])
        if not out["tags"]["region"]:
            print(f"Aucune région reconnue pour « {a['repere']} » ({a['title']})")
    for src, dst in [("cles", "essentiel"), ("plaisir", "plaisir"), ("citation", "citation"), ("videos", "videos")]:
        if a.get(src):
            out[dst] = a[src]
    return out


def salon_node(name, icon, by_salon, ids):
    items = by_salon.pop(name, [])
    node = {"id": slug(name), "label": name, "icon": icon, "children": [card(a, icon, ids) for a in items]}
    if not items:
        node["aVenir"] = "Salon en préparation : les premières fiches arrivent bientôt."
    return node


def main():
    ids = set()
    root = {"id": "racine", "label": CARTE["racine"]["mot"], "sousTitre": CARTE["racine"]["sousTitre"], "children": []}
    for bloc in CARTE["blocs"]:
        by_salon = {}
        for a in load(bloc["articles"]) if bloc["articles"] else []:
            by_salon.setdefault(a["salon"], []).append(a)
        node = {"id": bloc["id"], "label": bloc["label"], "kanji": bloc["kanji"], "icon": bloc["icon"],
                "couleur": bloc["id"], "children": []}
        for g in bloc.get("groupes", []):
            child = {"id": slug(g["label"]), "label": g["label"], "sousTitre": g["sousTitre"], "icon": g["icon"]}
            if g.get("couleur"):
                child["couleur"] = g["couleur"]
            if g.get("verrou"):
                child["verrou"] = g["verrou"]
            else:
                child["children"] = [salon_node(n, i, by_salon, ids) for n, i in g["salons"]]
            node["children"].append(child)
        node["children"] += [salon_node(n, i, by_salon, ids) for n, i in bloc.get("salons", [])]
        if by_salon:
            sys.exit(f"Salons absents de CARTE : {', '.join(by_salon)}")
        root["children"].append(node)

    cards = [c for b in root["children"] for c in walk(b) if "children" not in c and "verrou" not in c and "aVenir" not in c]
    data = {"titre": CARTE["titre"], "filtres": FILTRES, "arbre": root}
    OUT.parent.mkdir(exist_ok=True)
    payload = json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    OUT.write_text(f"/* Généré par scripts/construire-univers.py : ne pas modifier à la main. */\nwindow.UNIVERS = {payload};\n",
                   encoding="utf-8")
    print(f"{len(cards)} fiches écrites dans {OUT.relative_to(ROOT)}")
    for name in REGIONS:
        print(f"  {name} : {sum(name in c['tags'].get('region', []) for c in cards)}")


def walk(node):
    yield node
    for c in node.get("children", []):
        yield from walk(c)


if __name__ == "__main__":
    main()
