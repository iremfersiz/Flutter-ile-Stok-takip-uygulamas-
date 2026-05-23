import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/hotel_login_screen.dart'; 
import 'screens/cost_control/cost_control_menu_screen.dart';
import 'screens/bar_sorumlusu/bar_sorumlusu_transfer_screen.dart';
// ignore: unused_import
import 'screens/user_login_screen.dart'; 

// --- Supabase Kimlik Bilgileri --- (DEĞİŞMEDİ)
const String SUPABASE_URL = 'https://ycwepswykhezonjpmnkp.supabase.co';
const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inljd2Vwc3d5a2hlem9uanBtbmtwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIyNDk2NTYsImV4cCI6MjA3NzgyNTY1Nn0.X89lGD_7HiyNsGJBHm3vyPfwhUpO8lBiCrjUS0-THyE';

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );

  runApp(const StoxierApp());
}

class StoxierApp extends StatefulWidget {
  const StoxierApp({super.key});

  @override
  State<StoxierApp> createState() => _StoxierAppState();
}

class _StoxierAppState extends State<StoxierApp> {
  Widget? _initialWidget;

  // LOGIC: Oturum Kontrolü (DEĞİŞMEDİ)
  @override
  void initState() {
    super.initState();
    _checkRememberMeStatus();
  }

  Future<void> _checkRememberMeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedDepartment = prefs.getString('savedDepartment');

    if (savedDepartment != null) {
      if (savedDepartment == 'COST_CONTROL') {
        _initialWidget = const CostControlMenuScreen();
      } else if (savedDepartment == 'BAR_SORUMLUSU') {
        _initialWidget = const BarSorumlusuTransferScreen();
      }
    } else {
      _initialWidget = const HotelLoginScreen();
    }
    setState(() {});
  }

  // ARABİRİM (UI) KISMI TAMAMEN YENİDEN YAZILDI
  @override
  Widget build(BuildContext context) {
    
    // Sizin seçtiğiniz koyu tema renk paleti
    const Color primaryColor = Color(0xFF8BC34A); // lightGreen.shade400
    const Color darkBackground = Color(0xFF121212); // Koyu Gri
    const Color darkSurface = Color(0xFF1E1E1E);    // Kartlar ve AppBar
    const Color brightText = Colors.white;          // Metinler

    // 1. Bekleme Ekranı (Splash Screen) Modernleştirme
    if (_initialWidget == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Stoxier',
        home: Container(
          color: darkBackground, // Koyu tema arka planı
          child: Center(
            child: CircularProgressIndicator(
              color: primaryColor, // Ana renk ile dönen ikon
            )
          ),
        ),
      );
    }
    
    // 2. Ana Uygulama Teması (Koyu Tema)
    return MaterialApp(
      title: 'Stok Takip',
      debugShowCheckedModeBanner: false,
      
      // Koyu Temayı zorla
      themeMode: ThemeMode.dark, 

      // Karanlık Tema Tanımı
      darkTheme: ThemeData(
        useMaterial3: true, // MODERN görünüm için KRİTİK!
        
        // Koyu Tema Renk Şeması Tanımı
        colorScheme: ColorScheme.dark(
          primary: primaryColor, // Ana İşlem Rengi (Canlı Yeşil)
          secondary: primaryColor, // Secondary de aynı olsun
          
          background: darkBackground, // Arka Plan
          surface: darkSurface,        // Kart, AppBar Yüzeyleri
          
          // Yazı ve İkon Renkleri
          onPrimary: Colors.black, // Yeşil üzerinde siyah (en iyi kontrast)
          onBackground: brightText, 
          onSurface: brightText,
          
          error: Colors.red.shade600, // Hata Rengi
        ),

        // Scaffold, Kart ve AppBar için Kolay Ayarlar
        scaffoldBackgroundColor: darkBackground,
        cardColor: darkSurface,

        // AppBar Tema Ayarları
        appBarTheme: const AppBarTheme(
          backgroundColor: darkSurface, // Koyu Yüzey
          foregroundColor: brightText, // Yazı Rengi
          elevation: 0, // Modern temada gölge yok
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        
        // Input (TextFormField) Tema Ayarları
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: brightText.withOpacity(0.05), // Çok hafif dolgu
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          labelStyle: TextStyle(color: brightText.withOpacity(0.7)),
          hintStyle: TextStyle(color: brightText.withOpacity(0.5)),
          prefixIconColor: brightText.withOpacity(0.7),
        ),
        
        // Buton Temaları
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: _initialWidget,
    );
  }
}