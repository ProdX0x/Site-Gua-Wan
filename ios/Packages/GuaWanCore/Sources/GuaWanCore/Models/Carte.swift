import Foundation

/// Un salon : la plus petite unité de regroupement thématique d'un groupe/bloc.
/// Les fiches (`Fiche.salon`) s'y rattachent par leur nom exact.
public struct Salon: Hashable, Sendable {
    public let nom: String
    public let icon: String

    public init(_ nom: String, icon: String) {
        self.nom = nom
        self.icon = icon
    }
}

/// Un groupe de salons à l'intérieur d'un bloc (ex. « Sensualité », « Sexualité » dans Le Corps).
/// Un groupe « verrouillé » (`verrou != nil`) n'a pas de salons ouverts : c'est une section
/// à venir, protégée par une vérification d'âge sur le vrai site.
public struct Groupe: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let sousTitre: String?
    public let icon: String
    public let couleur: String?
    public let verrou: String?
    public let salons: [Salon]
    /// Noms indicatifs des sections à venir derrière le verrou (affichage seulement).
    public let chantier: [String]

    public init(label: String, sousTitre: String? = nil, icon: String, couleur: String? = nil,
                verrou: String? = nil, salons: [Salon] = [], chantier: [String] = []) {
        self.id = TextNormalization.slug(label)
        self.label = label
        self.sousTitre = sousTitre
        self.icon = icon
        self.couleur = couleur
        self.verrou = verrou
        self.salons = salons
        self.chantier = chantier
    }
}

/// Un bloc : l'une des trois grandes voies de Guà Wàn (L'Esprit 心, La Création 創, Le Corps 体).
public struct Bloc: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let kanji: String
    public let icon: String
    public let couleur: String
    /// `false` pour La Création : aucune fiche n'y est publiée encore (salons « à venir »).
    public let aDesFiches: Bool
    /// Salons directement sous le bloc (cas de L'Esprit et La Création).
    public let salonsDirects: [Salon]
    /// Groupes intermédiaires sous le bloc (cas du Corps : Sensualité / Sexualité).
    public let groupes: [Groupe]

    public init(id: String, label: String, kanji: String, icon: String, couleur: String? = nil,
                aDesFiches: Bool = true, salonsDirects: [Salon] = [], groupes: [Groupe] = []) {
        self.id = id
        self.label = label
        self.kanji = kanji
        self.icon = icon
        self.couleur = couleur ?? id
        self.aDesFiches = aDesFiches
        self.salonsDirects = salonsDirects
        self.groupes = groupes
    }

    /// Tous les salons du bloc, groupe confondu — pratique pour chercher où ranger une fiche.
    public var tousLesSalons: [Salon] { salonsDirects + groupes.flatMap(\.salons) }
}

/// Un filtre transverse applicable à la carte (voir `openFilter` dans univers.js) :
/// met en évidence toutes les fiches d'une région du monde, ou d'une mission éditoriale.
public struct Filtre: Identifiable, Hashable, Sendable {
    public let id: String
    public let bouton: String
    public let court: String
    public let titre: String
    public let intro: String
}

/// La taxonomie complète de Guà Wàn : reflet exact de `CARTE` dans
/// `scripts/construire-univers.py`. C'est de la configuration, pas du contenu —
/// ajouter un *salon* demande d'y toucher, ajouter une *fiche* dans un salon
/// existant n'en demande rien (voir `ContentRepository`).
public enum Carte {

    public static let titreUnivers = "L'Univers"
    public static let racineMot = "Vous"
    public static let racineSousTitre = "Chaque humain est le centre de son propre univers"

    public static let esprit = Bloc(
        id: "esprit", label: "L'Esprit", kanji: "心", icon: "esprit",
        salonsDirects: [
            Salon("Philosophies d'Orient et d'Occident", icon: "philo"),
            Salon("Spiritualités & religions du monde", icon: "spiritualites"),
            Salon("Textes sacrés & sagesses", icon: "textes"),
            Salon("Méditation & pleine conscience", icon: "meditation"),
            Salon("Mythes, symboles & ésotérisme", icon: "mythes"),
            Salon("Éthique & sens de la vie", icon: "ethique"),
        ]
    )

