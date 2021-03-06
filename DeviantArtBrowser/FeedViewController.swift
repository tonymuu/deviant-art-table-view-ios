//
//  ViewController.swift
//  DeviantArtBrowser
//
//  Created by Joshua Greene on 10/22/14.
//  Copyright (c) 2014 Razeware, LLC. All rights reserved.
//

import UIKit

class FeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
  
  // MARK: Instance Variables
  
    let basicCellIdentifier = "BasicCell"
    let customImageCellIdentifier = "CustomImageCell"
    
    @IBOutlet var searchTextField: UITextField!
    @IBOutlet var tableView: UITableView!
    
  let parser = RSSParser()
  let deviantArtBaseUrlString = "http://backend.deviantart.com/rss.xml"
  
  var items:[RSSItem] = []
  
  // MARK: View Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureTableView()
    refreshData()
  }
  
  func configureTableView() {
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 160.0
}
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    deselectAllRows()
  }
  
  func deselectAllRows() {
    if let selectedRows = tableView.indexPathsForSelectedRows() as? [NSIndexPath] {
      for indexPath in selectedRows {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
      }
    }
  }
  
  // MARK: Refresh Content
  
  func refreshData() {
    searchTextField.resignFirstResponder()
    parseForQuery(searchTextField.text)
  }
  
  func parseForQuery(query: String?) {
    showProgressHUD()
    
    parser.parseRSSFeed(deviantArtBaseUrlString,
      parameters: parametersForQuery(query),
      success: {(let channel: RSSChannel!) -> Void  in
        
        self.convertItemPropertiesToPlainText(channel.items as! [RSSItem])
        self.items = (channel.items as! [RSSItem])
        
        self.hideProgressHUD()
        self.reloadTableViewContent()
        
      }, failure: {(let error:NSError!) -> Void in
        
        self.hideProgressHUD()
        println("Error: \(error)")
    })
  }
  
  func showProgressHUD() {
    var hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
    hud.labelText = "Loading"
  }
  
  func parametersForQuery(query: NSString?) -> [String: String] {
    if query != nil && query!.length > 0 {
      return ["q": "\(query!)"]
      
    } else {
      return ["q": "boost:popular"]
    }
  }
  
  func hideProgressHUD() {
    MBProgressHUD.hideAllHUDsForView(view, animated: true)
  }
  
  func convertItemPropertiesToPlainText(rssItems:[RSSItem]) {
    for item in rssItems {
      let charSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
      
      if let title = item.title as NSString! {
        item.title = title.stringByConvertingHTMLToPlainText().stringByTrimmingCharactersInSet(charSet)
      }
      
      if let mediaDescription = item.mediaDescription as NSString! {
        item.mediaDescription = mediaDescription.stringByConvertingHTMLToPlainText().stringByTrimmingCharactersInSet(charSet)
      }
      
      if let mediaText = item.mediaText as NSString! {
        item.mediaText = mediaText.stringByConvertingHTMLToPlainText().stringByTrimmingCharactersInSet(charSet)
      }
    }
  }
  
  func reloadTableViewContent() {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.tableView.reloadData()
      self.tableView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: false)
    })
  }
  
  // MARK: UITableViewDataSource
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

    return items.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    if haveImageAtIndexPath(indexPath) {
        return imageCellAtIndexPath(indexPath)
    } else {
        return basicCellAtIndexPath(indexPath)
    }
}
    
    func imageCellAtIndexPath(indexPath: NSIndexPath) -> CustomImageTableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier(customImageCellIdentifier) as! CustomImageTableViewCell
        setImageForCell(cell, indexPath: indexPath)
        setTitleForCell(cell, indexPath: indexPath)
        setSubtitleForCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    func haveImageAtIndexPath(indexPath: NSIndexPath) -> Bool {
        let item = items[indexPath.row]
        let mediaThumbnailArray = item.mediaThumbnails as! [RSSMediaThumbnail]
        
        for mediaThumbnail in mediaThumbnailArray {
            if(mediaThumbnail.url != nil) {
                return true
            }
        }
        return false
    }
    
    func setImageForCell(cell:CustomImageTableViewCell, indexPath: NSIndexPath) {
        let item: RSSItem = items[indexPath.row]
        var mediaThumbnail: RSSMediaThumbnail?
        
        if(item.mediaThumbnails.count >= 2) {
            mediaThumbnail = item.mediaThumbnails[1] as? RSSMediaThumbnail
        } else {
            mediaThumbnail = item.mediaThumbnails.first as? RSSMediaThumbnail
        }
        
        cell.imageView?.image = nil
        
        if let url = mediaThumbnail?.url {
            cell.imageView?.setImageWithURL(url)
        }
    }
  

    func basicCellAtIndexPath(indexPath: NSIndexPath) -> BasicCellTableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(basicCellIdentifier) as! BasicCellTableViewCell
        setTitleForCell(cell, indexPath: indexPath)
        setSubtitleForCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    func setTitleForCell(cell: BasicCellTableViewCell, indexPath: NSIndexPath) {
        let item = items[indexPath.row] as RSSItem
        cell.titleLabel.text = item.title ?? "[No Title]"
        
    }
    
    func setSubtitleForCell(cell: BasicCellTableViewCell, indexPath: NSIndexPath) {
        let item = items[indexPath.row] as RSSItem
        var subtitle: NSString? = item.mediaText ?? item.mediaDescription ?? item.mediaTitle
        if let subtitle = subtitle {
            if subtitle.length > 200 {
                cell.subtitleLabel.text = "\(subtitle.substringToIndex(200))"
            } else {
                cell.subtitleLabel.text = subtitle as String
            }
        } else {
            cell.subtitleLabel.text = ""
        }
    }

  // MARK: UITextFieldDelegate
  
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    refreshData()
    return false
  }
  
  // MARK: Navigation
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    let indexPath = tableView.indexPathForSelectedRow()
    let item = items[indexPath!.row]
    
    let detailViewController = segue.destinationViewController as! DetailViewController
    detailViewController.item = item
  }
}

