//
//  ViewController.swift
//  GeolocationApp
//
//  Created by Jakub on 12/04/2023.
//

import UIKit
import MapKit



class ViewController: UIViewController, MKMapViewDelegate,CLLocationManagerDelegate  {
    @IBOutlet weak var mapKitView: MKMapView!
    
    

    // wywoływana co update lokalizacji
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.first?.coordinate
        // .coordinate CLLocationCoordinate2D()
        
        // tu Adaś
        let cords = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude:50.06146865220069,
            longitude: 19.93800239600079), latitudinalMeters: 100, longitudinalMeters: 0) //     max_lat/max_long - potestuj w [m]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let lm = CLLocationManager()
        lm.requestAlwaysAuthorization()
        lm.requestWhenInUseAuthorization()
        lm.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        lm.startUpdatingLocation()   // stopUpdatingLocation()

        mapKitView.pointOfInterestFilter = MKPointOfInterestFilter(excluding: [.bank]) // including - widoczne/ukryte warstwy
        mapKitView.showsUserLocation = true
         mapKitView.userTrackingMode = .followWithHeading // .follow
    }


}

