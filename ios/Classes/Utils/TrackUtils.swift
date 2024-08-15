//
//  TrackUtils.swift
//  bccm_player
//
//  Created by Andreas Gangsø on 07/09/2023.
//

import AVFoundation
import Foundation

class TrackUtils {
    static func getAVMediaSelectionsForText(_ asset: AVAsset) throws -> [AVMediaSelection] {
        guard let selectionGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else {
            return []
        }
        let audioGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .audible)
        var mediaSelections: [AVMediaSelection] = []
        // We want to filter out the default "Unknown CC" text track:
        // See https://developer.apple.com/library/archive/qa/qa1801/_index.html
        for option in selectionGroup.options.filter({ $0.extendedLanguageTag != nil || $0.mediaType != .closedCaption }) {
            let selection = asset.preferredMediaSelection.mutableCopy() as! AVMutableMediaSelection
            if let audioGroup = audioGroup {
                selection.select(nil, in: audioGroup)
            }
            selection.select(option, in: selectionGroup)
            mediaSelections.append(selection)
        }
        return mediaSelections
    }

    static func getAVMediaSelectionsForAudio(_ asset: AVAsset, ids: [String]) throws -> [AVMediaSelection] {
        guard let selectionGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .audible) else {
            return []
        }
        var mediaSelections: [AVMediaSelection] = []
        for trackId in ids {
            guard let trackIdInt = Int(trackId) else {
                throw BccmPlayerError.runtimeError("Invalid trackId for selection: " + trackId)
            }
            let optionToSelect = selectionGroup.options[trackIdInt]
            let selection = asset.preferredMediaSelection.mutableCopy() as! AVMutableMediaSelection
            selection.select(optionToSelect, in: selectionGroup)
            mediaSelections.append(selection)
        }
        return mediaSelections
    }

    static func getAudioTracksForAsset(_ asset: AVAsset, playerItem: AVPlayerItem?) -> [Track] {
        let urlAsset = asset as? AVURLAsset
        var audioTracks: [Track] = []
        if let audioGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
            let offlineOptions = urlAsset?.assetCache?.mediaSelectionOptions(in: audioGroup)
            for (index, option) in audioGroup.options.enumerated() {
                let isDownloaded = offlineOptions?.contains(option) as? NSNumber ?? false
                let track = Track.make(withId: "\(index)",
                                       label: option.displayName,
                                       language: option.locale?.identifier,
                                       frameRate: nil,
                                       bitrate: nil,
                                       width: nil,
                                       height: nil,
                                       downloaded: isDownloaded,
                                       isSelected: playerItem == nil ? false : playerItem!.currentMediaSelection.selectedMediaOption(in: audioGroup) == option)
                audioTracks.append(track)
            }
        }
        return audioTracks
    }

    static func getTextTracksForAsset(_ asset: AVAsset, playerItem: AVPlayerItem?) -> [Track] {
        let urlAsset = asset as? AVURLAsset
        var textTracks: [Track] = []
        if let subtitleGroup = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            let offlineOptions = urlAsset?.assetCache?.mediaSelectionOptions(in: subtitleGroup)
            for (index, option) in subtitleGroup.options.enumerated() {
                let isDownloaded = offlineOptions?.contains(option) as? NSNumber ?? false
                let track = Track.make(withId: "\(index)",
                                       label: option.displayName,
                                       language: option.locale?.identifier,
                                       frameRate: nil,
                                       bitrate: nil,
                                       width: nil,
                                       height: nil,
                                       downloaded: isDownloaded,
                                       isSelected: playerItem == nil ? false : playerItem!.currentMediaSelection.selectedMediaOption(in: subtitleGroup) == option)
                textTracks.append(track)
            }
        }
        return textTracks
    }

    static func getVideoTracksForAsset(_ asset: AVAsset, playerItem: AVPlayerItem?) -> [Track] {
        let urlAsset = asset as? AVURLAsset
        var videoTracks: [Track] = []
        if #available(iOS 15, *), let urlAsset = urlAsset {
            let variants = urlAsset.variants
            for (index, variant) in variants.enumerated() {
                let bitrate = variant.averageBitRate
                let width = variant.videoAttributes?.presentationSize.width
                let height = variant.videoAttributes?.presentationSize.height
                let frameRate = variant.videoAttributes?.nominalFrameRate
                let currentPreferredBitrate = playerItem?.preferredPeakBitRate

                let id = bitrate != nil ? "\(Int(bitrate!))" : height != nil ? "\(Int(height!))" : "\(index)"
                let label = width != nil && height != nil ? "\(Int(width!)) x \(Int(height!))" : "\(index)"
                let track = Track.make(withId: id,
                                       label: label,
                                       language: nil,
                                       frameRate: frameRate as NSNumber?,
                                       bitrate: bitrate != nil ? Int(bitrate!) as NSNumber : nil,
                                       width: width != nil ? Int(width!) as NSNumber : nil,
                                       height: height != nil ? Int(height!) as NSNumber : nil,
                                       downloaded: false,
                                       isSelected: currentPreferredBitrate != nil && bitrate != nil && Int(currentPreferredBitrate!) == Int(bitrate!))
                videoTracks.append(track)
            }
        }
        return videoTracks
    }
}

extension AVPlayerItem {
    func isOffline() -> Bool {
        let playerData = MetadataUtils.getNamespacedMetadata(externalMetadata, namespace: .BccmPlayer)
        return asset is AVURLAsset && playerData[PlayerMetadataConstants.IsOffline] == "true"
    }

    func setAudioLanguage(_ audioLanguage: String) -> Bool {
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.audible) {
            let offlineOptions = (asset as? AVURLAsset)?.assetCache?.mediaSelectionOptions(in: group)
            let locale = Locale(identifier: audioLanguage)
            let options = AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale)
            for option in options {
                if !isOffline() || offlineOptions?.contains(option) == true {
                    select(option, in: group)
                    return true
                }
            }
        }
        return false
    }

    func setAudioLanguagePrioritized(_ audioLanguages: [String]) -> Bool {
        for language in audioLanguages {
            if setAudioLanguage(language) {
                return true
            }
        }
        return false
    }

    func setSubtitleLanguagePrioritized(_ subtitleLanguage: [String]) -> Bool {
        for language in subtitleLanguage {
            if setSubtitleLanguage(language) {
                return true
            }
        }
        return false
    }

    func setSubtitleLanguage(_ subtitleLanguage: String) -> Bool {
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.legible) {
            let locale = Locale(identifier: subtitleLanguage)
            let options = AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale)
            if let option = options.first {
                select(option, in: group)
                return true
            }
        }
        return false
    }

    func getSelectedAudioLanguage() -> String? {
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: .audible),
           let selectedOption = currentMediaSelection.selectedMediaOption(in: group),
           let languageCode = selectedOption.extendedLanguageTag
        {
            return languageCode
        }

        return nil
    }

    func getSelectedSubtitleLanguage() -> String? {
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: .legible),
           let selectedOption = currentMediaSelection.selectedMediaOption(in: group),
           let languageCode = selectedOption.extendedLanguageTag
        {
            return languageCode
        }

        return nil
    }
}
