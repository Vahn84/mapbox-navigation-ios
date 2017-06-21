import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import Mapbox

let sourceIdentifier = "sourceIdentifier"
let layerIdentifier = "layerIdentifier"

class ViewController: UIViewController, MGLMapViewDelegate, NavigationViewControllerDelegate, NavigationMapViewDelegate {
    
    var destination: MGLPointAnnotation?
    var navigation: RouteController?
    var userRoute: Route?
    
    @IBOutlet weak var mapView: NavigationMapView!
    @IBOutlet weak var toolbar: UIToolbar!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
	automaticallyAdjustsScrollViewInsets = false
	mapView.delegate = self
	mapView.navigationMapDelegate = self

	mapView.userTrackingMode = .follow
    }
    
    deinit {
        navigation?.suspendLocationUpdates()
    }
    
    @IBAction func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        
        if let destination = destination {
            mapView.removeAnnotation(destination)
        }
        
	navigationController?.navigationBar.topItem?.title = "Select Navigation Method"

        destination = MGLPointAnnotation()
        destination?.coordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
        mapView.addAnnotation(destination!)
        
	getRoute()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
	if segue.identifier == "CustomUI" {
	    if let customUI = segue.destination as? CustomNavigationUI {
		let camera = mapView.camera
		camera.pitch = 50
		camera.altitude = 600

		customUI.userRoute = userRoute
		customUI.pendingCamera = camera
		customUI.destination = destination!
	    }
	}
    }
    
    @IBAction func didTapSimulateNavigation(_ sender: Any) {
	startNavigation(along: userRoute!, simulatesLocationUpdates: true)
    }
    
    func getRoute(didFinish: (()->())? = nil) {
        guard let destination = destination else { return }
        
        let options = RouteOptions(coordinates: [mapView.userLocation!.coordinate, destination.coordinate])
        options.includesSteps = true
        options.routeShapeResolution = .full
        options.profileIdentifier = .automobileAvoidingTraffic
        
        _ = Directions.shared.calculate(options) { [weak self] (waypoints, routes, error) in
            guard error == nil else {
                print(error!)
                return
            }
            guard let route = routes?.first else {
                return
	    }

	    self?.userRoute = route
	    self?.toolbar.isHidden = false

	    // Open method for adding and updating the route line
	    self?.mapView.showRoute(route)
            
            didFinish?()
        }
    }
    
    func startNavigation(along route: Route, simulatesLocationUpdates: Bool = false) {
        // Pass through:
        // 1. The route the user will take.
        // 2. A `Directions` object, used for rerouting.
        let navigationViewController = NavigationViewController(for: route)
        
        // If you'd like to use AWS Polly, provide your IdentityPoolId below.
        // `identityPoolId` is a required value for using AWS Polly voice instead of iOS's built in AVSpeechSynthesizer.
        // You can get a token here: http://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth-aws-identity-for-ios.html
        //navigationViewController.voiceController?.identityPoolId = "<#Your AWS IdentityPoolId. Remove Argument if you do not want to use AWS Polly#>"
        
        navigationViewController.simulatesLocationUpdates = simulatesLocationUpdates
        navigationViewController.routeController.snapsUserLocationAnnotationToRoute = true
        navigationViewController.voiceController?.volume = 0.5
        navigationViewController.navigationDelegate = self
        
        // Uncomment to apply custom styles
//        styleForRegular().apply()
//        styleForCompact().apply()
//        styleForiPad().apply()
//        styleForCarPlay().apply()
        
        let camera = mapView.camera
        camera.pitch = 45
        camera.altitude = 600
        if let userLocation = mapView.userLocation {
            camera.centerCoordinate = userLocation.coordinate
            if let location = userLocation.location {
                camera.heading = location.course
            }
        }
        navigationViewController.pendingCamera = camera
        
        present(navigationViewController, animated: true, completion: nil)
    }
    
    func styleForRegular() -> Style {
        let trait = UITraitCollection(verticalSizeClass: .regular)
        let style = Style(traitCollection: trait)
        
        // General styling
        style.tintColor = #colorLiteral(red: 0.9418798089, green: 0.3469682932, blue: 0.5911870599, alpha: 1)
        style.primaryTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        style.secondaryTextColor = #colorLiteral(red: 0.9626983484, green: 0.9626983484, blue: 0.9626983484, alpha: 1)
        style.buttonTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        style.wayNameTextColor = #colorLiteral(red: 0.9418798089, green: 0.3469682932, blue: 0.5911870599, alpha: 1)    

        // Maneuver view (Page view)
        style.maneuverViewBackgroundColor = #colorLiteral(red: 0.2974345386, green: 0.4338284135, blue: 0.9865127206, alpha: 1)
        style.maneuverViewHeight = 100
        
        // Table view (Drawer)
        style.headerBackgroundColor = #colorLiteral(red: 0.2974345386, green: 0.4338284135, blue: 0.9865127206, alpha: 1)
        style.cellTitleLabelTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        style.cellSubtitleLabelTextColor = #colorLiteral(red: 0.9626983484, green: 0.9626983484, blue: 0.9626983484, alpha: 1)
        style.cellTitleLabelFont = UIFont.preferredFont(forTextStyle: .headline)
        style.cellSubtitleLabelFont = UIFont.preferredFont(forTextStyle: .footnote)
        
        return style
    }
    
    func styleForCompact() -> Style {
        let horizontal = UITraitCollection(horizontalSizeClass: .compact)
        let vertical = UITraitCollection(verticalSizeClass: .compact)
        let traitCollection = UITraitCollection(traitsFrom: [horizontal, vertical])
        let style = Style(traitCollection: traitCollection)
        
        // General styling
        style.tintColor = #colorLiteral(red: 0.2974345386, green: 0.4338284135, blue: 0.9865127206, alpha: 1)
        style.primaryTextColor = .black
        style.secondaryTextColor = .gray
        style.buttonTextColor = .black
        
        // Maneuver view (Page view)
        style.maneuverViewBackgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        style.maneuverViewHeight = 70
        
        // Table view (Drawer)
        style.headerBackgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        style.primaryTextColor = .black
        style.secondaryTextColor = .gray
        style.cellTitleLabelTextColor = .black
        style.cellSubtitleLabelTextColor = .gray
        style.cellTitleLabelFont = .preferredFont(forTextStyle: .headline)
        style.cellSubtitleLabelFont = .preferredFont(forTextStyle: .footnote)
        
        return style
    }
    
    func styleForiPad() -> Style {
        let style = Style(traitCollection: UITraitCollection(userInterfaceIdiom: .pad))
        style.maneuverViewHeight = 100
        return style
    }
    
    func styleForCarPlay() -> Style {
        let style = Style(traitCollection: UITraitCollection(userInterfaceIdiom: .carPlay))
        style.maneuverViewHeight = 40
        return style
    }
    
    /// Delegate method for changing the route line style
    func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        let lineCasing = MGLLineStyleLayer(identifier: identifier, source: source)
        
        lineCasing.lineColor = MGLStyleValue(rawValue: UIColor(red:0.00, green:0.70, blue:0.99, alpha:1.0))
        lineCasing.lineWidth = MGLStyleValue(rawValue: 6)
        
        lineCasing.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        lineCasing.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        return lineCasing
    }
    
    /// Delegate method for changing the route line casing style
    func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        let line = MGLLineStyleLayer(identifier: identifier, source: source)
        
        line.lineColor = MGLStyleValue(rawValue: UIColor(red:0.18, green:0.49, blue:0.78, alpha:1.0))
        line.lineWidth = MGLStyleValue(rawValue: 8)
        
        line.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        line.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        return line
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt destination: MGLAnnotation) {
        print("User arrived at \(destination)")
    }
}
