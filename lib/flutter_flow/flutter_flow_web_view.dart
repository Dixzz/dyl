import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart' hide NavigationDecision;
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

import 'flutter_flow_util.dart';

class FlutterFlowWebView extends StatefulWidget {
  const FlutterFlowWebView({
    Key? key,
    required this.content,
    this.width,
    this.height,
    this.bypass = false,
    this.horizontalScroll = false,
    this.verticalScroll = false,
    this.html = false,
  }) : super(key: key);

  final String content;
  final double? height;
  final double? width;
  final bool bypass;
  final bool horizontalScroll;
  final bool verticalScroll;
  final bool html;

  @override
  FlutterFlowWebViewState createState() => FlutterFlowWebViewState();
}

class FlutterFlowWebViewState extends State<FlutterFlowWebView> {
  WebViewXController? _ref;
  @override
  Widget build(BuildContext context) => WillPopScope(
    onWillPop: () async {
      var ref = _ref;
      if (ref == null) return false;
      if (await ref.canGoBack()) {
        await ref.goBack();
      }
      return false;
    },
    child: WebViewX(
      key: webviewKey,
      width: widget.width ?? MediaQuery.of(context).size.width,
      height: widget.height ?? MediaQuery.of(context).size.height,
      ignoreAllGestures: false,
      initialContent: widget.content,
      initialMediaPlaybackPolicy:
      AutoMediaPlaybackPolicy.requireUserActionForAllMediaTypes,
      initialSourceType: widget.html
          ? SourceType.html
          : widget.bypass
          ? SourceType.urlBypass
          : SourceType.url,
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: (controller) async {
        _ref = controller;
        if (controller.connector is WebViewController && isAndroid) {
          final androidController =
          controller.connector.platform as AndroidWebViewController;
          await androidController.setOnShowFileSelector(_androidFilePicker);
        }
      },
      navigationDelegate: (request) async {
        if (isAndroid) {
          if (request.content.source
              .startsWith('https://api.whatsapp.com/send?phone')) {
            String url = request.content.source;

            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
            return NavigationDecision.prevent;
          }
        }
        return NavigationDecision.navigate;
      },
      webSpecificParams: const WebSpecificParams(
        webAllowFullscreenContent: true,
      ),
      mobileSpecificParams: MobileSpecificParams(
        debuggingEnabled: false,
        gestureNavigationEnabled: true,
        mobileGestureRecognizers: {
          if (widget.verticalScroll)
            Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer(),
            ),
          if (widget.horizontalScroll)
            Factory<HorizontalDragGestureRecognizer>(
                  () => HorizontalDragGestureRecognizer(),
            ),
        },
        androidEnableHybridComposition: true,
      ),
    ),
  );

  Key get webviewKey => Key(
        [
          widget.content,
          widget.width,
          widget.height,
          widget.bypass,
          widget.horizontalScroll,
          widget.verticalScroll,
          widget.html,
        ].map((s) => s?.toString() ?? '').join(),
      );

  Future<List<String>> _androidFilePicker(
    final FileSelectorParams params,
  ) async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      return [file.uri.toString()];
    }
    return [];
  }
}
