//
//  ViewController.swift
//  BugOut2
//
//  Created by Danny Peng on 10/1/16.
//  Copyright © 2016 Danny Peng. All rights reserved.
//


import UIKit
import MapKit
import Social
import GoogleMaps

class Destination: NSObject, NSCoding{
    let name: String
    let location: CLLocationCoordinate2D
    let zoom: Float
    
    struct PropertyKey {
        static let nameKey = "name"
        static let locationKey = "location"
        static let zoomKey = "zoom"
    }
    
    init(name: String, location: CLLocationCoordinate2D, zoom: Float) {
        self.name = name
        self.location = location
        self.zoom = zoom
        
        super.init()
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.nameKey)
        aCoder.encode(location, forKey: PropertyKey.locationKey)
        aCoder.encode(zoom, forKey: PropertyKey.zoomKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: PropertyKey.nameKey) as! String
        
        // Because photo is an optional property of Meal, use conditional cast.
        let location = aDecoder.decodeObject(forKey: PropertyKey.locationKey) as? CLLocationCoordinate2D
        
        let zoom = aDecoder.decodeFloat(forKey: PropertyKey.zoomKey)
        
        // Must call designated initializer.
        self.init(name: name, location: location!, zoom: zoom)
    }
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("destinations")
}

class ViewController: UIViewController , CLLocationManagerDelegate, UITextFieldDelegate{
    
    
    var mapView: GMSMapView?
    let locationManager = CLLocationManager()

    var currentLocation = CLLocationCoordinate2D()
    
    var currentDestination: Destination?
    var apiKey = "AIzaSyASBDtGdqU0gizz73LbZ10i2t7ZZ9kk9DI"
    
    var defaults = UserDefaults.standard
    var destinations = [Destination]()
    

    
    @IBOutlet weak var addDest: UITextField!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        if let savedPlaces = loadPlaces() {
//            destinations += savedPlaces
//        } 

       
        GMSServices.provideAPIKey(
            apiKey)
        
        
        
        //savePlaces()
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        var startLat: Double
        var startLong: Double
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            startLat = locationManager.location!.coordinate.latitude
            startLong = locationManager.location!.coordinate.longitude
            
        } else {
            
            startLat = 32.8853
            startLong = -117.2391
        }
        
        
        currentLocation = CLLocationCoordinate2DMake(startLat, startLong)
        
        
        let camera = GMSCameraPosition.camera(withLatitude: currentLocation.latitude, longitude: currentLocation.longitude, zoom: 12)
        mapView = GMSMapView.map(withFrame: CGRect.init(x: 0.0, y: view!.frame.size.height * 0.2, width: view!.frame.size.width, height: view!.frame.size.height * 0.8), camera: camera)
        view.addSubview(mapView!)
        
        
      
      
        
        let marker = GMSMarker(position: currentLocation)
        marker.title = "Current Location"
        marker.map = mapView
        

        if destinations.count > 0
        {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: "next")
        }
        
        addDest.delegate = self

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
//        UserDefaults.standard.set(destinations, forKey: "destinations")
//        UserDefaults.standard.synchronize()
        
