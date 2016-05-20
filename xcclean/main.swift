//
//  xcclean.swift
//  xcclean
//
//  Created by Sascha M Holesch on 2016/04/21.
//  Copyright © 2016年 NTSC. All rights reserved.
//

import Foundation

// MARK: Main

struct XCClean {

    func main() {
        guard Process.arguments.count > 2 else {
            printUsage()
            return
        }
        
        evaluateArguments(Process.arguments)
    }
    
    /**
     Argument evaluation.
     
     - parameter arguments: The array of arguments.
     */
    func evaluateArguments(arguments: [String]) {
        
        guard let dataType = DataType(rawValue: arguments[1]), action = Action(rawValue: arguments[2]) else {
            printUsage()
            return
        }
        
        switch action {
        case .Show:
            showDataForType(dataType)
        case .Delete:
            deleteDataForType(dataType, itemName: arguments[3])
        case .DeleteAll:
            deleteAllDataForType(dataType)
        }
    }

    /**
     Displays the usage explanation.
     */
    func printUsage() {
        print("XCode Cleaner v1.0")
        print("")
        print("Usage: xcclean data_type action item")
        print("")
        print("data_type:")
        print("- \(DataType.DerivedData.rawValue) action")
        print("- \(DataType.DeviceSupport.rawValue) action")
        print("- \(DataType.Archives.rawValue) action")
        print("- \(DataType.Simulators.rawValue) action")
        print("- \(DataType.Documentation.rawValue) action")
        print("")
        print("action:")
        print("- \(Action.Show.rawValue)")
        print("- \(Action.Delete.rawValue)")
        print("- \(Action.DeleteAll.rawValue)")
        print("  Deletes all items available as displayed by the 'show' action")
        print("")
        print("item:")
        print("  The item name as displayed by the 'show' action in the second column")
    }

}

// MARK: Definitions
extension XCClean {
    
    enum DataPath: String {
        case DerivedData = "~/Library/Developer/Xcode/DerivedData/"
        case DeviceSupport = "~/Library/Developer/Xcode/iOS DeviceSupport/"
        case Archives = "~/Library/Developer/Xcode/Archives/"
        case Simulators = "~/Library/Developer/CoreSimulator/Devices/"
        case Documentation = "~/Library/Developer/Shared/Documentation/DocSets/"
    }
    
    enum DataType: String {
        case DerivedData = "derived_data"
        case DeviceSupport = "device_support"
        case Archives = "archives"
        case Simulators = "simulators"
        case Documentation = "documentation"
        
        func associatedPath() -> DataPath {
            switch self {
            case .DerivedData:
                return DataPath.DerivedData
            case .DeviceSupport:
                return DataPath.DeviceSupport
            case .Archives:
                return DataPath.Archives
            case .Simulators:
                return DataPath.Simulators
            case .Documentation:
                return DataPath.Documentation
            }
        }
    }
    
    enum Action: String {
        case Show = "show"
        case Delete = "delete"
        case DeleteAll = "delete_all"
    }

}

// MARK: Helpers

extension XCClean {
    
    /**
     Creates a human readable string of the directory disk usage.
     
     - parameter url: The NSURL for the directory.
     
     - returns: A String containing a human readable disk usage.
     */
    func sizeOfDirectoryAtURL(url: NSURL) -> String {

        // Prepare the enumerator for deep iteration on directories
        let errorHandler: (NSURL, NSError) -> Bool = {
            (url, error) -> Bool in
            print("Error: \(error.localizedDescription)")
            return true
        }

        var bool = ObjCBool(true)
        guard let path = url.path where NSFileManager().fileExistsAtPath(path, isDirectory: &bool),
            let filesEnumerator = NSFileManager.defaultManager().enumeratorAtURL(url, includingPropertiesForKeys: nil, options: [], errorHandler: errorHandler)else {
                return ""
        }
        
        // Iterate over the files to collect their sizes
        var folderFileSizeInBytes = 0
        while let fileURL = filesEnumerator.nextObject() {
            guard let fileURL = fileURL as? NSURL, path = fileURL.path else {
                return ""
            }
            
            do {
                let attributes = try NSFileManager.defaultManager().attributesOfItemAtPath(path)
                if let fileSize = attributes[NSFileSize] as? Int {
                    folderFileSizeInBytes += fileSize.hashValue
                }
            } catch let error as NSError {
                print("Error retrieving file size: \(error.localizedDescription)")
            }
        }
        
        // Format the file size string
        let byteCountFormatter = NSByteCountFormatter()
        byteCountFormatter.allowedUnits = .UseDefault
        byteCountFormatter.countStyle = .File
        return byteCountFormatter.stringFromByteCount(Int64(folderFileSizeInBytes))
    }
    
    /**
     Creates a human readable string of the file disk usage.
     
     - parameter files: The NSURL for the file.
     
     - returns: A String containing a human readable disk usage.
     */
    func sizeOfFiles(files: [NSURL]) -> [String] {
        
        var longestSizeString = 0
        var sizeStrings: [String] = Array()
        
        // Create the array of filesize strings
        for file in files {
            let sizeString = "[\(sizeOfDirectoryAtURL(file))]"
            let length = sizeString.characters.count
            // Remember the longest string
            if length > longestSizeString {
                longestSizeString = length
            }
            sizeStrings.append(sizeString)
        }
        
        // Add prefix spaces for right hand side alignment
        var paddedStrings: [String] = Array()
        for sizeString in sizeStrings {
            let lengthDelta = longestSizeString - sizeString.characters.count
            var tempString = sizeString
            for _ in 0..<lengthDelta {
                tempString = " " + tempString
            }
            paddedStrings.append(tempString)
        }
        return paddedStrings
    }
    
