import UIKit
import AVKit
import AVFoundation

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = CameraController()
        window?.makeKeyAndVisible()
        return true
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

final class CameraController: UIViewController, AVPictureInPictureControllerDelegate {
    private let session = AVCaptureSession()
    private let cameraQueue = DispatchQueue(label: "faceguide.camera")
    private let preview = PreviewView()
    private let floatingPreview = PreviewView()
    private let pipContent = AVPictureInPictureVideoCallViewController()
    private var pip: AVPictureInPictureController?
    private var possibleObservation: NSKeyValueObservation?
    private var configured = false
    private var busy = false
    private let status = UILabel()
    private let start = UIButton(type: .system)
    private let floatButton = UIButton(type: .system)
    private let stop = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let title = UILabel()
        title.text = "FaceGuide · Prototype"
        title.font = .preferredFont(forTextStyle: .title1)
        title.adjustsFontForContentSizeCategory = true
        let instructions = UILabel()
        instructions.text = "1. Active la caméra.\n2. Ouvre la fenêtre flottante.\n3. Lance l’enregistrement d’écran dans le Centre de contrôle, avec Microphone activé.\n4. Ouvre l’application à expliquer.\n\nFais d’abord un essai de 15 secondes : vérifie le visage ET la voix dans Photos."
        instructions.numberOfLines = 0
        instructions.font = .preferredFont(forTextStyle: .body)
        status.numberOfLines = 0
        status.text = "Prêt pour un test sur ton iPhone."
        preview.backgroundColor = .secondarySystemBackground
        preview.layer.cornerRadius = 16
        preview.clipsToBounds = true
        preview.heightAnchor.constraint(equalToConstant: 200).isActive = true
        start.setTitle("Activer la caméra", for: .normal)
        start.addTarget(self, action: #selector(startCamera), for: .touchUpInside)
        floatButton.setTitle("Ouvrir la fenêtre selfie", for: .normal)
        floatButton.addTarget(self, action: #selector(openFloating), for: .touchUpInside)
        floatButton.isEnabled = false
        stop.setTitle("Arrêter la caméra", for: .normal)
        stop.addTarget(self, action: #selector(stopCamera), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [title, preview, instructions, start, floatButton, stop, status])
        stack.axis = .vertical
        stack.spacing = 14
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40)
        ])
        preview.previewLayer.session = session
        preview.previewLayer.videoGravity = .resizeAspectFill
        floatingPreview.previewLayer.session = session
        floatingPreview.previewLayer.videoGravity = .resizeAspectFill
        pipContent.preferredContentSize = CGSize(width: 240, height: 320)
        pipContent.view.addSubview(floatingPreview)
        floatingPreview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            floatingPreview.leadingAnchor.constraint(equalTo: pipContent.view.leadingAnchor),
            floatingPreview.trailingAnchor.constraint(equalTo: pipContent.view.trailingAnchor),
            floatingPreview.topAnchor.constraint(equalTo: pipContent.view.topAnchor),
            floatingPreview.bottomAnchor.constraint(equalTo: pipContent.view.bottomAnchor)
        ])
        NotificationCenter.default.addObserver(self, selector: #selector(interrupted), name: AVCaptureSession.wasInterruptedNotification, object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(interrupted), name: AVCaptureSession.runtimeErrorNotification, object: session)
    }

    @objc private func startCamera() {
        guard !busy else { return }
        busy = true
        start.isEnabled = false
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                self.report("Caméra refusée. Autorise FaceGuide dans Réglages → Confidentialité et sécurité → Appareil photo.")
                return
            }
            self.cameraQueue.async {
                do {
                    if !self.configured {
                        self.session.beginConfiguration()
                        defer { self.session.commitConfiguration() }
                        self.session.sessionPreset = .hd1280x720
                        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                            throw Failure.message("Caméra avant indisponible.")
                        }
                        let input = try AVCaptureDeviceInput(device: camera)
                        guard self.session.canAddInput(input) else { throw Failure.message("Impossible d’utiliser la caméra.") }
                        guard self.session.isMultitaskingCameraAccessSupported else {
                            throw Failure.message("iOS ne permet pas la caméra en multitâche pour cette installation. Le prototype ne peut pas continuer.")
                        }
                        self.session.addInput(input)
                        self.session.isMultitaskingCameraAccessEnabled = true
                        self.configured = true
                    }
                    self.session.startRunning()
                    DispatchQueue.main.async {
                        self.busy = false
                        self.start.isEnabled = true
                        self.configurePiP()
                    }
                } catch { self.report(error.localizedDescription) }
            }
        }
    }

    private func configurePiP() {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            status.text = "Fenêtre flottante non prise en charge."
            return
        }
        if pip == nil {
            let source = AVPictureInPictureController.ContentSource(activeVideoCallSourceView: preview, contentViewController: pipContent)
            pip = AVPictureInPictureController(contentSource: source)
            pip?.delegate = self
            pip?.canStartPictureInPictureAutomaticallyFromInline = false
            possibleObservation = pip?.observe(\.isPictureInPicturePossible, options: [.initial, .new]) { [weak self] controller, _ in
                DispatchQueue.main.async {
                    self?.floatButton.isEnabled = controller.isPictureInPicturePossible
                    self?.status.text = controller.isPictureInPicturePossible ? "Caméra prête. Ouvre la fenêtre selfie." : "Caméra active. La fenêtre flottante n’est pas encore disponible."
                }
            }
        } else { floatButton.isEnabled = pip?.isPictureInPicturePossible == true }
    }

    @objc private func openFloating() { pip?.startPictureInPicture() }

    @objc private func stopCamera() {
        pip?.stopPictureInPicture()
        floatButton.isEnabled = false
        cameraQueue.async { self.session.stopRunning() }
        status.text = "Caméra arrêtée. Arrête aussi l’enregistrement d’écran dans le Centre de contrôle."
    }

    @objc private func interrupted(_ notification: Notification) {
        DispatchQueue.main.async {
            self.status.text = "La caméra a été interrompue par iOS. Reviens dans FaceGuide et réactive-la ; vérifie ensuite la vidéo."
            self.floatButton.isEnabled = false
        }
    }

    private func report(_ text: String) {
        DispatchQueue.main.async {
            self.status.text = text
            self.busy = false
            self.start.isEnabled = true
        }
    }

    func pictureInPictureController(_ controller: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        status.text = "Fenêtre selfie indisponible : \(error.localizedDescription)"
    }

    func pictureInPictureController(_ controller: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        completionHandler(viewIfLoaded?.window != nil)
    }

    enum Failure: LocalizedError {
        case message(String)
        var errorDescription: String? { if case .message(let text) = self { return text }; return nil }
    }
}