//        if let destination = UserDefaults.standard.object(forKey: "destinations") {
//            print("We saved Destinations \(destination)")
//        }
        savePlaces(inc: destinations)
        loadPlaces()
        print("THIS IS REACHED\(destinations.count)")
        
    }
    
    func reParsePath(dest: String) -> String {
        let origin = "\(currentLocation.latitude)" + "," + "\(currentLocation.longitude)"
        
        var toInput = getJSON(urlToRequest:"https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(dest)&key=AIzaSyASBDtGdqU0gizz73LbZ10i2t7ZZ9kk9DI")

        
        let step1 = parseJSON(inputData: toInput)
        let step2 = step1["routes"] as! NSArray
        let step3 = step2[0] as! NSDictionary
        let step4 = step3["overview_polyline"] as! NSDictionary
        let step5 = step4["points"]
return step5 as! String
    }
    
    
    func next() {
        
        if currentDestination == nil {
            currentDestination = destinations.first
            setMapCamera()
            
        } else {
            if let index = destinations.index(of: currentDestination!) {
                currentDestination = destinations[index+1]
                
                mapView?.animate(to: GMSCameraPosition.camera(withTarget: currentDestination!.location, zoom: currentDestination!.zoom))
                
                
                
            }
            
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Prev", style: .plain, target: self, action: "prev")

        
        if destinations.index(of: currentDestination!) == destinations.count-1 {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    func prev() {
        
        if destinations.index(of:currentDestination!) == 0 {
           
            
            mapView?.animate(to: GMSCameraPosition.camera(withTarget: currentLocation, zoom: currentDestination!.zoom))

            let marker = GMSMarker(position: currentLocation)
            marker.title = "Current Location"
            marker.map = mapView
            
            currentDestination = nil
            
            navigationItem.leftBarButtonItem = nil
            
            
            
        } else {
            if let index = destinations.index(of: currentDestination!) {
                currentDestination = destinations[index-1]
                
                mapView?.animate(to: GMSCameraPosition.camera(withTarget: currentDestination!.location, zoom: currentDestination!.zoom))
                
                
                
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: "next")
            }
            
        }

        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: "next")
        
    }
    func getJSON(urlToRequest: String) -> NSData {
        var gold = NSData(contentsOf: (NSURL(string: urlToRequest) as? URL)!)
        if gold != nil {
            return gold!
        }
        else {
            return NSData()
        }
    }
    
    func parseJSON(inputData: NSData) -> NSDictionary {
        var error: NSError?
        var temp = NSDictionary()
        do{
        var boardsDictionary: NSDictionary = try JSONSerialization.jsonObject(with: inputData as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
            temp = boardsDictionary
            //print(boardsDictionary)
            return boardsDictionary
        }
        catch {
            print(error)
            return temp
        }
        
    }
    
    private func setMapCamera() {
        CATransaction.begin()
        CATransaction.setValue(2, forKey: kCATransactionAnimationDuration)
        mapView?.animate(to: GMSCameraPosition.camera(withTarget: currentDestination!.location, zoom: currentDestination!.zoom))
        CATransaction.commit()
        
        let marker = GMSMarker(position: currentDestination!.location)
        marker.title = currentDestination?.name
        marker.map = mapView
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    func loc() -> CLLocationCoordinate2D
    {
        if currentDestination == nil
        {
            return currentLocation
        }
        else {
            return currentDestination!.location
        }
    }
    
    func toText(entry: String) -> String
    {
        
        let replaced = String(entry.characters.map {
            $0 == " " ? "+" : $0
        })
        
        return replaced
    }
    
    func screenShotMethod() {
        //Create the UIImage
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        //Save it to the camera roll
        UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil)
    }
    
    @IBAction func BugOut(_ sender: AnyObject) {
        screenShotMethod()
    }
    
    
    
    @IBAction func addDestination(_ sender: AnyObject) {
        
        
        let origin = "\(currentLocation.latitude)" + "," + "\(currentLocation.longitude)"
        
        let dest = addDest.text
        
        connect(origin: toText(entry: origin), dest: toText(entry:dest!))
        
        addDest.text = ""
        loadPlaces()
        
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    @IBAction func pop(_ sender: UITextField) {
        mapView?.isHidden=true
    }
    
    @IBAction func restoreMap(_ sender: AnyObject) {
        mapView?.isHidden = false

    }
    
    
    func connect(origin: String, dest: String){
        
        var toInput = getJSON(urlToRequest:"https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(dest)&key=AIzaSyASBDtGdqU0gizz73LbZ10i2t7ZZ9kk9DI")
        let step1 = parseJSON(inputData: toInput)
        let step2 = step1["routes"] as! NSArray
        let step3 = step2[0] as! NSDictionary
        let step4 = step3["legs"] as! NSArray
        let step5 = step4[0] as! NSDictionary
        let step6 = step5["end_location"] as! NSDictionary

        let pCityLat = step6["lat"]!
        print(pCityLat)
        let pCityLng = step6["lng"]!
        print(pCityLng)
        
        destinations.append(Destination(name: dest, location: CLLocationCoordinate2DMake(pCityLat as! CLLocationDegrees, pCityLng as! CLLocationDegrees), zoom: 12))
        let marker = GMSMarker(position: destinations.last!.location)
        marker.title = destinations.last?.name
        marker.map = mapView
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: "next")
        
        var Hello = GMSPath.init(fromEncodedPath: reParsePath(dest:dest))
        var World = GMSPolyline(path: Hello)
        World.map = mapView
        
    }
    
    func savePlaces(inc: [Destination]) {
        UserDefaults.standard.set(inc, forKey: "destinations")
        UserDefaults.standard.synchronize()
    }
    
    func loadPlaces() ->[Destination] {
        if let destination = UserDefaults.standard.object(forKey: "destinations") {
            print("We saved Destinations \(destination)")
            return destination as! [Destination]
        }
        return destinations
    }
    
//   func savePlaces() {
//        
//        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(destinations, toFile: Destination.ArchiveURL.path)
//
//        if !isSuccessfulSave {
//            print("Failed ...")
//        }
//    }
    
    
//    func loadPlaces() -> [Destination]? {
//        return NSKeyedUnarchiver.unarchiveObject(withFile: Destination.ArchiveURL.path) as? [Destination]
//    }

    
}
