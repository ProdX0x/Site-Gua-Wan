import SwiftUI
import RealityKit
import GuaWanCore

/// L'espace immersif de « L'Univers » : les mêmes blocs/groupes/fiches que la
/// carte plate (`UniversMapView`), mais disposés en vraies strates spatiales
/// — chaque palier de profondeur de l'arbre (bloc → branche → fiche) est
/// poussé un peu plus loin devant la personne (voir `UniversImmersiveModel`)
/// — plutôt qu'une carte plate simplement posée dans l'espace.
///
/// Reconstruit son contenu RealityKit à chaque changement d'état du store
/// (ouverture/fermeture d'une bulle, fin de chargement) dans la fermeture
/// `update` de `RealityView` ; les bulles et étiquettes déjà présentes sont
/// repositionnées plutôt que recréées (identité stable), les liens sont bon
/// marché à reconstruire entièrement à chaque passage.
struct UniversImmersiveSpace: View {
    @State private var model = UniversImmersiveModel()
    @Environment(\.openWindow) private var openWindow

    /// Bulles et étiquettes déjà posées dans la scène, par identifiant de
    /// nœud — pour les repositionner plutôt que les recréer à chaque mise à
    /// jour (RealityKit n'a pas d'équivalent du diffing de liste de SwiftUI).
    @State private var bullesParNoeud: [String: Entity] = [:]
    @State private var etiquettesParNoeud: [String: Entity] = [:]
    /// Conteneur unique pour les liens parent → enfant : entièrement
    /// reconstruit à chaque passage (peu coûteux, peu de liens à la fois),
    /// voir `reconstruireLiens`.
    @State private var liensRacine = Entity()

