"""Intègre les articles des blocs Le Corps et L'Esprit (docs/articles/*.json) dans la maquette.

Usage : python3 scripts/integrer-articles.py
Le script vérifie chaque article, puis remplace les tableaux ARTICLES_CORPS et
ARTICLES_ESPRIT entre leurs marqueurs @ARTICLES_… dans maquette/index.html.
Un bloc dont les fichiers sont tous absents est laissé tel quel.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
NBSP = " "
TYPO = [("« ", "«" + NBSP), (" »", NBSP + "»"), (" :", NBSP + ":"), (" ;", NBSP + ";"), (" ?", NBSP + "?"), (" !", NBSP + "!")]

BLOCS = {
    "CORPS": {
        "files": ["corps-gout-odorat.json", "corps-toucher-ouie.json", "corps-vue-audela.json", "corps-mouvement-soin.json"],
        "salons": ["Le Goût", "L'Odorat", "Le Toucher", "L'Ouïe", "La Vue", "Au-delà des cinq sens", "Corps en mouvement", "Soin & bien-être"],
        "fields": {"salon": str, "title": str, "excerpt": str, "tag": str, "body": list, "plaisir": str, "pratique": list, "sources": list},
        "optional": {"media": (str, type(None))},
        "typo": ["title", "excerpt", "body", "plaisir", "pratique"],
    },
    "ESPRIT": {
        "files": ["esprit-philo-1.json", "esprit-philo-2.json", "esprit-spiritualites.json", "esprit-textes.json",
                  "esprit-meditation.json", "esprit-mythes.json", "esprit-ethique.json",
                  "esprit-monde-afrique.json", "esprit-monde-ameriques.json", "esprit-monde-russie-asie.json"],
        "salons": ["Philosophies d'Orient et d'Occident", "Spiritualités & religions du monde", "Textes sacrés & sagesses",
                   "Méditation & pleine conscience", "Mythes, symboles & ésotérisme", "Éthique & sens de la vie"],
        "fields": {"salon": str, "title": str, "excerpt": str, "tag": str, "repere": str, "body": list, "cles": list,
                   "pratique": list, "sources": list},
        "optional": {"lieu": (dict, type(None)), "citation": (dict, type(None)), "videos": list, "auteur": (str, type(None))},
        "typo": ["title", "excerpt", "repere", "body", "cles", "pratique"],
    },
}


def typo(value):
    """Espaces insécables de la typographie française, pour qu'aucun signe ne reste seul en bout de ligne."""
    if isinstance(value, list):
        return [typo(v) for v in value]
    if isinstance(value, str):
        for a, b in TYPO:
            value = value.replace(a, b)
    return value


def check(article, conf, where):
    problems = []
    for name, kind in conf["fields"].items():
        if not isinstance(article.get(name), kind) or not article.get(name):
            problems.append(f"champ « {name} » manquant ou vide")
    for name, kinds in conf["optional"].items():
        if name in article and not isinstance(article[name], kinds):
            problems.append(f"champ « {name} » de type inattendu")
    if article.get("salon") not in conf["salons"]:
        problems.append(f"salon inconnu : {article.get('salon')}")
    if article.get("tag") not in ("Informer", "Éduquer"):
        problems.append(f"étiquette inconnue : {article.get('tag')}")
    for s in article.get("sources") or []:
        if not s.get("ref") or not str(s.get("url", "")).startswith("http"):
            problems.append(f"source incomplète : {s}")
    lieu = article.get("lieu")
    if lieu and not (isinstance(lieu.get("lat"), (int, float)) and isinstance(lieu.get("lon"), (int, float)) and lieu.get("nom")):
        problems.append(f"lieu incomplet : {lieu}")
    cit = article.get("citation")
    if cit and not (cit.get("texte") and cit.get("auteur")):
        problems.append(f"citation incomplète : {cit}")
    for v in article.get("videos") or []:
        if not (v.get("title") and v.get("channel") and str(v.get("url", "")).startswith("https://www.youtube.com/watch?v=")):
            problems.append(f"vidéo incomplète : {v}")
    return [f"{where} : {p}" for p in problems]


def integrate(html, name, conf):
    articles, problems, found = [], [], 0
    for file in conf["files"]:
        path = ROOT / "docs" / "articles" / file
        if not path.exists():
            problems.append(f"{file} : fichier absent")
            continue
        found += 1
        for i, a in enumerate(json.loads(path.read_text(encoding="utf-8"))):
            problems += check(a, conf, f"{file} n°{i + 1}")
            item = {k: a.get(k) for k in [*conf["fields"], *conf["optional"]]}
            for k in conf["typo"]:
                item[k] = typo(item[k])
            if item.get("citation"):
                item["citation"] = {**item["citation"], "texte": typo(item["citation"]["texte"])}
            articles.append(item)
    if not found:
        print(f"{name} : aucun fichier, bloc laissé tel quel")
        return html
    if problems:
        print("\n".join(problems))
        sys.exit(1)
    articles.sort(key=lambda a: conf["salons"].index(a["salon"]))
    data = json.dumps(articles, ensure_ascii=False, indent=1).replace("</", "<\\/")
    pattern = re.compile(rf"(/\* @ARTICLES_{name}:start \*/\n).*?(\n/\* @ARTICLES_{name}:end \*/)", re.S)
    if not pattern.search(html):
        sys.exit(f"Marqueurs @ARTICLES_{name} introuvables dans maquette/index.html")
    html = pattern.sub(lambda m: f"{m.group(1)}const ARTICLES_{name} = {data};{m.group(2)}", html)
    print(f"{name} : {len(articles)} articles intégrés")
    for s in conf["salons"]:
        print(f"  {s} : {sum(a['salon'] == s for a in articles)}")
    return html


def main():
    page = ROOT / "maquette" / "index.html"
    html = page.read_text(encoding="utf-8")
    for name, conf in BLOCS.items():
        html = integrate(html, name, conf)
    page.write_text(html, encoding="utf-8")


if __name__ == "__main__":
    main()
