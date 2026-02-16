import 'package:flutter/material.dart';

class AppTheme {
  // --- PALETA DE CORES (HospFlow Identity) ---

  // Azul Navy Profundo (Cor Institucional)
  static const Color primaryModern = Color(0xFF0D47A1);

  // Cores de Fundo
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;

  // Inputs e Bordas
  static const Color inputFill = Color(0xFFE3F2FD);
  static const Color border = Color(0xFFBBDEFB);

  // Textos
  static const Color textDark = Color(0xFF151B26);

  // CORREÇÃO: Definindo ambas as variáveis para compatibilidade
  static const Color textGrey = Color(0xFF64748B);
  static const Color textLight =
      Color(0xFF94A3B8); // Um pouco mais claro que o Grey

  // Status (Feedback Visual)
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color error = Color(0xFFD32F2F);

  // Gradiente (Para o Header do Dashboard)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF0D47A1), // Navy Original
      Color(0xFF1976D2), // Azul um pouco mais claro
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- TEMA GLOBAL DO FLUTTER ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Cores Principais
      primaryColor: primaryModern,
      scaffoldBackgroundColor: background,

      colorScheme: const ColorScheme.light(
        primary: primaryModern,
        secondary: primaryModern, // Accent
        surface: surface,
        error: error,
        tertiary: warning,
      ),

      // Tipografia Padrão
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
        titleLarge: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
        bodyLarge: TextStyle(fontSize: 16, color: textDark),
        bodyMedium: TextStyle(fontSize: 14, color: textGrey),
      ),

      // Estilo dos Cards
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
      ),

      // Estilo da AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryModern,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
      ),

      // Estilo dos Botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryModern,
          foregroundColor: Colors.white,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // Estilo dos Campos de Texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryModern, width: 2),
        ),
        labelStyle: const TextStyle(color: textGrey),
      ),

      // Estilo do Botão Flutuante (FAB)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryModern,
        foregroundColor: Colors.white,
      ),
    );
  }
}
