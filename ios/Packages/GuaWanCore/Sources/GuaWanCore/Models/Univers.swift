import Foundation

/// Le type d'un nœud de la carte « L'Univers ».
public enum NodeKind: String, Sendable {
    /// « Vous », le centre de la carte.
    case racine
    /// L'un des trois blocs (L'Esprit / La Création / Le Corps).
    case bloc
    /// Un groupe ou un salon — tout nœud intermédiaire entre un bloc et une fiche.
    case branche
    /// Une fiche de contenu : feuille de l'arbre.
    case carte
}

/// Un nœud de l'arbre de L'Univers.
///
/// Reflète le résultat de `flatten()` dans univers.js, mais **sans** les champs
/// d'exécution propres à la mise en page radiale (position, échelle, angle…) :
/// ceux-ci vivent dans `UniversStore` (voir le moteur de disposition), pas ici.
/// Ce type est de la donnée pure — construite une fois par `UniversTreeBuilder`,
/// puis partagée en lecture par toutes les vues (carte radiale, fils de bloc…).
public final class UniversNode: Identifiable, Hashable {
    public let id: String
    public let kind: NodeKind
    public let label: String
    public let sousTitre: String?
    public let kanji: String?
    public let icon: String
    public let couleur: String
    /// Message affiché si le nœud est verrouillé (section 18+ non débloquée).
    public let verrou: String?
    /// Message affiché si le salon existe mais n'a encore aucune fiche.
    public let aVenir: String?
    /// La fiche portée par ce nœud — uniquement pour `kind == .carte`.
    public let fiche: Fiche?
    public let depth: Int
    public internal(set) weak var parent: UniversNode?
    public internal(set) var children: [UniversNode] = []

    init(id: String, kind: NodeKind, label: String, sousTitre: String? = nil, kanji: String? = nil,
         icon: String, couleur: String, verrou: String? = nil, aVenir: String? = nil,
         fiche: Fiche? = nil, depth: Int, parent: UniversNode?) {
        self.id = id
        self.kind = kind
        self.label = label
        self.sousTitre = sousTitre
        self.kanji = kanji
        self.icon = icon
        self.couleur = couleur
        self.verrou = verrou
        self.aVenir = aVenir
        self.fiche = fiche
        self.depth = depth
        self.parent = parent
    }

    /// Peut être ouvert (déplié) : a des enfants et n'est pas lui-même une fiche.
    public var peutOuvrir: Bool { kind != .carte && !children.isEmpty }

    /// Vrai si tous les enfants directs sont des fiches (cas d'un salon rempli).
    public var estUnSalonDeFiches: Bool { children.first?.kind == .carte }

    /// Nombre de fiches portées par ce nœud et ses descendants.
    public var leaves: Int {
        kind == .carte ? 1 : children.reduce(0) { $0 + $1.leaves }
    }

    /// Chemin depuis la racine (exclue), du bloc jusqu'au parent direct.
    public var ancetres: [UniversNode] {
        var chain: [UniversNode] = []
        var n = parent
        while let node = n, node.parent != nil {
            chain.insert(node, at: 0)
            n = node.parent
        }
        return chain
    }

    public static func == (lhs: UniversNode, rhs: UniversNode) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Construit l'arbre de L'Univers à partir de la taxonomie (`Carte`) et des
/// fiches actuellement chargées (`ContentRepository`).
///
/// C'est l'équivalent, exécuté au runtime plutôt qu'à la construction du site,
/// de `main()` dans `scripts/construire-univers.py` : regrouper les fiches par
/// salon, marquer « à venir » les salons encore vides, construire les groupes
/// puis les blocs. Comme il tourne à chaque lancement (ou chaque invalidation
/// du contenu), ajouter une fiche à un salon existant la fait apparaître ici
/// sans aucune étape de build séparée.
public enum UniversTreeBuilder {

    public static func build(fiches: [Fiche], carte: [Bloc] = Carte.blocs) -> UniversNode {
        var usedIds = Set<String>()
        func reserve(_ id: String, depth: Int) -> String {
            if usedIds.contains(id) {
                return reserve("\(id)-\(depth)", depth: depth)
            }
            usedIds.insert(id)
            return id
        }

        let parFiche = Dictionary(grouping: fiches, by: \.salon)

        func nœudSalon(_ salon: Salon, couleur: String, depth: Int, parent: UniversNode) -> UniversNode {
            let id = reserve(TextNormalization.slug(salon.nom), depth: depth)
            let items = parFiche[salon.nom] ?? []
            let node = UniversNode(
                id: id, kind: .branche, label: salon.nom, icon: salon.icon, couleur: couleur,
                aVenir: items.isEmpty ? "Salon en préparation : les premières fiches arrivent bientôt." : nil,
                depth: depth, parent: parent
            )
            node.children = items.map { fiche in
                let cardId = reserve(fiche.id.isEmpty ? TextNormalization.slug(fiche.title) : fiche.id, depth: depth + 1)
                return UniversNode(
                    id: cardId, kind: .carte, label: fiche.title, icon: salon.icon, couleur: couleur,
                    fiche: fiche, depth: depth + 1, parent: node
                )
            }
            return node
        }

        func nœudGroupe(_ groupe: Groupe, blocId: String, depth: Int, parent: UniversNode) -> UniversNode {
            let id = reserve(groupe.id, depth: depth)
            let couleur = groupe.couleur ?? blocId
            let node = UniversNode(
                id: id, kind: .branche, label: groupe.label, sousTitre: groupe.sousTitre,
                icon: groupe.icon, couleur: couleur, verrou: groupe.verrou, depth: depth, parent: parent
            )
            if groupe.verrou == nil {
                node.children = groupe.salons.map { nœudSalon($0, couleur: couleur, depth: depth + 1, parent: node) }
            }
            return node
        }

        func nœudBloc(_ bloc: Bloc, depth: Int, parent: UniversNode) -> UniversNode {
            let id = reserve(bloc.id, depth: depth)
            let node = UniversNode(
                id: id, kind: .bloc, label: bloc.label, kanji: bloc.kanji, icon: bloc.icon,
                couleur: bloc.couleur, depth: depth, parent: parent
            )
            let depuisGroupes = bloc.groupes.map { nœudGroupe($0, blocId: bloc.id, depth: depth + 1, parent: node) }
            let depuisSalonsDirects = bloc.salonsDirects.map {
                nœudSalon($0, couleur: bloc.couleur, depth: depth + 1, parent: node)
            }
            node.children = depuisGroupes + depuisSalonsDirects
            return node
        }

        let racine = UniversNode(
            id: reserve("racine", depth: 0), kind: .racine, label: Carte.racineMot,
            sousTitre: Carte.racineSousTitre, icon: "point", couleur: "racine", depth: 0, parent: nil
        )
        racine.children = carte.map { nœudBloc($0, depth: 1, parent: racine) }
        return racine
    }

    /// Visite tous les nœuds de l'arbre (profondeur d'abord), racine incluse.
    public static func walk(_ node: UniversNode, _ visit: (UniversNode) -> Void) {
        visit(node)
        node.children.forEach { walk($0, visit) }
    }
}
