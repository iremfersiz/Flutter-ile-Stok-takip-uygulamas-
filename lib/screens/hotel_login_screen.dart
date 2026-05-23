import 'package:flutter/material.dart';
import '../main.dart'; 
import 'user_login_screen.dart';

class HotelLoginScreen extends StatefulWidget {
  const HotelLoginScreen({super.key});

  @override
  State<HotelLoginScreen> createState() => _HotelLoginScreenState();
}

class _HotelLoginScreenState extends State<HotelLoginScreen> {
  // Tema sabitlerini, önceki ekranlarla tutarlı olması için tanımlayalım
  static const Color primaryColor = Colors.blue; 
  static const Color screenBackground = Color(0xFFF5F5F5); 

  final TextEditingController _hotelCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false; // Şifre görünürlüğü için state

  // LOGIC: Otel Giriş işlemini yapar ve doğrular (DEĞİŞMEDİ)
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await supabase
          .from('oteller') 
          .select('id') 
          .eq('otel_kimligi', _hotelCodeController.text.trim())
          .eq('sifre', _passwordController.text.trim())
          .maybeSingle(); 

      if (response != null && response.isNotEmpty) {
        final int otelId = response['id'] as int;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => UserLoginScreen(otelId: otelId)),
        );
        _passwordController.clear();
      } else {
        setState(() {
          _errorMessage = "Hatalı Otel Kimliği veya Şifre!";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Giriş hatası: Sunucuya erişilemiyor.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // YARDIMCI WIDGET: Tek tip InputDecoration
  InputDecoration _buildInputDecoration(String labelText, String hintText, IconData icon, [Widget? suffixWidget]) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(color: Colors.black54),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
      ),
      prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.8)),
      suffixIcon: suffixWidget,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    );
  }

  // ARABİRİM (UI) KISMI
  @override
  Widget build(BuildContext context) {
    // Scaffold arka planını diğer ekranlarla uyumlu yap
    return Scaffold(
      backgroundColor: screenBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Uygulama Adı/Logo Alanı
              Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: primaryColor,
              ),
              const SizedBox(height: 10),
              // Başlık
              const Text(
                'STOK TAKİP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lütfen otel kimliğinizle devam edin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 50),

              // Otel Kimliği Alanı
              TextFormField(
                controller: _hotelCodeController,
                keyboardType: TextInputType.text,
                style: const TextStyle(color: Colors.black87),
                decoration: _buildInputDecoration(
                  'Otel Kimliği',
                  'Örn: STXTEST',
                  Icons.apartment,
                ),
              ),
              const SizedBox(height: 20),

              // Otel Şifresi Alanı
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: const TextStyle(color: Colors.black87),
                decoration: _buildInputDecoration(
                  'Otel Şifresi',
                  'Şifrenizi Girin',
                  Icons.lock_outline,
                  // Şifre Göster/Gizle butonu
                  IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Hata Mesajı
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      // Kırmızı tonlarında hafif bir arka plan
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300)
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              
              // Giriş Butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18), 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text(
                        'DEVAM ET',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}