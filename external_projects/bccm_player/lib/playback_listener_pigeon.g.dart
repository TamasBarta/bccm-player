// Autogenerated from Pigeon (v3.2.7), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, prefer_null_aware_operators, omit_local_variable_types, unused_shown_name, unnecessary_import
import 'dart:async';
import 'dart:typed_data' show Uint8List, Int32List, Int64List, Float64List;

import 'package:flutter/foundation.dart' show WriteBuffer, ReadBuffer;
import 'package:flutter/services.dart';

class PositionUpdateEvent {
  PositionUpdateEvent({
    this.playbackPositionMs,
  });

  int? playbackPositionMs;

  Object encode() {
    final Map<Object?, Object?> pigeonMap = <Object?, Object?>{};
    pigeonMap['playbackPositionMs'] = playbackPositionMs;
    return pigeonMap;
  }

  static PositionUpdateEvent decode(Object message) {
    final Map<Object?, Object?> pigeonMap = message as Map<Object?, Object?>;
    return PositionUpdateEvent(
      playbackPositionMs: pigeonMap['playbackPositionMs'] as int?,
    );
  }
}

class _PlaybackListenerPigeonCodec extends StandardMessageCodec {
  const _PlaybackListenerPigeonCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is PositionUpdateEvent) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else 
{
      super.writeValue(buffer, value);
    }
  }
  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:       
        return PositionUpdateEvent.decode(readValue(buffer)!);
      
      default:      
        return super.readValueOfType(type, buffer);
      
    }
  }
}
abstract class PlaybackListenerPigeon {
  static const MessageCodec<Object?> codec = _PlaybackListenerPigeonCodec();

  void onPositionUpdate(PositionUpdateEvent event);
  static void setup(PlaybackListenerPigeon? api, {BinaryMessenger? binaryMessenger}) {
    {
      final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.PlaybackListenerPigeon.onPositionUpdate', codec, binaryMessenger: binaryMessenger);
      if (api == null) {
        channel.setMessageHandler(null);
      } else {
        channel.setMessageHandler((Object? message) async {
          assert(message != null, 'Argument for dev.flutter.pigeon.PlaybackListenerPigeon.onPositionUpdate was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final PositionUpdateEvent? arg_event = (args[0] as PositionUpdateEvent?);
          assert(arg_event != null, 'Argument for dev.flutter.pigeon.PlaybackListenerPigeon.onPositionUpdate was null, expected non-null PositionUpdateEvent.');
          api.onPositionUpdate(arg_event!);
          return;
        });
      }
    }
  }
}
