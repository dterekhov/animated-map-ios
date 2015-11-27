//
//  ViewController.swift
//  AnimatedMap
//
//  Created by Dmitry Terekhov on 11/27/15.
//  Copyright © 2015 Education. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    // MARK: Members
    private struct Constants {
        static let AppName = "Animated Map"
        static let AlertTitleRemove = "Remove places"
        static let AlertTitleMessage = "All places are empty. Make long Tap on map to add."
        static let TableHeight: CGFloat = 220
        static let TableCellIdentifier = "PlaceCell"
    }
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
            mapView.mapType = .Standard
            mapView.showsUserLocation = true
        }
    }
    
    private lazy var locationManager: CLLocationManager = {
        let lazilyCreatedManager = CLLocationManager()
        lazilyCreatedManager.delegate = self
        lazilyCreatedManager.desiredAccuracy = kCLLocationAccuracyBest
        lazilyCreatedManager.requestAlwaysAuthorization()
        return lazilyCreatedManager
    }()
    
    private var isZoomedToUserAtFirstTime = true
    
    private var places = [MKPointAnnotation]()
    
    @IBOutlet weak var placesTableView: UITableView!
    @IBOutlet weak var topTableConstraint: NSLayoutConstraint!
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = Constants.AppName
        setupUI()
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.startUpdatingLocation()
        }
    }
    
    private func setupUI() {
        topTableConstraint.constant = -Constants.TableHeight
    }
    
    // MARK: - CLLocationManagerDelegate
    
    // Zoom to current user's location when device detect position
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last where isZoomedToUserAtFirstTime {
            isZoomedToUserAtFirstTime = false
            zoomInToCoordinate(location.coordinate)
        }
    }
    
    // MARK: - TableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.TableCellIdentifier) as UITableViewCell!
        let place = places[indexPath.row]
        cell.textLabel?.text = place.title
        cell.detailTextLabel?.text = String(format:"Latitude: %d, Longitude: %d", place.coordinate.latitude, place.coordinate.longitude)
        return cell
    }
    
    // MARK: - User interaction
    @IBAction func resetCurrentLocationButtonTap() {
        zoomInToCoordinate(mapView.userLocation.coordinate)
    }
    
    @IBAction func longGestureHandle(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state != .Began { return }
        let touchPoint = recognizer.locationInView(mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let placeName = "Place #" + "\(places.count + 1)"
        let annotation = MKPointAnnotation()
        annotation.title = placeName
        annotation.subtitle = "Description for " + placeName
        annotation.coordinate = touchMapCoordinate
        places.append(annotation)
        mapView.addAnnotation(annotation)
        placesTableView.reloadData()
    }
    
    @IBAction func removeAllPlaces(sender: UIBarButtonItem) {
        // Cannot to Remove
        if places.count == 0 {
            let alertController = UIAlertController(title: Constants.AlertTitleRemove, message: Constants.AlertTitleMessage, preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            presentViewController(alertController, animated: true, completion: nil)
            return
        }
        
        // Removing
        let alertController = UIAlertController(title: Constants.AlertTitleRemove, message: "Are you shure to remove all added places?", preferredStyle: UIAlertControllerStyle.Alert)
        let removeAction = UIAlertAction(title: "Remove", style: .Destructive) { alertAction -> Void in
            self.mapView.removeAnnotations(self.places) // Remove from UI
            self.places.removeAll() // Remove from Model
            self.placesTableView.reloadData()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(removeAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func showPlacesButtonTap(sender: UIBarButtonItem) {
        // Cannot show empty tableView
        if places.count == 0 {
            let alertController = UIAlertController(title: "Added places", message: Constants.AlertTitleMessage, preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
            alertController.addAction(cancelAction)
            presentViewController(alertController, animated: true, completion: nil)
            return
        }
        
        let tableIsVisibleConstant = (mapView.frame.height - Constants.TableHeight) / 2
        let tableIsHiddenConstant = -Constants.TableHeight
        let isTableHidden = topTableConstraint.constant == tableIsHiddenConstant
        
        // Animate moving and opacity of tableView
        placesTableView.alpha = isTableHidden ? 0 : 1
        topTableConstraint.constant = isTableHidden ? tableIsVisibleConstant : tableIsHiddenConstant
        UIView.animateWithDuration(0.3) {
            self.placesTableView.alpha = isTableHidden ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Helpers
    private func zoomInToCoordinate(coordinate: CLLocationCoordinate2D) {
        let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
    }
}