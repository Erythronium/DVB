//
//  DVB.swift
//  Pods
//
//  Created by Kilian Költzsch on 06/05/16.
//
//

import Foundation
import MapKit

/// DVB offers static functions to interact with all the different endpoints.
public class DVB {

    /// List all departures from a given stop
    ///
    /// - parameter stop:       name of the stop
    /// - parameter city:       optional city, defaults to Dresden
    /// - parameter line:       optional filter for returning only departures of a specific line or list of lines
    /// - parameter offset:     optional offset for the time until a departure arrives
    /// - parameter modes:      optional list of allowed modes of transport, defaults to 'normal' things like buses and trams
    /// - parameter completion: handler provided with list of departures and optional error
    public static func departures(_ stop: String, city: String = "", line: [String]? = nil, offset: Int = 0, modes: [TransportMode.Departure] = [], completion: @escaping ([Departure], DVBError?) -> Void) {

        let url = URL.VVO.departures(hst: stop, vz: offset, ort: city, lim: 0, vm: modes).url()

        get(url) { (result) in
            switch result {
            case .failure(let error):
                completion([], error)
            case .success(let json):
                guard let list = json as? [Any] else { completion([], .decode); return }
                var departures = list.map(Departure.init).flatMap {$0}

                // Filter out non-requested lines if line filter is set
                if let line = line {
                    departures = departures.filter { return line.contains($0.line) }
                }

                completion(departures, nil)
            }
        }
    }

    /// A list of all stops in the VVO network
    public static var allVVOStops: [Stop] = {
        let dvbBundle = Bundle(for: DVB.self)

        guard let vvostopsPath = dvbBundle.path(forResource: "VVOStops", ofType: "plist"),
        let allStops = NSArray(contentsOfFile: vvostopsPath) as? [[String:String]] else { return [] }

        return allStops.map(Stop.init(dict:)).flatMap {$0}
    }()

    /// Find a list of stops with a given search string.
    ///
    /// - parameter query:  query
    /// - parameter region: region, defaults to 'Dresden'
    ///
    /// - returns: list of stops that match the query
    public static func find(query: String, region: String = "Dresden") -> [Stop] {
        let query = query.lowercased()
        let foundStops = allVVOStops.filter { stop in
            let match = stop.searchString.lowercased().contains(query) || stop.name.lowercased().contains(query)
            return match && stop.region == region
        }

        return foundStops.sorted { $0.priority > $1.priority }
    }

    /// Find a list of stops with their distance to a set of coordinates in a given radius.
    ///
    /// - Parameters:
    ///   - location: search location
    ///   - radius: search radius in meters, defaults to 1000 (1km)
    /// - Returns: list of stops and their distance from the given coordinates, limited to the search radius
    public static func findNear(location: CLLocation, radius: Double = 1000) -> [(Stop, Double)] {
        return allVVOStops.map { stop in
            guard let loc = stop.location else { return nil }
            let stopLoc = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
            return (stop, location.distance(from: stopLoc))
        }.flatMap {
            $0
        }.filter { tuple in
            tuple.1 <= radius
        }
    }

    /// Find a list of stops with their distance to a set of coordinates in a given radius.
    ///
    /// - Parameters:
    ///   - latitude: latitude of search location
    ///   - longitude: longitude of search location
    ///   - radius: search radius in meters, defaults to 1000 (1km)
    /// - Returns: list of stops and their distance from the given coordinates, limited to the search radius
    public static func findNear(latitude: Double, longitude: Double, radius: Double = 1000) -> [(Stop, Double)] {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        return findNear(location: location, radius: radius)
    }
}
