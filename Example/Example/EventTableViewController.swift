//  Copyright © 2022 Radar Labs, Inc. All rights reserved.

import UIKit

/// A simple table that displays data received by `RadarDelegate`, which is
/// implemented by the `AppDelegate`.
class EventTableViewController: UITableViewController {

    /// Events are a simple tuple of a string and a timestamp of when it was
    /// received by `AppDelegate.notify()`.
    var events: [(Date, String)] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    override init(style: UITableView.Style) {
        super.init(style: style)

        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseId)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let event = events[events.count - indexPath.row - 1]
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseId, for: indexPath)

        // Event string
        cell.textLabel?.text = event.1
        cell.textLabel?.numberOfLines = 0

        // Event timestamp
        cell.detailTextLabel?.text = String(describing: event.0)

        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    class Cell: UITableViewCell {

        static let reuseId = "eventCell"

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

            if let titleFont = textLabel?.font {
                textLabel?.font = titleFont.withSize(13.0)
            }

            if let detailFont = detailTextLabel?.font {
                detailTextLabel?.font = detailFont.withSize(11.0)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    }

}

