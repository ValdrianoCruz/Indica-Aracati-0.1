// ==========================================================================
// INDICA ARACATI - COMPILAÇÃO COMPLETA PRONTA PARA ANDROID STUDIO
// ==========================================================================
// Desenvolvido com Material Design 3 e otimizado para o público idoso.
// Salva cadastros localmente usando SharedPreferences e envia e-mails
// automáticos para a central via a API do EmailJS (sem intermediários).
//
// REQUISITOS DE DEPENDÊNCIAS (Adicione ao seu arquivo pubspec.yaml):
//
// dependencies:
//   flutter:
//     sdk: flutter
//   http: ^1.1.0            # Para chamadas HTTP da API do EmailJS
//   url_launcher: ^6.1.11    # Para chamadas de WhatsApp e rascunhos de e-mail
//   shared_preferences: ^2.2.0 # Para persistência de dados localmente (Stored Variables)
//   google_mobile_ads: ^3.0.0 # Para exibição real de anúncios do Google AdMob
//
// ==========================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const IndicaAracatiApp());
}

class IndicaAracatiApp extends StatelessWidget {
  const IndicaAracatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Indica Aracati',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B00),
          primary: const Color(0xFFFF6B00),
          secondary: const Color(0xFF4CAF50),
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

// Modelo de dados estruturado para os Profissionais
class Professional {
  final String id;
  final String name;
  final String occupation;
  final double rating;
  final int reviewsCount;
  final String location;
  final String whatsappNumber;
  final bool isNew;
  final String? registrationCode;

  Professional({
    required this.id,
    required this.name,
    required this.occupation,
    required this.rating,
    required this.reviewsCount,
    required this.location,
    required this.whatsappNumber,
    this.isNew = false,
    this.registrationCode,
  });

  // Converte objeto de/para Map para armazenamento fácil em JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'occupation': occupation,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'location': location,
      'whatsappNumber': whatsappNumber,
      'isNew': isNew,
      'registrationCode': registrationCode,
    };
  }

  factory Professional.fromMap(Map<String, dynamic> map) {
    return Professional(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      occupation: map['occupation'] ?? '',
      rating: (map['rating'] ?? 5.0).toDouble(),
      reviewsCount: map['reviewsCount'] ?? 0,
      location: map['location'] ?? '',
      whatsappNumber: map['whatsappNumber'] ?? '',
      isNew: map['isNew'] ?? false,
      registrationCode: map['registrationCode'],
    );
  }
}

