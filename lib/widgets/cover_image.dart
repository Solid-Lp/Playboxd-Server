import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Capa de jogo vinda da IGDB. No celular usa cache em disco; no navegador o
// servidor da IGDB não libera CORS, então a imagem é exibida como <img> da página.
class CoverImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;

  // Escurece a imagem (no navegador vira uma camada por cima)
  final Color? color;
  final BlendMode? colorBlendMode;

  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;

  const CoverImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        color: color,
        colorBlendMode: colorBlendMode,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    }

    final image = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      loadingBuilder: placeholder == null
          ? null
          : (context, child, progress) =>
              progress == null ? child : placeholder!(context, imageUrl),
      errorBuilder: errorWidget == null
          ? null
          : (context, error, _) => errorWidget!(context, imageUrl, error),
    );

    if (color == null) return image;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [image, ColoredBox(color: color!)],
      ),
    );
  }
}
