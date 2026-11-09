import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget googleWebButton() => web.renderButton(
      configuration: web.GSIButtonConfiguration(
        theme: web.GSIButtonTheme.filledBlack,
        size: web.GSIButtonSize.large,
        text: web.GSIButtonText.continueWith,
        shape: web.GSIButtonShape.pill,
        locale: 'pt-BR',
        minimumWidth: 300,
      ),
    );