    public static let creation = Bloc(
        id: "creation", label: "La Création", kanji: "創", icon: "creation", aDesFiches: false,
        salonsDirects: [
            Salon("Sciences & découvertes", icon: "sciences"),
            Salon("Cosmos & physique", icon: "cosmos"),
            Salon("Arts visuels", icon: "arts"),
            Salon("Musique & son", icon: "musique"),
            Salon("Écriture & poésie", icon: "ecriture"),
            Salon("Cinéma & image", icon: "cinema"),
            Salon("IA & création", icon: "ia"),
        ]
    )

    public static let corps = Bloc(
        id: "corps", label: "Le Corps", kanji: "体", icon: "corps",
        groupes: [
            Groupe(label: "Sensualité", sousTitre: "Le plaisir des sens", icon: "sensualite", salons: [
                Salon("Le Goût", icon: "gout"),
                Salon("L'Odorat", icon: "odorat"),
                Salon("Le Toucher", icon: "toucher"),
                Salon("L'Ouïe", icon: "ouie"),
                Salon("La Vue", icon: "vue"),
                Salon("Au-delà des cinq sens", icon: "audela"),
                Salon("Corps en mouvement", icon: "mouvement"),
                Salon("Soin & bien-être", icon: "soin"),
            ]),
            Groupe(label: "Sexualité", sousTitre: "18 ans et plus", icon: "verrou", couleur: "sexe",
                   verrou: "Réservé aux 18 ans et plus, avec vérification d'âge. Les salons sont en chantier : contenu à venir.",
                   chantier: ["Éducation sexuelle", "Couple & relations", "Santé intime", "Galerie"]),
        ]
    )

    /// Dans cet ordre précisément à l'écran (voir `ORDER` dans index.html).
    public static let blocs: [Bloc] = [esprit, creation, corps]

    public static let filtres: [Filtre] = [
        Filtre(id: "region", bouton: "Par région", court: "Région",
               titre: "Explorer par région du monde",
               intro: "Choisissez une région pour mettre en évidence toutes les fiches qui s'y rattachent."),
        Filtre(id: "mission", bouton: "Par mission", court: "Mission",
               titre: "Informer ou éduquer",
               intro: "Chaque fiche sert l'une des deux missions de Guà Wàn. Choisissez-en une pour la voir partout sur la carte."),
    ]

    /// Mots du « repère » (lieu · époque) qui rattachent une fiche à une région du monde,
    /// sans accents ni majuscules — identique à `REGIONS` dans construire-univers.py.
    public static let regions: [(nom: String, motsClefs: [String])] = [
        ("Afrique", ["afrique", "algerie", "mali", "senegal", "ghana", "akan", "kongo", "kenya", "ethiopie",
                     "egypte", "maghreb", "yoruba", "ife"]),
        ("Amériques", ["amerique", "etats-unis", "wisconsin", "canadien", "navajo", "lakota", "andes", "perou",
                       "equateur", "bolivie", "bresil", "paraguay", "argentine", "martinique", "guatemala", "mexique"]),
        ("Asie", ["japon", "inde", "chine", "birmanie", "tibet", "himalaya", "mongolie", "asie", "ouzbekistan",
                  "kirghizistan", "siberie", "sakha", "touva", "sri lanka", "cachemire", "pendjab", "gange",
                  "tamoul", "iranien", "indien"]),
        ("Europe", ["grece", "autriche", "france", "angleterre", "royaume-uni", "europe", "russie", "kyiv",
                    "islande", "romain", "provinces-unies", "al-andalus", "danube", "byzantin"]),
        ("Proche-Orient", ["anatolie", "liban", "proche-orient", "babylon", "mesopotamie", "irak", "galilee",
                           "jerusalem", "judee", "arabie", "mecque", "byzantin"]),
        ("Océanie", ["australie", "maoris", "whanganui"]),
        ("Le monde entier", ["monde", "neurosciences", "recherche"]),
    ]

    /// Régions reconnues dans un « repère » de fiche (ex. « Mali · XIIIe siècle, tradition orale »).
    /// Une même fiche peut se rattacher à plusieurs régions.
    public static func regionsOf(repere: String?) -> [String] {
        guard let repere else { return [] }
        let folded = TextNormalization.fold(repere)
        let mots = Set(folded.split { !($0.isLetter || $0.isNumber || $0 == "-") }.map(String.init))
        return regions.filter { region in
            region.motsClefs.contains { clef in mots.contains { $0.hasPrefix(clef) } }
        }.map(\.nom)
    }
}
