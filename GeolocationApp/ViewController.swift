//
//  ViewController.swift
//  GeolocationApp
//
//  Created by Jakub on 12/04/2023.
//

import UIKit
import MapKit
import AVFoundation


class ViewController: UIViewController, MKMapViewDelegate,CLLocationManagerDelegate, UISearchBarDelegate {
    @IBOutlet weak var mapKitView: MKMapView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var lm = CLLocationManager();
    var coordinates = CLLocationCoordinate2D();
    var destination: MapPin?;
    var voiceToUse: AVSpeechSynthesisVoice?;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        mapKitView.frame = self.view.bounds;
        
        lm.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        lm.requestAlwaysAuthorization();
        lm.requestWhenInUseAuthorization();
        lm.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        lm.startUpdatingLocation();   // stopUpdatingLocation()

        mapKitView.pointOfInterestFilter = MKPointOfInterestFilter(excluding: [.bank]); // including - widoczne/ukryte warstwy
        mapKitView.showsUserLocation = true;
        mapKitView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapKitView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: "pin")
//        mkv.userTrackingMode = .followWithHeading
        
        if(lm.location != nil) {
            let cords = MKCoordinateRegion(center: lm.location!.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapKitView.setRegion(cords, animated: true)
        }
        
        for voice in AVSpeechSynthesisVoice.speechVoices() {
            if voice.name == "Zosia" {
                self.voiceToUse = voice
                break
            }
        }
        
        lm.delegate = self;
        mapKitView.delegate = self;
        searchBar.delegate = self;
    }


    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userCoords = locations.first!;
        
        self.coordinates = userCoords.coordinate;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let allAnnotations = self.mapKitView.annotations
        self.mapKitView.removeAnnotations(allAnnotations)
        
        searchBar.endEditing(true);
        
        if(searchBar.text == "") {
            return;
        }
        
        self.mapKitView.removeOverlays(mapKitView.overlays)
        
        let lr = MKLocalSearch.Request()
        lr.naturalLanguageQuery = searchBar.text;
             
        let lS = MKLocalSearch(request: lr)
        lS.start {(response, _) in
            if(response == nil) {
                return
            }
                
            let first = response!.mapItems.first!;
            self.destination = MapPin(title: first.name!, locationName: first.description, coordinate: first.placemark.coordinate, item: first)
            self.generateRoute()
            
            for mapItem in response!.mapItems {
                let pin = MapPin(title: mapItem.name!, locationName: mapItem.description, coordinate: mapItem.placemark.coordinate, item: mapItem)
                self.mapKitView.addAnnotations([pin])
            }
        }
    }
    
    func goAnnotation(mapPin: MapPin) {
        self.destination = mapPin;
        self.generateRoute()
    }
    
    func generateRoute() {
        self.mapKitView.removeOverlays(self.mapKitView.overlays)
        
        let dR = MKDirections.Request()
        dR.source = MKMapItem(placemark: MKPlacemark(coordinate:  mapKitView.userLocation.location!.coordinate))
        dR.destination = self.destination!.item  // z naszego wyszukania MKLocalSearch
        dR.transportType = .walking

        let directions = MKDirections(request: dR)
        directions.calculate { (response, _) in
            for routes in response!.routes {
                for step in routes.steps {
                    let region = CLCircularRegion(center: step.polyline.coordinate, radius: 15, identifier: step.instructions)
                    
                    if(step == routes.steps.first) {
                        let speechSynthesizer = AVSpeechSynthesizer()
                        let speechUtterance = AVSpeechUtterance(string: region.identifier)
                        speechUtterance.voice = self.voiceToUse
                        speechSynthesizer.speak(speechUtterance)
                    }
                    
                    self.lm.startMonitoring(for: region)
                    self.lm.requestState(for: region)
                    
                    self.mapKitView.addOverlay(step.polyline)
                    
                    let circle = MKCircle(center: region.center, radius: region.radius)
                    self.mapKitView.addOverlay(circle)
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        switch overlay {
        case let overlay as MKCircle:
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.lineWidth = 1
            renderer.strokeColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0)
            renderer.fillColor = UIColor(red: 255/255, green: 60/255, blue: 150/255, alpha: 0.3)
            return renderer
            
        case let overlay as MKPolyline:
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.lineWidth = 4
            renderer.strokeColor = UIColor(red: 255/255, green: 60/255, blue: 150/255, alpha: 1.0)
            return renderer
            
        default:
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? MapPin {
                let alert = UIAlertController(title: "Zmiana trasy", message: "Czy chcesz zmienić miejsce docewlowe?", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Tak", style: .default, handler: { action in
                    self.goAnnotation(mapPin: annotation)
                }))
                
                alert.addAction(UIAlertAction(title: "Nie", style: .destructive, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
                
            }
        }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let speechSynthesizer = AVSpeechSynthesizer()
        let speechUtterance = AVSpeechUtterance(string: region.identifier)
        speechUtterance.voice = self.voiceToUse
        speechSynthesizer.speak(speechUtterance)
    }
}


class CustomAnnotationView: MKMarkerAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: "pin")
        glyphImage = UIImage(named: "annotation")   // icon z Assets
        markerTintColor = .black
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MapPin: NSObject, MKAnnotation {
    let title: String?
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    let item: MKMapItem
    init(title: String, locationName: String, coordinate: CLLocationCoordinate2D, item: MKMapItem) {
        self.title = title
        self.locationName = locationName
        self.coordinate = coordinate
        self.item = item
    }
}
