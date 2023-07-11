import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

const _DEFAULT_SIZE = 32;

/// Display a Hash then fade to Image
class BlurHash extends StatefulWidget {
  const BlurHash({
    required this.hash,
    Key? key,
    this.imageKey,
    this.color = Colors.blueGrey,
    this.imageFit = BoxFit.fill,
    this.decodingWidth = _DEFAULT_SIZE,
    this.decodingHeight = _DEFAULT_SIZE,
    this.image,
    this.onDecoded,
    this.onDisplayed,
    this.onReady,
    this.onStarted,
    this.onError,
    this.duration = const Duration(milliseconds: 1000),
    this.httpHeaders = const {},
    this.curve = Curves.easeOut,
    this.errorBuilder,
  })  : assert(decodingWidth > 0),
        assert(decodingHeight != 0),
        super(key: key);

  /// Callback when hash is decoded
  final VoidCallback? onDecoded;

  /// Callback when hash is decoded
  final VoidCallback? onDisplayed;

  /// Callback when image is downloaded
  final VoidCallback? onReady;

  /// Callback when image is downloaded
  final VoidCallback? onStarted;

  /// Calback when image is error
  final FutureOr<Image>? onError;

  /// Hash to decode
  final String hash;

  /// Displayed background color before decoding
  final Color color;

  /// How to fit decoded & downloaded image
  final BoxFit imageFit;

  /// Decoding definition
  final int decodingWidth;

  /// Decoding definition
  final int decodingHeight;

  /// Remote resource to download
  final String? image;

  final Duration duration;

  final Curve curve;

  /// Http headers for secure call like bearer
  final Map<String, String> httpHeaders;

  /// Network image errorBuilder
  final ImageErrorWidgetBuilder? errorBuilder;

  // Key to use for the widget
  final Key? imageKey;

  @override
  BlurHashState createState() => BlurHashState();
}

class BlurHashState extends State<BlurHash> {
  late Future<ui.Image> _image;
  late bool loaded;
  late bool loading;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    _decodeImage();
    loaded = false;
    loading = false;
  }

  // @override
  // void didUpdateWidget(BlurHash oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (widget.hash != oldWidget.hash ||
  //       widget.image != oldWidget.image ||
  //       widget.decodingWidth != oldWidget.decodingWidth ||
  //       widget.decodingHeight != oldWidget.decodingHeight) {
  //     _init();
  //   }
  // }

  void _decodeImage() {
    _image = blurHashDecodeImage(
      blurHash: widget.hash,
      width: widget.decodingWidth,
      height: widget.decodingHeight,
    );
    _image.whenComplete(() => widget.onDecoded?.call());
    // .onError((error, stackTrace) {},);
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            // child: StreamBuilder<ui.Image>(
            //   stream: Stream.fromFuture(_image),
            child: FutureBuilder<ui.Image>(
              future: _image,
              builder: (_, snap) => snap.data != null &&
                      snap.data!.debugDisposed == false &&
                      snap.data!.width > 0 &&
                      snap.data!.height > 0 &&
                      !loading &&
                      snap.hasData &&
                      !snap.hasError
                  ? Image(
                      image: UiImage(
                        snap.data!,
                        // key: ValueKey(_image.hashCode),
                        key: widget.key,
                      ),
                      fit: widget.imageFit,
                      errorBuilder: widget.errorBuilder,
                    )
                  : Container(color: widget.color),
            ),
          ),
        ],
      );
}

class UiImage extends ImageProvider<UiImage> {
  final ui.Image image;
  final double scale;
  final Key? key;

  const UiImage(
    this.image, {
    this.key,
    this.scale = 1.0,
  });

  @override
  Future<UiImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<UiImage>(this);

  @override
  ImageStreamCompleter load(UiImage key, DecoderCallback decode) =>
      OneFrameImageStreamCompleter(_loadAsync(key));

  Future<ImageInfo> _loadAsync(UiImage key) async {
    assert(key == this);
    return ImageInfo(image: image, scale: key.scale);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final UiImage typedOther = other;
    return image == typedOther.image && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(image.hashCode, scale);

  @override
  String toString() =>
      '$runtimeType(${describeIdentity(image)}, scale: $scale)';
}