    /**
     Retrieve a files within a directory.
     
     - parameter url:          The NSURL to scan for files.
     - parameter propertyKeys: Optional property keys.
     
     - returns: An array of files.
     */
    func filesAtURL(url: NSURL, propertyKeys: [String]?) -> [NSURL] {
        
        do {
            return try NSFileManager.defaultManager().contentsOfDirectoryAtURL(url, includingPropertiesForKeys: propertyKeys, options: .SkipsHiddenFiles)
        } catch {
            return []
        }
    }
    
}

// MARK: Show Action

extension XCClean {
    
    /**
     Retrieves the name of the archive contained in the directory.
     
     - parameter url: The NSURL to the archive directory.
     
     - returns: Returns a String containing detail information about the archive directory.
     */
    func archiveDetailsForURL(url: NSURL) -> String {
        
        var detailString = "("
        let files = filesAtURL(url, propertyKeys: [NSURLIsDirectoryKey])
        for file in files {
            if let filename = file.lastPathComponent {
                if detailString.characters.count == 1 {
                    detailString += filename
                } else {
                    detailString += "; " + filename
                }
            }
        }
        return detailString + ")"
    }
    
    /**
     Retrieves iOS version and device type for the simulator directory.
     
     - parameter url: The NSURL to the simulator directory.

     - returns: Returns a String containing detail information about the simulator.
     */
    func simulatorDetailsForURL(url: NSURL) -> String {
        
        var detailString = "("
        let files = filesAtURL(url, propertyKeys: [NSURLIsDirectoryKey])
        for file in files {
            if let filename = file.lastPathComponent where filename == "device.plist",
                let dict = NSDictionary(contentsOfURL: file),
                os = dict["runtime"]?.componentsSeparatedByString(".").last,
                deviceType = dict["deviceType"]?.componentsSeparatedByString(".").last?.stringByReplacingOccurrencesOfString("-", withString: " ") {
                detailString += deviceType + ", " + os
            }
        }
        return detailString + ")"
    }
    
    /**
     Prints directory information to the screen.
     
     - parameter dataType: The type of data for with to display information.
     */
    func showDataForType(dataType: DataType) {
        
        let path = dataType.associatedPath()
        let url = NSURL(fileURLWithPath: (path.rawValue as NSString).stringByExpandingTildeInPath, isDirectory: true)
        let files = filesAtURL(url, propertyKeys: nil)
        // Iterate over the directory to gather all file sizes and format them with right alignment
        let itemSizeStrings = sizeOfFiles(files)
        
        for (index, file) in files.enumerate() {
            if let filename = file.lastPathComponent {
                switch path {
                case .Archives:
                    let detailString = archiveDetailsForURL(file)
                    print(itemSizeStrings[index] + " " + filename + " " + detailString)
                case .Simulators:
                    let detailString = simulatorDetailsForURL(file)
                    print(itemSizeStrings[index] + " " + filename + " " + detailString)
                default:
                    print(itemSizeStrings[index] + " " + filename)
                }
            }
        }
    }

}

// MARK: Delete Action

extension XCClean {
    
    /**
     Deletes a specific file.
     
     - parameter url: The NSURL to the file to delete.
     */
    func deleteDataAtUrl(url: NSURL) {
        
        guard let filename = url.lastPathComponent else {
            return
        }
        
        do {
            try NSFileManager.defaultManager().removeItemAtURL(url)
            print("Deleted directory \"\(filename)\"")
        } catch {
            print("Failed to delete directory \"\(filename)\"")
        }
    }
    
    /**
     Deletes all files for a specific data type.
     
     - parameter dataType: The DataType to delete all files for.
     */
    func deleteAllDataForType(dataType: DataType) {
        let directoryURL = NSURL(fileURLWithPath: (dataType.associatedPath().rawValue as NSString).stringByExpandingTildeInPath, isDirectory: true)
        let files = filesAtURL(directoryURL, propertyKeys: [NSURLIsDirectoryKey])
        for file in files {
            var bool = ObjCBool(true)
            if let filePath = file.path where NSFileManager().fileExistsAtPath(filePath, isDirectory: &bool) {
                //print("Delete \(filePath)")
                deleteDataAtUrl(file)
            }
        }
    }
    
    /**
     Deletes a specific file for the specified data type.
     
     - parameter dataType: The DataType to delete files for.
     - parameter itemName: The name of the file to delete.
     */
    func deleteDataForType(dataType: DataType, itemName: String) {
        let directoryURL = NSURL(fileURLWithPath: (dataType.associatedPath().rawValue as NSString).stringByExpandingTildeInPath, isDirectory: true)
        let deletionItemUrl = directoryURL.URLByAppendingPathComponent(itemName, isDirectory: true)
        
        var bool = ObjCBool(true)
        guard let deletionPath = deletionItemUrl.path where NSFileManager().fileExistsAtPath(deletionPath, isDirectory: &bool) else {
            print("The directory \"\(itemName)\" does not exist.")
            return
        }
        
        deleteDataAtUrl(deletionItemUrl)
    }
    
}

// MARK: Entry point

XCClean().main()