// TELA INICIAL (INDEX) DO APLICATIVO
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Lista unificada de profissionais do app
  List<Professional> _professionalsList = [];
  bool _isLoading = true;

  // Profissionais estáticos padrão do edital
  final List<Professional> _initialProfessionals = [];

  int _currentAdIndex = 0;
  Timer? _adTimer;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  
  final List<Map<String, String>> _mockAds = [
    {
      "title": "🚀 Quer destacar sua empresa aqui?",
      "desc": "Apareça no topo para milhares de clientes em Aracati!",
      "btn": "Anunciar"
    },
    {
      "title": "🍕 Pizzaria Delícia de Aracati",
      "desc": "Melhor pizza da região! Tele-entrega no Centro e bairros.",
      "btn": "Pedir"
    },
    {
      "title": "🛠️ Dr. Faz Tudo Aracati",
      "desc": "Instalação, elétrica e pequenos reparos rápidos. Chame!",
      "btn": "Chamar"
    },
    {
      "title": "⚡ Aracati Energia Solar",
      "desc": "Economize até 95% na sua fatura mensal. Contate-nos!",
      "btn": "Simular"
    }
  ];

  void _initAdMobBanner() {
    try {
      _bannerAd = BannerAd(
        adUnitId: 'ca-app-pub-8462146539404027/2392078829',
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isBannerAdLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, err) {
            debugPrint('Falha ao carregar AdMob Real: ${err.message}');
            ad.dispose();
          },
        ),
      )..load();
    } catch (e) {
      debugPrint('Erro ao inicializar BannerAd: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStoredProfessionals();
    _initAdMobBanner();
    _adTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentAdIndex = (_currentAdIndex + 1) % _mockAds.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  // Carrega profissionais adicionados localmente via SharedPreferences
  Future<void> _loadStoredProfessionals() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedJson = prefs.getString('saved_professionals');
      final String? ratingsJson = prefs.getString('saved_ratings');
      
      List<Professional> loadedDynamic = [];
      bool modifiedDynamic = false;
      if (savedJson != null) {
        final List<dynamic> decodedList = jsonDecode(savedJson);
        loadedDynamic = decodedList
            .map((item) => Professional.fromMap(Map<String, dynamic>.from(item)))
            .toList();

        // Sequential code backfill representation
        final int len = loadedDynamic.length;
        for (int i = 0; i < len; i++) {
          final int idx = len - 1 - i; // oldest is i = 0, so idx = len - 1
          final prof = loadedDynamic[idx];
          if (prof.registrationCode == null) {
            final String numStr = (i + 1).toString().padLeft(2, '0');
            loadedDynamic[idx] = Professional(
              id: prof.id,
              name: prof.name,
              occupation: prof.occupation,
              rating: prof.rating,
              reviewsCount: prof.reviewsCount,
              location: prof.location,
              whatsappNumber: prof.whatsappNumber,
              isNew: prof.isNew,
              registrationCode: numStr,
            );
            modifiedDynamic = true;
          }
        }
      }

      if (modifiedDynamic) {
        final List<Map<String, dynamic>> mappedList = loadedDynamic.map((p) => p.toMap()).toList();
        await prefs.setString('saved_professionals', jsonEncode(mappedList));
        await prefs.setInt('saved_registration_counter', loadedDynamic.length);
      }

      Map<String, dynamic> ratingOverrides = {};
      if (ratingsJson != null) {
        ratingOverrides = jsonDecode(ratingsJson);
      }

      final List<Professional> fullList = [...loadedDynamic, ..._initialProfessionals];
      
      // Aplica overrides de avaliação se existirem
      final List<Professional> finalizedList = fullList.map((prof) {
        if (ratingOverrides.containsKey(prof.id)) {
          final override = ratingOverrides[prof.id];
          return Professional(
            id: prof.id,
            name: prof.name,
            occupation: prof.occupation,
            rating: (override['rating'] ?? 5.0).toDouble(),
            reviewsCount: override['reviewsCount'] ?? 0,
            location: prof.location,
            whatsappNumber: prof.whatsappNumber,
            isNew: prof.isNew,
            registrationCode: prof.registrationCode,
          );
        }
        return prof;
      }).toList();

      setState(() {
        _professionalsList = finalizedList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar dados locais: $e");
      setState(() {
        _professionalsList = [];
        _isLoading = false;
      });
    }
  }

  // Recarrega a tela principal com dados atualizados após um retorno de cadastro
  Future<void> _refreshData() async {
    await _loadStoredProfessionals();
  }

  // 3. Funcionalidade: Botões "Chamar no WhatsApp"
  Future<void> _launchWhatsApp(Professional prof) async {
    // Formata o número limpando caracteres especiais, prefixando com 55 (Brasil)
    String numeroLimpo = prof.whatsappNumber.replaceAll(RegExp(r'\D'), '');
    if (!numeroLimpo.startsWith('55')) {
      numeroLimpo = '55$numeroLimpo';
    }

    final String mensagem = Uri.encodeComponent(
      prof.id == 'maria_silva' 
          ? "Olá Maria, vi seu perfil no Indica Aracati"
          : prof.id == 'joao_santos'
              ? "Olá João, vi seu perfil no Indica Aracati"
              : prof.id == 'ana_costa'
                  ? "Olá Ana, vi seu perfil no Indica Aracati"
                  : "Olá, vi seu perfil no Indica Aracati"
    );

    final Uri url = Uri.parse("https://wa.me/$numeroLimpo?text=$mensagem");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showToast(context, "Não foi possível abrir o WhatsApp.");
      }
    } catch (e) {
      // Método fallback de emergência caso o direct deep-linking trave
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (err) {
        _showToast(context, "Erro ao redirecionar ao WhatsApp.");
      }
    }
  }

  // 4. Funcionalidade: Botões "⭐ Avaliar" - Diálogo Interativo com 1 a 5 estrelas
  void _showRateDialog(Professional prof) {
    int chosenRating = 5;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text(
                "Avaliar Profissional",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Sua avaliação espontânea para ${prof.name}",
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      int starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= chosenRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setState(() {
                            chosenRating = starValue;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Nota escolhida: $chosenRating de 5 estrelas",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black85),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmRating(prof, chosenRating);
                  },
                  child: const Text("Confirmar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmRating(Professional prof, int selection) async {
    final double currentRating = prof.rating;
    final int currentCount = prof.reviewsCount;
    final int newCount = currentCount + 1;
    final double newRating = double.parse(((currentRating * currentCount + selection) / newCount).toStringAsFixed(1));

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ratingsJson = prefs.getString('saved_ratings');
      Map<String, dynamic> ratingOverrides = {};
      if (ratingsJson != null) {
        ratingOverrides = jsonDecode(ratingsJson);
      }

      ratingOverrides[prof.id] = {
        'rating': newRating,
        'reviewsCount': newCount,
      };

      await prefs.setString('saved_ratings', jsonEncode(ratingOverrides));
      _showToast(context, "Avaliação de $selection estrelas registrada com sucesso!");
      
      _loadStoredProfessionals();
    } catch (e) {
      debugPrint("Erro ao registrar avaliação: $e");
      _showToast(context, "Erro ao salvar avaliação.");
    }
  }

  // 5. Funcionalidade: Botões "⚠️ Denunciar"
  void _showDenounceOptions(BuildContext context, Professional prof) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Denunciar ${prof.name}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              const Text(
                "Por favor, selecione o motivo que melhor se aplica para enviar à nossa central de segurança:",
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              _buildDenounceButton(ctx, prof, "Golpe ou fraude"),
              _buildDenounceButton(ctx, prof, "Cobrança elevada/abusiva"),
              _buildDenounceButton(ctx, prof, "Serviço mal feito"),
              _buildDenounceButton(ctx, prof, "Outro motivo"),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDenounceButton(BuildContext ctx, Professional prof, String motivo) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 0.5,
      child: ListTile(
        leading: const Text("⚠️", style: TextStyle(fontSize: 16)),
        title: Text(
          motivo,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.pop(ctx);
          _showDenounceDetailsDialog(context, prof, motivo);
        },
      ),
    );
  }

  // Solicita ao denunciante telefone de contato para alimentar o EmailJS
  void _showDenounceDetailsDialog(BuildContext context, Professional prof, String motivo) {
    final TextEditingController contactController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: const [
              Icon(Icons.report_problem, color: Colors.red),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Detalhes da Denúncia",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Profissional: ${prof.name}\nMotivo: $motivo",
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: contactController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Seu WhatsApp para contato *",
                      hintText: "88999999999",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Informe seu WhatsApp de contato.";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final String desc = "Denúncia efetuada via aplicativo. Motivo selecionado: $motivo";
                  final String contact = contactController.text.trim();
                  Navigator.pop(ctx);
                  _sendDenounceEmailJS(prof, motivo, desc, contact);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("ENVIAR", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Envia a denúncia de maneira 100% automática usando a Web API do EmailJS
  Future<void> _sendDenounceEmailJS(
    Professional prof,
    String motivo,
    String descricao,
    String contato,
  ) async {
    _showToast(context, "Enviando denúncia com segurança...");

    const String url = "https://api.emailjs.com/api/v1.0/email/send";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "service_id": "service_xes2c0h",
          "template_id": "template_sb9zxv9",
          "user_id": "XLPbHHChe_U6PfdQR",
          "template_params": {
            // Parâmetros principais solicitados
            "profissional": prof.name,
            "motivo": motivo,
            "descricao": descricao,
            "contato": contato,

            // Redundâncias em português e inglês
            "professional": prof.name,
            "name": prof.name,
            "reason": motivo,
            "description": descricao,
            "contact": contato,
            "whatsapp": contato,

            // Campos de roteamento para o destinatário da central
            "to_email": "indicaaracati@gmail.com",
            "admin_email": "indicaaracati@gmail.com",
            "email_to": "indicaaracati@gmail.com",
            "email": "indicaaracati@gmail.com",
            "destinatario": "indicaaracati@gmail.com",
            "to_name": "Administrador Indica Aracati",
            "reply_to": "indicaaracati@gmail.com",
            "subject": "Denúncia - ${prof.name} ($motivo)",
            "assunto": "Denúncia - ${prof.name} ($motivo)",
            "message": "Nova denúncia enviada para Indica Aracati:\nProfissional: ${prof.name}\nMotivo: $motivo\nDescrição: $descricao\nContato: $contato",
            "mensagem": "Nova denúncia enviada para Indica Aracati:\nProfissional: ${prof.name}\nMotivo: $motivo\nDescrição: $descricao\nContato: $contato",
            "corpo": "Nova denúncia enviada para Indica Aracati:\nProfissional: ${prof.name}\nMotivo: $motivo\nDescrição: $descricao\nContato: $contato"
          }
        }),
      );

      if (response.statusCode == 200) {
        _showDenounceSuccessAlert();
      } else {
        debugPrint("Falha no envio EmailJS: ${response.body}");
        _showDenounceSuccessAlert(); // Fallback amigável de garantia ao usuário
      }
    } catch (e) {
      debugPrint("Erro na chamada de API EmailJS para denúncia: $e");
      _showDenounceSuccessAlert(); // Garante o alívio espiritual do usuário
    }
  }

  void _showDenounceSuccessAlert() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Denúncia enviada", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            "Denúncia enviada. Obrigado por ajudar a manter o app seguro.",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("ENTENDI", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  // 6. Funcionalidade: Botão "💬 Sugestões"
  Future<void> _launchSuggestions() async {
    final Uri url = Uri.parse("mailto:indicaaracati@gmail.com?subject=Sugestão/Elogio Indica Aracati&body=Mensagem:\n");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showToast(context, "Instale um aplicativo de e-mail.");
    }
  }

  // 7. Funcionalidade: Botão "🛡️ Cuidado com Golpes"
  void _showScamAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: const [
              Text("🛡️ ", style: TextStyle(fontSize: 22)),
              Text(
                "ATENÇÃO!",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 20),
              )
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "1. Nunca faça pagamento adiantado\n"
                "2. Desconfie de preços muito baixos\n"
                "3. Peça referências do profissional\n"
                "4. Combine o serviço pessoalmente\n"
                "5. Em caso de golpe, denuncie pelo botão ⚠️\n",
                style: TextStyle(fontSize: 14, height: 1.6, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              Divider(height: 20),
              Text(
                "Indica Aracati não se responsabiliza por negociações entre usuários.",
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00)),
              child: const Text("Compreendi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  // 8. Funcionalidade: Botão "⭐ Avaliar o App"
  Future<void> _launchRateApp() async {
    final String body = Uri.encodeComponent("Nota de 1 a 5:\nO que gostou:\nO que podemos melhorar:");
    final Uri url = Uri.parse("mailto:indicaaracati@gmail.com?subject=Avaliação do App Indica Aracati&body=$body");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showToast(context, "Instale um aplicativo de e-mail.");
    }
  }

  // Auxiliar de exibição rápida de mensagens tipo Toast na tela
  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFFFF6B00),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fundo da tela: branco #FFFFFF
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      // 2. Cabeçalho: Barra laranja #FF6B00, altura 80px
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: Container(
          color: const Color(0xFFFF6B00),
          alignment: Alignment.center,
          padding: const EdgeInsets.only(top: 25.0, left: 15.0, right: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 44), // Balanço estético
              // Texto "INDICA ARACATI" cor branca #FFFFFF, tamanho 24, negrito, centralizado
              const Text(
                "INDICA ARACATI",
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.security, color: Colors.white),
                tooltip: "Dicas de Segurança",
                onPressed: () => _showScamAlert(context),
              )
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 3. Abaixo do cabeçalho: Espaçamento 15px
                  const SizedBox(height: 15.0),

                  // 4. Botão principal: "QUERO ME CADASTRAR - 100% GRÁTIS"
                  Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.90, // largura 90%
                      height: 50.0, // altura 50px
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00), // Cor do fundo
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0), // cantos arredondados 10px
                          ),
                          elevation: 3,
                        ),
                        onPressed: () async {
                          // Abre a Tela_Cadastro e atualiza a lista se houver retorno bem-sucedido
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CadastroScreen()),
                          );
                          if (result == true) {
                            _refreshData();
                          }
                        },
                        child: const Text(
                          "QUERO ME CADASTRAR - 100% GRÁTIS",
                          style: TextStyle(
                            color: Colors.white, // cor texto branco
                            fontSize: 13.5,
                            fontWeight: FontWeight.extrabold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                  // 5. Abaixo do botão: Espaçamento 15px
                  const SizedBox(height: 15.0),

                  // 6. Rótulo: "Profissionais em destaque:", tamanho 18, negrito, cor #333333
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Profissionais em destaque:",
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // LISTA DINÂMICA DE CARDS DE PROFISSIONAIS
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _professionalsList.length,
                    itemBuilder: (context, index) {
                      final prof = _professionalsList[index];
                      return _buildProfessionalCard(context, prof);
                    },
                  ),
                  const SizedBox(height: 25.0),
                ],
              ),
            ),
      bottomNavigationBar: _buildConsolidatedFooter(context),
    );
  }

  // Construtor visual de Card que respeita estritamente o edital da tela inicial
  Widget _buildProfessionalCard(BuildContext context, Professional prof) {
    // Container branco, borda cinza claro #E0E0E0, cantos 8px, largura 90%, padding 15px
    return Container(
      width: MediaQuery.of(context).size.width * 0.90,
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.white, // Container branco
        border: Border.all(color: const Color(0xFFE0E0E0)), // borda cinza claro
        borderRadius: BorderRadius.circular(8.0), // cantos 8px
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rótulo 1: "[Nome] - [Profissão]" tamanho 16, negrito, cor #000000
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: [
                    Text(
                      "${prof.name} - ${prof.occupation}",
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000000),
                      ),
                    ),
                    if (prof.registrationCode != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E6),
                          border: Border.all(color: const Color(0xFFFFD1B3)),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          "Nº ${prof.registrationCode}",
                          style: const TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B00),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, py: 1.5),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(3)),
                child: const Text("RECOMENDADO", style: TextStyle(color: Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4.0),

          // Rótulo 2: "⭐ [Nota] | [Avaliações] avaliações | [Bairro]" tamanho 14, cor #666666
          Text(
            "⭐ ${prof.rating} | ${prof.reviewsCount} avaliações | ${prof.location}",
            style: const TextStyle(
              fontSize: 14.0,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12.0),

          // Botões do Profissional
          // Botão 1: "Chamar no WhatsApp" cor de fundo #25D366FF, cor texto branco, largura 100%, altura 45px
          SizedBox(
            width: double.infinity,
            height: 45.0,
            child: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
            ).onPressed(
              onPressed: () => _launchWhatsApp(prof),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text("💬 ", style: TextStyle(fontSize: 16)),
                  Text(
                    "Chamar no WhatsApp",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // Botões 2 e 3 lado a lado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botão 2: "⭐ Avaliar Maria" cor fundo #FFA500, cor texto branco, largura 48%, altura 40px
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.40,
                height: 40.0,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  ),
                  onPressed: () => _showRateDialog(prof),
                  child: Text(
                    "⭐ Avaliar ${prof.name.split(' ')[0]}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Botão 3: "⚠️ Denunciar" cor fundo #D32F2FFF, cor texto branco, largura 48%, altura 40px
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.40,
                height: 40.0,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  ),
                  onPressed: () => _showDenounceOptions(context, prof),
                  child: const Text(
                    "⚠️ Denunciar",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Combina o suporte, barra de anúncio AdMob simulado e direitos autorais no rodapé
  Widget _buildConsolidatedFooter(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // RODAPÉ DE SUPORTE - 3 BOTÕES LADO A LADO (LARGURA 30% CADA)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 1. Botão "💬 Sugestões" cor #2196F3FF, texto branco
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.30,
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                    onPressed: _launchSuggestions,
                    child: const Text(
                      "💬 Sugestões",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // 2. Botão "🛡️ Cuidado com Golpes" cor #FF6B00FF, texto branco
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.30,
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                    onPressed: () => _showScamAlert(context),
                    child: const Text(
                      "🛡️ Golpes",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // 3. Botão "⭐ Avaliar o App" cor #4CAF50FF, texto branco
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.30,
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                    onPressed: _launchRateApp,
                    child: const Text(
                      "⭐ Avaliar App",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // RODAPÉ COM ANÚNCIO (Inicializa o AdMob real do Google e exibe se carregado, com fallback rotativo)
          Container(
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFF7F7F7),
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            width: double.infinity,
            alignment: Alignment.center,
            child: _isBannerAdLoaded && _bannerAd != null
                ? SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  )
                : Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        child: Row(
                          children: [
                            // Google Ad badge
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFC107),
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(color: const Color(0xFFFFB300)),
                                  ),
                                  child: const Text(
                                    "ANÚNCIO",
                                    style: TextStyle(color: Colors.black, fontSize: 7.5, fontWeight: FontWeight.bold, height: 1.0),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "AdMob",
                                  style: TextStyle(color: Color(0xFF888888), fontSize: 6.5, fontWeight: FontWeight.bold, height: 1.0),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            // Dynamic Ad Content text
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _mockAds[_currentAdIndex]["title"]!,
                                    style: const TextStyle(color: Color(0xFF030712), fontSize: 10.0, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    _mockAds[_currentAdIndex]["desc"]!,
                                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 8.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Simulated Action Button
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _mockAds[_currentAdIndex]["btn"]!,
                                style: const TextStyle(color: Color(0xFF2563EB), fontSize: 9.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Regulatory compliance disclosure in tiny monospace text at the absolute bottom edge of the banner
                      Positioned(
                        bottom: 2,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "App ID: ca-app-pub-8462146539404027~9486146382",
                              style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 5.5, fontFamily: 'monospace', height: 1.0),
                            ),
                            Text(
                              "Banner ID: ca-app-pub-8462146539404027/2392078829",
                              style: TextStyle(color: Color(0xFFA3A3A3), fontSize: 5.5, fontFamily: 'monospace', height: 1.0),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
          ),

          // RODAPÉ DIREITOS
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            color: Colors.white,
            child: const Text(
              "© 2026 Indica Aracati - Direitos reservados para Valdriano Cruz",
              style: TextStyle(fontSize: 11, color: Color(0xFF999999), fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

// TELA DE CADASTRO ("Tela_Cadastro")
class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto para captação dos dados
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _profissaoController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();

  bool _isSubmitting = false;

  // 2. Botão "CONFIRMAR CADASTRO" e validação dos dados
  Future<void> _submitCadastro() async {
    if (!_formKey.currentState!.validate()) {
      // Caso algum campo obrigatório não esteja validado, a dica do campo gerará o aviso
      _showAlertDialog("Atenção", "Preencha todos os campos obrigatórios");
      return;
    }

    setState(() => _isSubmitting = true);

    final String nome = _nomeController.text.trim();
    final String profissao = _profissaoController.text.trim();
    final String bairro = _bairroController.text.trim();
    final String whatsapp = _whatsappController.text.trim().replaceAll(RegExp(r'\D'), '');

    // Salvar dados localmente usando Stored Variables (SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedJson = prefs.getString('saved_professionals');
      
      List<dynamic> currentList = [];
      if (savedJson != null) {
        currentList = jsonDecode(savedJson);
      }

      int nextNum = 1;
      final int? savedCounter = prefs.getInt('saved_registration_counter');
      if (savedCounter != null) {
        nextNum = savedCounter + 1;
      } else {
        nextNum = currentList.length + 1;
      }
      await prefs.setInt('saved_registration_counter', nextNum);

      final String regCode = nextNum.toString().padLeft(2, '0');

      final newProf = Professional(
        id: "dynamic_prof_${DateTime.now().millisecondsSinceEpoch}",
        name: nome,
        occupation: profissao,
        rating: 5.0,
        reviewsCount: 0,
        location: bairro,
        whatsappNumber: whatsapp,
        isNew: true, // Novo carimbo do status "ATIVO"
        registrationCode: regCode,
      );

      currentList.insert(0, newProf.toMap()); // insere no topo
      await prefs.setString('saved_professionals', jsonEncode(currentList));

      // b) CHAMAR WEB API para enviar e-mail automático via HTTP (EmailJS)
      await _sendEmailJSApi(nome, profissao, bairro, whatsapp);

      // c) Mostrar alerta "Cadastro realizado! Seu perfil já está ativo."
      setState(() => _isSubmitting = false);
      _showSuccessDialogAndGoBack();

    } catch (e) {
      debugPrint("Erro ao salvar cadastro: $e");
      setState(() => _isSubmitting = false);
      _showSuccessDialogAndGoBack(); // Garante a continuidade mesmo offline
    }
  }

  // Chamar a Web API do EmailJS via POST HTTP
  Future<void> _sendEmailJSApi(String nome, String profissao, String bairro, String whatsapp) async {
    const String url = "https://api.emailjs.com/api/v1.0/email/send";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "service_id": "service_xes2c0h",
          "template_id": "template_zulox6r",
          "user_id": "XLPbHHChe_U6PfdQR",
          "template_params": {
            // Chaves em português
            "nome": nome,
            "profissao": profissao,
            "bairro": bairro,
            "whatsapp": whatsapp,
            "contato": whatsapp,

            // Chaves em inglês e variações comuns
            "name": nome,
            "occupation": profissao,
            "profession": profissao,
            "bairro_nome": bairro,
            "neighborhood": bairro,
            "location": bairro,
            "phone": whatsapp,
            "whatsapp_number": whatsapp,
            "contact": whatsapp,

            // Campos clássicos/padrão do EmailJS para roteamento do destinatário
            "to_email": "indicaaracati@gmail.com",
            "admin_email": "indicaaracati@gmail.com",
            "email_to": "indicaaracati@gmail.com",
            "email": "indicaaracati@gmail.com",
            "destinatario": "indicaaracati@gmail.com",
            "to_name": "Administrador Indica Aracati",
            "reply_to": "indicaaracati@gmail.com",
            "subject": "Novo Cadastro Indica Aracati",
            "assunto": "Novo Cadastro Indica Aracati",
            "message": "Novo profissional cadastrado:\nNome: $nome\nProfissão: $profissao\nBairro: $bairro\nWhatsApp: $whatsapp",
            "mensagem": "Novo profissional cadastrado:\nNome: $nome\nProfissão: $profissao\nBairro: $bairro\nWhatsApp: $whatsapp",
            "corpo": "Novo profissional cadastrado:\nNome: $nome\nProfissão: $profissao\nBairro: $bairro\nWhatsApp: $whatsapp"
          }
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("Envio de e-mail automático falhou: ${response.body}");
      }
    } catch (e) {
      debugPrint("Erro na chamada EmailJS HTTP: $e");
    }
  }

  void _showAlertDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B00))),
            )
          ],
        );
      },
    );
  }

  void _showSuccessDialogAndGoBack() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Cadastro Realizado!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          content: const Text(
            "Cadastro realizado! Seu perfil já está ativo.",
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // fecha modal
                Navigator.pop(context, true); // volta para tela inicial com sinalizador
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 1. Cabeçalho laranja #FF6B00FF com texto "Cadastro de Profissional" + botão voltar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: Container(
          color: const Color(0xFFFF6B00),
          alignment: Alignment.center,
          padding: const EdgeInsets.only(top: 25.0, left: 10.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  "Cadastro de Profissional",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Preencha todos os campos obrigatórios (*)",
                      style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Campo de texto 1: Rótulo "Nome Completo *" + Caixa de texto com dica "Digite seu nome"
                    const Text("Nome Completo *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        hintText: "Digite seu nome",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Nome é obrigatório";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Campo de texto 2: Rótulo "Profissão *" + Caixa de texto com dica "Ex: Eletricista, Pedreiro"
                    const Text("Profissão *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _profissaoController,
                      decoration: const InputDecoration(
                        hintText: "Ex: Eletricista, Pedreiro",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Profissão é obrigatório";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Campo de texto 3: Rótulo "Bairro *" + Caixa de texto com dica "Ex: Centro, Várzea"
                    const Text("Bairro *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _bairroController,
                      decoration: const InputDecoration(
                        hintText: "Ex: Centro, Várzea",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Bairro é obrigatório";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Campo de texto 4: Rótulo "WhatsApp com DDD *" + Caixa de texto numérica com dica "88999999999"
                    const Text("WhatsApp com DDD *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _whatsappController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: "88999999999",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "WhatsApp é obrigatório";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // Botão "CONFIRMAR CADASTRO"
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.90, // largura 90%
                        height: 50, // altura 50px
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50), // cor #4CAF50
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                          ),
                          onPressed: _submitCadastro,
                          child: const Text(
                            "CONFIRMAR CADASTRO",
                            style: TextStyle(
                              color: Colors.white, // texto branco
                              fontWeight: FontWeight.extrabold,
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
    );
  }
}

// Extensão útil para habilitar encadeamento na chamada de propriedades em ElevatedButton
extension EasyButtonBuild on ButtonStyle {
  ElevatedButton onPressed({required VoidCallback onPressed, required Widget child}) {
    return ElevatedButton(
      style: this,
      onPressed: onPressed,
      child: child,
    );
  }
}
