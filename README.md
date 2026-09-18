# FaceGuide — prototype expérimental pour iPhone

Ce projet teste une caméra selfie en fenêtre flottante, utilisée avec l’enregistrement d’écran intégré à iOS. Il ne constitue pas une application terminée : ni la compilation sur Xcode ni l’enregistrement sur un iPhone réel n’ont encore été exécutés. Aucun fichier IPA installable n’est fourni dans les sources.

## Ce que le prototype doit vérifier

- La caméra reste active quand on ouvre une autre application.
- La fenêtre selfie apparaît dans la vidéo enregistrée par iOS.
- La voix est enregistrée avec le microphone du Centre de contrôle.
- La combinaison fonctionne sur l’iPhone de l’utilisateur, qui indique iOS 26.6.2.

Si l’un de ces points échoue, ce prototype ne répond pas au besoin. Une capture ReplayKit et une composition séparée peuvent devenir nécessaires ; elles ne sont pas implémentées ici. Le prototype ne capture pas lui-même de vidéo et n’annonce jamais qu’un enregistrement est démarré.

## Compilation sans posséder de Mac

1. Créer un dépôt GitHub et placer le contenu de ce dossier à sa racine, y compris `.github/workflows/build.yml`.
2. Pour éviter les frais de calcul, utiliser un dépôt public et le runner standard prévu par le workflow. Les sources seront publiques : ne pas y placer de secrets ou de vidéos personnelles. Les règles GitHub de compte, de stockage et de quotas restent applicables.
3. Dans Actions, choisir « Compiler le prototype iPhone », puis « Run workflow ».
4. Après une compilation réussie, télécharger l’artefact `FaceGuide-unsigned`.

GitHub fournit ici le Mac de compilation à distance. Docker Desktop ne compile pas ce projet iOS. Aucun compte Apple ni certificat n’est envoyé à GitHub. Le workflow doit encore être exécuté et peut demander des ajustements selon les outils disponibles.

## Installation personnelle depuis Windows

L’IPA produite est NON SIGNÉE : Safari ne peut pas l’installer. Il faut la signer avec son propre compte Apple au moyen d’un outil d’installation personnelle, par exemple AltStore Classic/AltServer, et suivre sa documentation Windows. Ne pas transmettre son mot de passe Apple dans une conversation ou dans le dépôt.

Documentation : https://faq.altstore.io/altstore-classic/altserver

Avec le provisionnement gratuit Apple, les profils expirent après 7 jours. AltServer doit pouvoir contacter l’iPhone pour renouveler l’installation, normalement sur le même réseau local ou par USB. Un PC allumé à domicile ne garantit pas un renouvellement à distance. Après installation, le test ne nécessite ni serveur ni réseau, tant que la signature est valide.

## Test indispensable sur iPhone

1. Ouvrir FaceGuide et autoriser la caméra.
2. Appuyer sur « Activer la caméra », puis « Ouvrir la fenêtre selfie ».
3. Dans le Centre de contrôle, maintenir Enregistrement d’écran, activer Microphone, puis commencer.
4. Ouvrir Réglages, naviguer et parler pendant 15 secondes.
5. Arrêter l’enregistrement ; lire la vidéo dans Photos. Vérifier visage en mouvement, navigation et voix.
6. Refaire un essai en mode avion, puis un essai de plusieurs minutes. Vérifier les interruptions, le son et la chauffe avant tout usage réel.

Le microphone est géré par iOS ; l’application ne crée volontairement aucune capture audio concurrente. Les appels, le verrouillage et certaines applications peuvent interrompre ou limiter la capture. Arrêter séparément la caméra et l’enregistrement système à la fin.

## Restriction technique à examiner

L’accès caméra multitâche documenté par Apple depuis iOS 18 dépend notamment du mode d’arrière-plan `voip`. Le prototype déclare ce mode et vérifie à l’exécution `isMultitaskingCameraAccessSupported`. Il utilise la fenêtre PiP prévue pour les appels vidéo. Ce n’est pas une garantie qu’Apple autorisera la distribution d’un enregistreur utilisant ce mécanisme : ce prototype n’est pas prêt à être soumis à l’App Store, et ne simule aucun appel pour forcer son exécution.

Sources :
- https://developer.apple.com/documentation/avfoundation/avcapturesession/ismultitaskingcameraaccesssupported
- https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.avfoundation.multitasking-camera-access
- https://developer.apple.com/help/account/basics/about-your-developer-account
- https://docs.github.com/en/actions/concepts/billing-and-usage

## État de livraison

Sources Swift, configuration XcodeGen et workflow de compilation fournis. Pas de serveur, pas de dépendance logicielle de l’application, pas de collecte réseau. Relecture statique uniquement ; validation de compilation et test matériel encore nécessaires.
