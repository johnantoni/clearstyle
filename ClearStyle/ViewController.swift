//
//  ViewController.swift
//  ClearStyle
//
//  Created by Audrey M Tam on 4/08/2014.
//  Copyright (c) 2014 Ray Wenderlich. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TableViewCellDelegate {
                            
    @IBOutlet weak var tableView: UITableView!
    
    var toDoItems = [ToDoItem]()
    let pinchRecognizer = UIPinchGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pinchRecognizer.addTarget(self, action: "handlePinch:")
        tableView.addGestureRecognizer(pinchRecognizer)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(TableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .None
        tableView.backgroundColor = UIColor.blackColor()
        tableView.rowHeight = 50
        
        if toDoItems.count > 0 {
            return
        }
        toDoItems.append(ToDoItem(text: "feed the cat"))
        toDoItems.append(ToDoItem(text: "buy eggs"))
        toDoItems.append(ToDoItem(text: "watch WWDC videos"))
        toDoItems.append(ToDoItem(text: "rule the Web"))
        toDoItems.append(ToDoItem(text: "buy a new iPhone"))
        toDoItems.append(ToDoItem(text: "darn holes in socks"))
        toDoItems.append(ToDoItem(text: "write this tutorial"))
        toDoItems.append(ToDoItem(text: "master Swift"))
        toDoItems.append(ToDoItem(text: "learn to draw"))
        toDoItems.append(ToDoItem(text: "get more exercise"))
        toDoItems.append(ToDoItem(text: "catch up with Mom"))
        toDoItems.append(ToDoItem(text: "get a hair cut"))
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toDoItems.count
    }

    func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! TableViewCell
            cell.selectionStyle = .None
            cell.textLabel?.backgroundColor = UIColor.clearColor()
            let item = toDoItems[indexPath.row]
