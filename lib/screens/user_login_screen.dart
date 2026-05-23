import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // supabase nesnesi için
import 'cost_control/cost_control_menu_screen.dart';
import 'bar_sorumlusu/bar_sorumlusu_ana_menu.dart'; // DOĞRU ANA MENÜ BAĞLANDI

class UserLoginScreen extends StatefulWidget {
  final int otelId;
  const UserLoginScreen({super.key, required this.otelId});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  // Tema sabitleri
  static const Color primaryColor = Colors.blue; 
  static const Color screenBackground = Color(0xFFF5F5F5); 
  static const Color cardColor = Colors.white; 
  static const Color darkTextColor = Colors.black87; 
  static const Color dangerColor = Colors.red; 

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRememberMePreference();
  }

  InputDecoration _buildInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: darkTextColor, fontWeight: FontWeight.bold),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      prefixIcon: Icon(icon, color: primaryColor),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    );
  }

  Future<void> _loadRememberMePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        _usernameController.text = prefs.getString('savedUsername') ?? '';
      }
    });
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String username = _usernameController.text.trim();
      final String password = _passwordController.text.trim();

      // Kullanıcıyı veritabanından sorgula
      final response = await supabase
          .from('kullanicilar')
          .select('id, departman, depo_id, depolar(depo_adi)') 
          .eq('otel_id', widget.otelId)
          .eq('kullanici_adi', username)
          .eq('sifre_hash', password)
          .maybeSingle();

      if (response != null) {
        final String departman = response['departman'] as String;
        final int userId = response['id'] as int;
        final int? depotId = response['depo_id'] as int?;
        final String? depotName = response['depolar'] != null ? response['depolar']['depo_adi'] : null;

        final prefs = await SharedPreferences.getInstance();

        // Verileri Şeritte Kaydet
        await prefs.setInt('user_id', userId);
        if (depotId != null) {
          await prefs.setInt('user_depot_id', depotId);
          await prefs.setString('user_depot_name', depotName ?? "Bar");
        }

        await prefs.setBool('rememberMe', _rememberMe);
        if (_rememberMe) {
          await prefs.setString('savedUsername', username);
        }

        // YÖNLENDİRME MERKEZİ
        _navigateToDepartmentScreen(departman);

      } else {
        setState(() => _errorMessage = "Hatalı Kullanıcı Adı veya Şifre!");
      }
    } catch (e) {
      setState(() => _errorMessage = "Bağlantı Hatası: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToDepartmentScreen(String departman) {
    if (departman == 'COST_CONTROL') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const CostControlMenuScreen()),
      );
    } else if (departman == 'BAR_SORUMLUSU') {
      // DÜZELTİLDİ: Barmen artık direkt kendi ANA MENÜ paneline gidiyor.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const BarSorumlusuAnaMenu()),
      );
    } else {
      setState(() => _errorMessage = "Yetkisiz Departman!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        title: const Text('Giriş Yap', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: cardColor,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Icon(Icons.liquor, size: 60, color: primaryColor),
                  const SizedBox(height: 15),
                  const Text('STOK YÖNETİM SİSTEMİ', 
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: darkTextColor)),
                  const SizedBox(height: 30),

                  TextFormField(
                    controller: _usernameController,
                    style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.bold),
                    decoration: _buildInputDecoration('Kullanıcı Adı', Icons.person),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.bold),
                    decoration: _buildInputDecoration('Şifre', Icons.lock),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? false),
                        activeColor: primaryColor,
                      ),
                      const Text('Beni Hatırla', style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
                    ],
                  ),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(_errorMessage!, style: const TextStyle(color: dangerColor, fontWeight: FontWeight.bold)),
                    ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('GİRİŞ YAP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}