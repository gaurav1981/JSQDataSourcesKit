//
//  Created by Jesse Squires
//  https://www.jessesquires.com
//
//
//  Documentation
//  https://jessesquires.github.io/JSQDataSourcesKit
//
//
//  GitHub
//  https://github.com/jessesquires/JSQDataSourcesKit
//
//
//  License
//  Copyright © 2015-present Jesse Squires
//  Released under an MIT license: https://opensource.org/licenses/MIT
//

import UIKit
import JSQDataSourcesKit

final class TableViewController: UITableViewController {
    
    typealias TableCellConfig = ReusableViewConfig<CellViewModel, UITableViewCell>
    var dataSourceProvider: DataSourceProvider<DataSource<Section<CellViewModel>>, TableCellConfig, TableCellConfig>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. create view models
        let section0 = Section(items: CellViewModel(), CellViewModel(), CellViewModel(), headerTitle: "First")
        let section1 = Section(items: CellViewModel(), CellViewModel(), CellViewModel(), CellViewModel(), headerTitle: "Second", footerTitle: "Only 2nd has a footer")
        let section2 = Section(items: CellViewModel(), CellViewModel(), headerTitle: "Third")
        let dataSource = DataSource(sections: section0, section1, section2)
        
        // 2. create cell config
        let config = ReusableViewConfig(reuseIdentifier: CellId) { (cell, model: CellViewModel?, type, tableView, indexPath) -> UITableViewCell in
            cell.textLabel?.text = model!.text
            cell.detailTextLabel?.text = "\(indexPath.section), \(indexPath.row)"
            cell.accessibilityIdentifier = "\(indexPath.section), \(indexPath.row)"
            return cell
        }
        
        // ** optional editing **
        // if needed, enable the editing functionality on the tableView
        let editingController: TableEditingController<DataSource<Section<CellViewModel>>> = TableEditingController(
            canEditRow: { (item, tableView, indexPath) -> Bool in
                return true
        },
            commitEditing: { (dataSource: inout DataSource, tableView, editingStyle, indexPath) in
                if editingStyle == .delete {
                    if let _ = dataSource.remove(at: indexPath) {
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
        })
        
        // 3. create data source provider
        dataSourceProvider = DataSourceProvider(dataSource: dataSource,
                                                cellConfig: config,
                                                supplementaryConfig: config,
                                                tableEditingController: editingController)
        
        // 4. set data source
        tableView.dataSource = dataSourceProvider?.tableViewDataSource
    }
}