    var body: some View {
        RealityView { content in
            content.add(liensRacine)
            reconstruire(dans: content)
        } update: { content in
            reconstruire(dans: content)
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { valeur in
                    gererTap(surEntite: valeur.entity)
                }
        )
        .overlay(alignment: .top) {
            if model.store.isLoading {
                Text("Chargement de L'Univers…")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 40)
            }
        }
        .task {
            await model.store.load()
            model.store.setInitialOpen(wide: true)
        }
    }

    // MARK: - Construction / mise à jour de la scène

    private func reconstruire(dans content: RealityViewContent) {
        let visibles = model.store.tousLesNoeuds.filter { model.store.position(of: $0).visible }
        let idsVisibles = Set(visibles.map(\.id))

        // Retire les bulles/étiquettes des nœuds qui se sont repliés.
        // (on copie les clés dans un tableau avant de muter les dictionnaires
        // pendant la boucle : itérer directement sur `.keys` en mutant le
        // dictionnaire sous-jacent n'est pas permis.)
        for id in Array(bullesParNoeud.keys) where !idsVisibles.contains(id) {
            bullesParNoeud[id]?.removeFromParent()
            bullesParNoeud.removeValue(forKey: id)
        }
        for id in Array(etiquettesParNoeud.keys) where !idsVisibles.contains(id) {
            etiquettesParNoeud[id]?.removeFromParent()
            etiquettesParNoeud.removeValue(forKey: id)
        }

        for noeud in visibles {
            let position = model.position3D(for: noeud)
            let taille = model.taille3D(for: noeud)

            if let bulle = bullesParNoeud[noeud.id] {
                bulle.position = position
            } else {
                let bulle = creerBulle(pour: noeud, taille: taille)
                bulle.position = position
                content.add(bulle)
                bullesParNoeud[noeud.id] = bulle
            }

            let positionEtiquette = position + SIMD3<Float>(0, taille / 2 + 0.035, 0)
            if let etiquette = etiquettesParNoeud[noeud.id] {
                etiquette.position = positionEtiquette
            } else {
                let etiquette = creerEtiquette(pour: noeud)
                etiquette.position = positionEtiquette
                content.add(etiquette)
                etiquettesParNoeud[noeud.id] = etiquette
            }
        }

        reconstruireLiens(visibles: visibles, idsVisibles: idsVisibles)
    }

    /// Un lien par nœud visible ayant un parent visible, matérialisé par un
    /// petit chapelet de perles entre les deux centres — volontairement plus
    /// simple qu'un cylindre orienté (pas de calcul de rotation à vérifier
    /// sans compilateur) : l'essentiel est la disposition spatiale des
    /// bulles, pas la fidélité du tracé.
    private func reconstruireLiens(visibles: [UniversNode], idsVisibles: Set<String>) {
        for enfant in Array(liensRacine.children) {
            enfant.removeFromParent()
        }
        for noeud in visibles {
            guard let parent = noeud.parent, idsVisibles.contains(parent.id) else { continue }
            let a = model.position3D(for: parent)
            let b = model.position3D(for: noeud)
            liensRacine.addChild(creerLien(de: a, vers: b, couleur: noeud.couleur))
        }
    }

    // MARK: - Fabrique d'entités

    private func creerBulle(pour noeud: UniversNode, taille: Float) -> Entity {
        let couleur = UniversImmersiveColor.couleur(nommee: noeud.couleur)
        let material = SimpleMaterial(color: couleur, roughness: 0.55, isMetallic: false)

        let mesh: MeshResource
        let forme: ShapeResource
        if noeud.kind == .carte {
            // Boîte à coins arrondis pour une fiche : la distingue visuellement
            // des sphères (racine/bloc/branche) sans ajouter de risque — même
            // famille d'API (`generateBox`/`generateSphere`) que les sphères.
            let profondeur = taille * 0.12
            mesh = .generateBox(width: taille, height: taille * 0.72, depth: profondeur, cornerRadius: taille * 0.16)
            forme = .generateBox(width: taille, height: taille * 0.72, depth: profondeur)
        } else {
            mesh = .generateSphere(radius: taille / 2)
            forme = .generateSphere(radius: taille / 2)
        }

        let entite = ModelEntity(mesh: mesh, materials: [material])
        entite.name = noeud.id
        entite.components.set(CollisionComponent(shapes: [forme]))
        entite.components.set(InputTargetComponent())
        entite.components.set(HoverEffectComponent())
        return entite
    }

    /// Étiquette en texte 3D plutôt qu'un attachment SwiftUI projeté : signature
    /// plus ancienne et plus sûre à écrire sans compilateur sous la main (voir
    /// le rapport final sur les API RealityKit à vérifier malgré tout).
    private func creerEtiquette(pour noeud: UniversNode) -> Entity {
        let texte = noeud.kind == .carte ? (noeud.fiche?.shortTitle ?? noeud.label) : noeud.label
        let hauteurLettre: Float = switch noeud.kind {
        case .racine: 0.065
        case .bloc: 0.05
        case .branche: 0.038
        case .carte: 0.032
        }
        let mesh = MeshResource.generateText(
            texte,
            extrusionDepth: 0.0008,
            font: .systemFont(ofSize: CGFloat(hauteurLettre)),
            containerFrame: CGRect(x: -0.5, y: -0.15, width: 1.0, height: 0.3),
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        let material = UnlitMaterial(color: .white)
        let entite = ModelEntity(mesh: mesh, materials: [material])
        // Fait toujours face à la personne, quelle que soit sa position dans
        // l'espace (voir le rapport final : composant à vérifier à l'usage).
        entite.components.set(BillboardComponent())
        return entite
    }

    /// Un chapelet de petites perles entre deux points — reflet très
    /// simplifié des liens courbes de la carte plate (`UniversLinkLayer`).
    private func creerLien(de a: SIMD3<Float>, vers b: SIMD3<Float>, couleur nomCouleur: String) -> Entity {
        let conteneur = Entity()
        let nombrePerles = 6
        let mesh = MeshResource.generateSphere(radius: 0.006)
        let teinte = UniversImmersiveColor.couleur(nommee: nomCouleur).withAlphaComponent(0.5)
        let material = SimpleMaterial(color: teinte, roughness: 1.0, isMetallic: false)
        for i in 1...nombrePerles {
            let t = Float(i) / Float(nombrePerles + 1)
            let perle = ModelEntity(mesh: mesh, materials: [material])
            perle.position = a + (b - a) * t
            conteneur.addChild(perle)
        }
        return conteneur
    }

    // MARK: - Interaction

    /// Retrouve le `UniversNode` nommé sur l'entité tapée (ou l'un de ses
    /// parents, au cas où le rayon touche un sous-maillage) et reproduit
    /// `gererTap()` de `UniversMapView` : ouvre une fenêtre pour une fiche,
    /// ou déplie/replie une branche.
    private func gererTap(surEntite entite: Entity) {
        var courante: Entity? = entite
        while let e = courante {
            if !e.name.isEmpty, let noeud = model.store.node(id: e.name) {
                gererTap(surNoeud: noeud)
                return
            }
            courante = e.parent
        }
    }

    private func gererTap(surNoeud noeud: UniversNode) {
        if noeud.kind == .carte, let fiche = noeud.fiche {
            openWindow(value: fiche)
        } else if noeud.verrou != nil || noeud.aVenir != nil {
            // Pas de toast en immersif pour cette première passe : la bulle
            // reste simplement inerte (voir le rapport final).
            return
        } else {
            model.store.toggle(noeud)
        }
    }
}
