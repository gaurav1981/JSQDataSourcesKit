//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQDataSourcesKit
//
//
//  GitHub
//  https://github.com/jessesquires/JSQDataSourcesKit
//
//
//  License
//  Copyright (c) 2015 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

import Foundation
import UIKit
import CoreData


public protocol TableViewCellFactoryType {

    typealias DataItem
    typealias Cell: UITableViewCell

    func cellForItem(item: DataItem, inTableView tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> Cell

    func configureCell(cell: Cell, forItem item: DataItem, inTableView tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> Cell

}


public struct TableViewCellFactory <Cell: UITableViewCell, DataItem>: TableViewCellFactoryType {

    typealias CellConfigurationHandler = (Cell, DataItem, UITableView, NSIndexPath) -> Cell

    private let reuseIdentifier: String

    private let cellConfigurator: CellConfigurationHandler

    public init(reuseIdentifier: String, cellConfigurator: CellConfigurationHandler) {
        self.reuseIdentifier = reuseIdentifier
        self.cellConfigurator = cellConfigurator
    }

    public func cellForItem(item: DataItem, inTableView tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> Cell {
        let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as! Cell
        return configureCell(cell, forItem: item, inTableView: tableView, atIndexPath: indexPath)
    }

    public func configureCell(cell: Cell, forItem item: DataItem, inTableView tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> Cell {
        return self.cellConfigurator(cell, item, tableView, indexPath)
    }

}


public protocol TableViewSectionInfo {
    typealias DataItem

    var dataItems: [DataItem] { get }

    var headerTitle: String? { get }

    var footerTitle: String? { get }
}


public struct TableViewSection <DataItem>: TableViewSectionInfo {

    typealias TableViewRowCollection = [DataItem]

    public var dataItems: TableViewRowCollection

    public let headerTitle: String?

    public let footerTitle: String?

    public init(dataItems: TableViewRowCollection, headerTitle: String? = nil, footerTitle: String? = nil) {
        self.dataItems = dataItems
        self.headerTitle = headerTitle
        self.footerTitle = footerTitle
    }

}


public class TableViewDataSourceProvider <DataItem, SectionInfo: TableViewSectionInfo, CellFactory: TableViewCellFactoryType
                                            where
                                            SectionInfo.DataItem == DataItem,
                                            CellFactory.DataItem == DataItem> {

    public var sections: [SectionInfo]

    public let cellFactory: CellFactory

    public var dataSource: UITableViewDataSource { return bridgedDataSource }

    public init(sections: [SectionInfo], cellFactory: CellFactory, tableView: UITableView? = nil) {
        self.sections = sections
        self.cellFactory = cellFactory

        tableView?.dataSource = self.dataSource
    }

    private lazy var bridgedDataSource: BridgedTableViewDataSource = BridgedTableViewDataSource(
        numberOfSections: { [unowned self] () -> Int in
            self.sections.count
        },
        numberOfRowsInSection: { [unowned self] (section) -> Int in
            self.sections[section].dataItems.count
        },
        cellForRowAtIndexPath: { [unowned self] (tableView, indexPath) -> UITableViewCell in
            let dataItem = self.sections[indexPath.section].dataItems[indexPath.row]
            return self.cellFactory.cellForItem(dataItem, inTableView: tableView, atIndexPath: indexPath)
        },
        titleForHeaderInSection: { [unowned self] (section) -> String? in
            self.sections[section].headerTitle
        },
        titleForFooterInSection: { [unowned self] (section) -> String? in
            self.sections[section].footerTitle
        }
    )

}


public class TableViewFetchedResultsDataSourceProvider <DataItem, SectionInfo: TableViewSectionInfo, CellFactory: TableViewCellFactoryType
                                                        where
                                                        SectionInfo.DataItem == DataItem,
                                                        CellFactory.DataItem == DataItem> {

    public let fetchedResultsController: NSFetchedResultsController

    public let cellFactory: CellFactory

    public var dataSource: UITableViewDataSource { return bridgedDataSource }

    public init(fetchedResultsController: NSFetchedResultsController, delegate: NSFetchedResultsControllerDelegate? = nil, cellFactory: CellFactory, tableView: UITableView? = nil) {
        self.fetchedResultsController = fetchedResultsController
        self.fetchedResultsController.delegate = delegate
        self.cellFactory = cellFactory

        tableView?.dataSource = self.dataSource
    }

    private lazy var bridgedDataSource: BridgedTableViewDataSource = BridgedTableViewDataSource(
        numberOfSections: { [unowned self] () -> Int in
            self.fetchedResultsController.sections?.count ?? 0
        },
        numberOfRowsInSection: { [unowned self] (section) -> Int in
            let sectionInfo = self.fetchedResultsController.sections?[section] as! NSFetchedResultsSectionInfo
            return sectionInfo.numberOfObjects ?? 0
        },
        cellForRowAtIndexPath: { [unowned self] (tableView, indexPath) -> UITableViewCell in
            let dataItem = self.fetchedResultsController.objectAtIndexPath(indexPath) as! DataItem
            return self.cellFactory.cellForItem(dataItem, inTableView: tableView, atIndexPath: indexPath)
        },
        titleForHeaderInSection: { [unowned self] (section) -> String? in
            if self.fetchedResultsController.fetchedObjects?.count == 0 {
                return nil
            }

            let sectionInfo = self.fetchedResultsController.sections?[section] as! NSFetchedResultsSectionInfo
            return sectionInfo.name
        },
        titleForFooterInSection: { [unowned self] (section) -> String? in
            return nil
        }
    )
    
}

@objc private class BridgedTableViewDataSource: NSObject, UITableViewDataSource {

    typealias NumberOfSectionsHandler = () -> Int
    typealias NumberOfRowsInSectionHandler = (Int) -> Int
    typealias CellForRowAtIndexPathHandler = (UITableView, NSIndexPath) -> UITableViewCell
    typealias TitleForHeaderInSectionHandler = (Int) -> String?
    typealias TitleForFooterInSectionHandler = (Int) -> String?

    private let numberOfSections: NumberOfSectionsHandler
    private let numberOfRowsInSection: NumberOfRowsInSectionHandler
    private let cellForRowAtIndexPath: CellForRowAtIndexPathHandler
    private let titleForHeaderInSection: TitleForHeaderInSectionHandler
    private let titleForFooterInSection: TitleForFooterInSectionHandler

    init(numberOfSections: NumberOfSectionsHandler,
        numberOfRowsInSection: NumberOfRowsInSectionHandler,
        cellForRowAtIndexPath: CellForRowAtIndexPathHandler,
        titleForHeaderInSection: TitleForHeaderInSectionHandler,
        titleForFooterInSection: TitleForFooterInSectionHandler) {

            self.numberOfSections = numberOfSections
            self.numberOfRowsInSection = numberOfRowsInSection
            self.cellForRowAtIndexPath = cellForRowAtIndexPath
            self.titleForHeaderInSection = titleForHeaderInSection
            self.titleForFooterInSection = titleForFooterInSection
    }

    @objc func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return numberOfSections()
    }

    @objc func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfRowsInSection(section)
    }

    @objc func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return cellForRowAtIndexPath(tableView, indexPath)
    }

    @objc func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titleForHeaderInSection(section)
    }

    @objc func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return titleForFooterInSection(section)
    }
    
}