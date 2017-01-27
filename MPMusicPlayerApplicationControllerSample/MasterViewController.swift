//
//  MasterViewController.swift
//  MPMusicPlayerApplicationControllerSample
//
//  Created by hiraya.shingo on 2017/01/27.
//  Copyright © 2017年 hiraya.shingo. All rights reserved.
//

import UIKit
import MediaPlayer

class MasterViewController: UITableViewController {
    let musicPlayerApplicationController = MPMusicPlayerController.applicationQueuePlayer()
    var mediaItems: [MPMediaItem] = []
    var finishedSetQueue = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up navigationItem
        navigationItem.leftBarButtonItem = editButtonItem
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton

        // set up toolbar
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                       target: nil,
                                       action: nil)
        let previous = UIBarButtonItem(barButtonSystemItem: .rewind,
                                       target: self,
                                       action: #selector(didTapPrevButton(_:)))
        let play = UIBarButtonItem(barButtonSystemItem: .play,
                                   target: self,
                                   action: #selector(didTapPlayButton(_:)))
        let next = UIBarButtonItem(barButtonSystemItem: .fastForward,
                                   target: self,
                                   action: #selector(didTapNextButton(_:)))
        toolbarItems = [
            flexible,
            previous,
            flexible,
            play,
            flexible,
            next,
            flexible
        ]
        navigationController?.setToolbarHidden(false, animated: true)
        
        // check Authorization
        MPMediaLibrary.requestAuthorization { status in
            print("status:", status == .authorized ? "authorized" : "Not authorized")
        }
    }
    
    func didTapPrevButton(_ sender: Any) {
        musicPlayerApplicationController.skipToPreviousItem()
    }
    
    func didTapPlayButton(_ sender: Any) {
        let playbackState = musicPlayerApplicationController.playbackState
        if playbackState == .playing {
            musicPlayerApplicationController.pause()
        } else if playbackState == .stopped || playbackState == .paused {
            musicPlayerApplicationController.play()
        }
    }
    
    func didTapNextButton(_ sender: Any) {
        musicPlayerApplicationController.skipToNextItem()
    }

    func insertNewObject(_ sender: Any) {
        // present MPMediaPickerController
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.allowsPickingMultipleItems = true
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func setQueue(mediaItemCollection: MPMediaItemCollection) {
        mediaItems = mediaItemCollection.items
        tableView.reloadData()
        
        // setQueue and prepare
        musicPlayerApplicationController.setQueue(with: mediaItemCollection)
        musicPlayerApplicationController.nowPlayingItem = mediaItemCollection.items.first
    }
    
    func insertQueue(mediaItemCollection: MPMediaItemCollection) {
        // Update Player's Queue
        musicPlayerApplicationController.performQueueTransaction({ mutableQueue in
            print("mutableQueue.items.count:", mutableQueue.items.count)
            print("mediaItemCollection.items.count:", mediaItemCollection.items.count)
            
            // This code is not work with iOS 10.3 beta 1
            let descriptor = MPMusicPlayerMediaItemQueueDescriptor(itemCollection: mediaItemCollection)
            mutableQueue.insert(descriptor,
                                after: mutableQueue.items.last)
            // 
            
        }, completionHandler: {queue, error in
            print("queue.items.count:", queue.items.count)
            
            self.mediaItems = queue.items
            self.tableView.reloadData()
        })
    }
}

// MARK: - UITableViewDataSource
extension MasterViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = mediaItems[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.artist
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MasterViewController {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Edit Player's Queue
            musicPlayerApplicationController.performQueueTransaction({ mutableQueue in
                mutableQueue.removeItem(self.mediaItems[indexPath.row])
            }, completionHandler: {queue, error in
                self.mediaItems = queue.items
                tableView.deleteRows(at: [indexPath], with: .fade)
            })
        } else if editingStyle == .insert {
            
        }
    }
}

// MARK: - MPMediaPickerControllerDelegate
extension MasterViewController: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        if finishedSetQueue {
            // after the 2nd time
            insertQueue(mediaItemCollection: mediaItemCollection)
        } else {
            // first time
            setQueue(mediaItemCollection: mediaItemCollection)
            finishedSetQueue = true
        }
        
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
}
