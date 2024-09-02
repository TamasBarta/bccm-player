//
//  PlayerController.swift
//  bccm_player
//
//  Created by Andreas Gangsø on 19/09/2022.
//

import AVFoundation
import Foundation

public protocol PlayerController {
    var id: String { get }
    var mixWithOthers: Bool { get set }
    var manuallySelectedAudioLanguage: String? { get set }
    func setNpawConfig(npawConfig: NpawConfig?)
    func updateAppConfig(appConfig: AppConfig?)
    func getCurrentItem() -> MediaItem?
    func getPlayerTracksSnapshot() -> PlayerTracksSnapshot
    func setSelectedTrack(type: TrackType, trackId: String?)
    func setPlaybackSpeed(_ speed: Float)
    func setVolume(_ speed: Float)
    func setRepeatMode(_ repeatMode: RepeatMode)
    func getPlayerStateSnapshot() -> PlayerStateSnapshot
    func replaceCurrentMediaItem(_ mediaItem: MediaItem, autoplay: NSNumber?, completion: ((FlutterError?) -> Void)?)
    func queueItem(_ mediaItem: MediaItem)
    func play()
    func seekTo(_ positionMs: Int64, _ completion: @escaping (Bool) -> Void)
    func pause()
    func stop(reset: Bool)
    func exitFullscreen()
    func enterFullscreen()
    func hasBecomePrimary()
    func moveQueueItem(from fromIndex: Int, to toIndex: Int)
    func removeQueueItem(id: String)
    func clearQueue()
    func replaceQueueItems(items: [MediaItem], from fromIndex: Int, to toIndex: Int)
    func setCurrentQueueItem(id: String)
    func getQueue() -> MediaQueue
}
