import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Recomendado para datas PT-BR

// IMPORTS
import 'core/theme/app_theme.dart'; // O tema que criamos antes
import 'presentation/screens/home/tela_inicial.dart'; // A tela movida

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HospFlowApp());
}

class HospFlowApp extends StatelessWidget {
  const HospFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HospFlow',

      // Configuração de Tema Centralizada
      theme: AppTheme.lightTheme,

      // Configuração de Idioma (Importante para o DatePicker)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],

      // Tela Inicial
      home: const TelaInicial(),
    );
  }
}