//            cell.textLabel?.text = item.text
            cell.delegate = self
            cell.toDoItem = item
            return cell
    }
    
    func cellDidBeginEditing(editingCell: TableViewCell) {
        let editingOffset = tableView.contentOffset.y - editingCell.frame.origin.y as CGFloat
        let visibleCells = tableView.visibleCells as! [TableViewCell]
        for cell in visibleCells {
            UIView.animateWithDuration(0.3, animations: {() in
                cell.transform = CGAffineTransformMakeTranslation(0, editingOffset)
                if cell !== editingCell {
                    cell.alpha = 0.3
                }
            })
        }
    }
    
    func cellDidEndEditing(editingCell: TableViewCell) {
        let visibleCells = tableView.visibleCells as! [TableViewCell]
        for cell: TableViewCell in visibleCells {
            UIView.animateWithDuration(0.3, animations: {() in
                cell.transform = CGAffineTransformIdentity
                if cell !== editingCell {
                    cell.alpha = 1.0
                }
            })
        }
        if editingCell.toDoItem!.text == "" {
            toDoItemDeleted(editingCell.toDoItem!)
        }
    }
    
    func toDoItemDeleted(toDoItem: ToDoItem) {
        // could use this to get index when Swift Array indexOfObject works
        // let index = toDoItems.indexOfObject(toDoItem)
        // in the meantime, scan the array to find index of item to delete
        var index = 0
        for i in 0..<toDoItems.count {
            if toDoItems[i] === toDoItem {  // note: === not ==
                index = i
                break
            }
        }
        // could removeAtIndex in the loop but keep it here for when indexOfObject works
        toDoItems.removeAtIndex(index)
        
        // loop over the visible cells to animate delete
        let visibleCells = tableView.visibleCells as! [TableViewCell]
        let lastView = visibleCells[visibleCells.count - 1] as TableViewCell
        var delay = 0.0
        var startAnimating = false
        for i in 0..<visibleCells.count {
            let cell = visibleCells[i]
            if startAnimating {
                UIView.animateWithDuration(0.3, delay: delay, options: .CurveEaseInOut,
                    animations: {() in
                        cell.frame = CGRectOffset(cell.frame, 0.0, -cell.frame.size.height)},
                    completion: {(finished: Bool) in if (cell == lastView) {
                        self.tableView.reloadData()
                        }
                    }
                )
                delay += 0.03
            }
            if cell.toDoItem === toDoItem {
                startAnimating = true
                cell.hidden = true
            }
        }
        
        // use the UITableView to animate the removal of this row
        tableView.beginUpdates()
        let indexPathForRow = NSIndexPath(forRow: index, inSection: 0)
        tableView.deleteRowsAtIndexPaths([indexPathForRow], withRowAnimation: .Fade)
        tableView.endUpdates()
    }
    // MARK: - Table view delegate
    
    func colorForIndex(index: Int) -> UIColor {
        let itemCount = toDoItems.count - 1
        let val = (CGFloat(index) / CGFloat(itemCount)) * 0.6
        return UIColor(red: 1.0, green: val, blue: 0.0, alpha: 1.0)
    }
    
    let kRowHeight: CGFloat = 50.0
    func tableView(tableView: UITableView,
        heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            return kRowHeight
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell,
        forRowAtIndexPath indexPath: NSIndexPath) {
            cell.backgroundColor = colorForIndex(indexPath.row)
    }

    // MARK: - pinch-to-add methods
    
    struct TouchPoints {
        var upper: CGPoint
        var lower: CGPoint
    }
    // the indices of the upper and lower cells that are being pinched
    var upperCellIndex = -100
    var lowerCellIndex = -100
    // the location of the touch points when the pinch began
    var initialTouchPoints: TouchPoints!
    // indicates that the pinch was big enough to cause a new item to be added
    var pinchExceededRequiredDistance = false

    // indicates that the pinch is in progress
    var pinchInProgress = false
    
    func handlePinch(recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .Began {
            pinchStarted(recognizer)
        }
        if recognizer.state == .Changed
            && pinchInProgress
            && recognizer.numberOfTouches() == 2 {
                pinchChanged(recognizer)
        }
        if recognizer.state == .Ended {
            pinchEnded(recognizer)
        }
    }
    
    func pinchStarted(recognizer: UIPinchGestureRecognizer) {
        // find the touch-points
        initialTouchPoints = getNormalizedTouchPoints(recognizer)
        
        // locate the cells that these points touch
        upperCellIndex = -100
        lowerCellIndex = -100
        let visibleCells = tableView.visibleCells  as! [TableViewCell]
        for i in 0..<visibleCells.count {
            let cell = visibleCells[i]
            if viewContainsPoint(cell, point: initialTouchPoints.upper) {
                upperCellIndex = i
            }
            if viewContainsPoint(cell, point: initialTouchPoints.lower) {
                lowerCellIndex = i
            }
        }
        // check whether they are neighbors
        if abs(upperCellIndex - lowerCellIndex) == 1 {
            // initiate the pinch
            pinchInProgress = true
            // show placeholder cell
            let precedingCell = visibleCells[upperCellIndex]
            placeHolderCell.frame = CGRectOffset(precedingCell.frame, 0.0, kRowHeight / 2.0)
            placeHolderCell.backgroundColor = precedingCell.backgroundColor
            tableView.insertSubview(placeHolderCell, atIndex: 0)
        }
    }
    
    func pinchChanged(recognizer: UIPinchGestureRecognizer) {
        // find the touch points
        let currentTouchPoints = getNormalizedTouchPoints(recognizer)
        
        // determine by how much each touch point has changed, and take the minimum delta
        let upperDelta = currentTouchPoints.upper.y - initialTouchPoints.upper.y
        let lowerDelta = initialTouchPoints.lower.y - currentTouchPoints.lower.y
        let delta = -min(0, min(upperDelta, lowerDelta))
        
        // offset the cells, negative for the cells above, positive for those below
        let visibleCells = tableView.visibleCells as! [TableViewCell]
        for i in 0..<visibleCells.count {
            let cell = visibleCells[i]
            if i <= upperCellIndex {
                cell.transform = CGAffineTransformMakeTranslation(0, -delta)
            }
            if i >= lowerCellIndex {
                cell.transform = CGAffineTransformMakeTranslation(0, delta)
            }
        }
        
        // scale the placeholder cell
        let gapSize = delta * 2
        let cappedGapSize = min(gapSize, tableView.rowHeight)
        placeHolderCell.transform = CGAffineTransformMakeScale(1.0, cappedGapSize / tableView.rowHeight)
        placeHolderCell.label.text = gapSize > tableView.rowHeight ? "Release to add item" : "Pull apart to add item"
        placeHolderCell.alpha = min(1.0, gapSize / tableView.rowHeight)
        
        // has the user pinched far enough?
        pinchExceededRequiredDistance = gapSize > tableView.rowHeight
    }
    
    func pinchEnded(recognizer: UIPinchGestureRecognizer) {
        pinchInProgress = false
        
        // remove the placeholder cell
        placeHolderCell.transform = CGAffineTransformIdentity
        placeHolderCell.removeFromSuperview()
        
        if pinchExceededRequiredDistance {
            pinchExceededRequiredDistance = false

            // Set all the cells back to the transform identity
            let visibleCells = self.tableView.visibleCells as! [TableViewCell]
            for cell in visibleCells {
                cell.transform = CGAffineTransformIdentity
            }
            
            // add a new item
            let indexOffset = Int(floor(tableView.contentOffset.y / tableView.rowHeight))
            toDoItemAddedAtIndex(lowerCellIndex + indexOffset)
        } else {
            // otherwise, animate back to position
            UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseInOut, animations: {() in
                let visibleCells = self.tableView.visibleCells as! [TableViewCell]
                for cell in visibleCells {
                    cell.transform = CGAffineTransformIdentity
                }
                }, completion: nil)
        }
    }
    
    // returns the two touch points, ordering them to ensure that
    // upper and lower are correctly identified.
    func getNormalizedTouchPoints(recognizer: UIGestureRecognizer) -> TouchPoints {
        var pointOne = recognizer.locationOfTouch(0, inView: tableView)
        var pointTwo = recognizer.locationOfTouch(1, inView: tableView)
        // ensure pointOne is the top-most
        if pointOne.y > pointTwo.y {
            let temp = pointOne
            pointOne = pointTwo
            pointTwo = temp
        }
        return TouchPoints(upper: pointOne, lower: pointTwo)
    }
    
    func viewContainsPoint(view: UIView, point: CGPoint) -> Bool {
        let frame = view.frame
        return (frame.origin.y < point.y) && (frame.origin.y + (frame.size.height) > point.y)
    }
    
    // MARK: - UIScrollViewDelegate methods
    // contains scrollViewDidScroll, and you'll add two more, to keep track of dragging the scrollView

    // a cell that is rendered as a placeholder to indicate where a new item is added
    let placeHolderCell = TableViewCell(style: .Default, reuseIdentifier: "cell")
    // indicates the state of this behavior
    var pullDownInProgress = false

    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        // this behavior starts when a user pulls down while at the top of the table
        pullDownInProgress = scrollView.contentOffset.y <= 0.0
        placeHolderCell.backgroundColor = UIColor.redColor()
        if pullDownInProgress {
            // add the placeholder
            tableView.insertSubview(placeHolderCell, atIndex: 0)
        }
    }

    func scrollViewDidScroll(scrollView: UIScrollView)  {
        // non-scrollViewDelegate methods need this property value
        let scrollViewContentOffsetY = tableView.contentOffset.y
        
        if pullDownInProgress && scrollView.contentOffset.y <= 0.0 {
            // maintain the location of the placeholder
            placeHolderCell.frame = CGRect(x: 0, y: -tableView.rowHeight,
                width: tableView.frame.size.width, height: tableView.rowHeight)
            placeHolderCell.label.text = -scrollViewContentOffsetY > tableView.rowHeight ?
                "Release to add item" : "Pull to add item"
            placeHolderCell.alpha = min(1.0, -scrollViewContentOffsetY / tableView.rowHeight)
        } else {
            pullDownInProgress = false
        }
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // check whether the user pulled down far enough
        if pullDownInProgress && -scrollView.contentOffset.y > tableView.rowHeight {
            toDoItemAdded()
        }
        pullDownInProgress = false
        placeHolderCell.removeFromSuperview()
    }
    
    // MARK: - add, delete, edit methods
    
    func toDoItemAdded() {
        toDoItemAddedAtIndex(0)
    }
    
    func toDoItemAddedAtIndex(index: Int) {
        let toDoItem = ToDoItem(text: "")
        toDoItems.insert(toDoItem, atIndex: index)
        tableView.reloadData()
        // enter edit mode
        var editCell: TableViewCell
        let visibleCells = tableView.visibleCells as! [TableViewCell]
        for cell in visibleCells {
            if (cell.toDoItem === toDoItem) {
                editCell = cell
                editCell.label.becomeFirstResponder()
                break
            }
        }
    }
}

