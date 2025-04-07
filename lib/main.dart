import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cmfl12c/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:fullscreen_window/fullscreen_window.dart';

enum BodyPart { head, body, leftArm, rightArm, leftLeg, rightLeg }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String user = "";
  Future<void> checkuser() async {
    String user1 = await FirebaseAuth.instance.currentUser!.uid;
    setState(() {
      user = user1;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkuser();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: user.isEmpty ? Login() : Home(),
    );
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  Future<UserCredential> signInWithGoogleWeb() async {
    // Create a new provider
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      googleProvider.addScope(
        'https://www.googleapis.com/auth/contacts.readonly',
      );
      googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

      // Once signed in, return the UserCredential
      return await FirebaseAuth.instance.signInWithPopup(googleProvider);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
      throw Exception("Google sign-in failed: $e");
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    var a = await FirebaseAuth.instance.signInWithCredential(credential);
    print(a);
    // Once signed in, return the UserCredential
    return a;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            Text(
              "Giriş",
              style: TextStyle(
                fontSize: 36,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text("CMFL12C ye Hoşgeldiniz.", style: TextStyle(fontSize: 18)),
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Text("Google ile giriş yap", style: TextStyle(fontSize: 24)),
            IconButton(
              icon: Image.asset("assets/google.png"),
              onPressed: () {
                if (kIsWeb) {
                  signInWithGoogleWeb().then((value) async {
                    var uid = await FirebaseAuth.instance.currentUser?.uid;
                    var user = await FirebaseAuth.instance.currentUser;
                    var check =
                        await FirebaseFirestore.instance
                            .collection("allusers")
                            .doc("google")
                            .collection("users")
                            .doc(uid)
                            .get();
                    if (check.exists) {
                    } else {
                      await FirebaseFirestore.instance
                          .collection("allusers")
                          .doc("google")
                          .collection("users")
                          .doc(uid)
                          .set({
                            "coin": 100,
                            "name": user?.displayName,
                            "email": user?.email,
                            "photo": user?.photoURL,
                            "uid": user?.uid,
                          });
                    }

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => Home()),
                      (_) => false,
                    );
                  });
                } else {
                  signInWithGoogle().then((value) async {
                    var uid = await FirebaseAuth.instance.currentUser?.uid;
                    var user = await FirebaseAuth.instance.currentUser;
                    var check =
                        await FirebaseFirestore.instance
                            .collection("allusers")
                            .doc("google")
                            .collection("users")
                            .doc(uid)
                            .get();
                    if (check.exists) {
                    } else {
                      await FirebaseFirestore.instance
                          .collection("allusers")
                          .doc("google")
                          .collection("users")
                          .doc(uid)
                          .set({
                            "coin": 100,
                            "name": user?.displayName,
                            "email": user?.email,
                            "photo": user?.photoURL,
                            "uid": user?.uid,
                          });
                    }

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => Home()),
                      (_) => false,
                    );
                  });
                }
              },
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            Text("veya", style: TextStyle(fontSize: 18)),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signInAnonymously().then((
                    value,
                  ) async {
                    await FirebaseFirestore.instance
                        .collection("allusers")
                        .doc("anonymous")
                        .collection("users")
                        .doc(value.user?.uid)
                        .set({
                          "coin": 100,
                          "name": value.user?.uid,
                          "uid": value.user?.uid,
                        });
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => Home()),
                      (_) => false,
                    );
                  });
                } on FirebaseAuthException catch (e) {
                  switch (e.code) {
                    case "operation-not-allowed":
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Misafir girişine izin verilmedi."),
                        ),
                      );
                      break;
                    default:
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.code)));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              child: Text(
                "Misafir olarak devam et",
                style: TextStyle(fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String name = "";
  String photourl = "";
  String coin = "";
  String username = "";
  TextEditingController usernameController = TextEditingController();
  checkusername() async {
    if (FirebaseAuth.instance.currentUser!.isAnonymous) {
      username = FirebaseAuth.instance.currentUser!.uid;
    } else {
      if (username.isEmpty) {
        await showDialog(
          context: context,
          barrierDismissible: false, // dışarı tıklayınca kapanmaz
          builder: (context) {
            return AlertDialog(
              title: Text("Kullanıcı Adı Seç"),
              content: TextFormField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: "Kullanıcı Adı",
                  hintText: "Bir kullanıcı adı gir",
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (usernameController.text.trim().isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection("allusers")
                          .doc("google")
                          .collection("users")
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .update({"username": usernameController.text.trim()})
                          .then((value) {
                            setState(() {
                              username = usernameController.text.trim();
                            });
                            Navigator.of(
                              context,
                            ).pop(usernameController.text.trim());
                          });
                    }
                    // boşsa hiçbir şey yapma, dialog kapanmasın
                  },
                  child: Text("Tamam"),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> getuserdata() async {
    await FirebaseAuth.instance.currentUser!.isAnonymous
        ? await FirebaseFirestore.instance
            .collection("allusers")
            .doc("anonymous")
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get()
            .then((value) {
              setState(() {
                name = value.data()!["name"];
                photourl =
                    value.data()?["photo"] ??
                    "https://i1.sndcdn.com/avatars-000384010493-s9f71b-t500x500.jpg";
                coin = value.data()!["coin"].toString();
                username = value.data()?["username"] ?? "";
              });
            })
        : await FirebaseFirestore.instance
            .collection("allusers")
            .doc("google")
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .get()
            .then((value) {
              setState(() {
                name = value.data()!["name"];
                photourl =
                    value.data()?["photo"] ??
                    "https://i1.sndcdn.com/avatars-000384010493-s9f71b-t500x500.jpg";
                coin = value.data()!["coin"].toString();
                username = value.data()?["username"] ?? "";
              });
            });

    await FirebaseAuth.instance.currentUser!.isAnonymous
        ? await FirebaseFirestore.instance
            .collection("allusers")
            .doc("anonymous")
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots()
            .listen((value) {
              setState(() {
                name = value.data()!["name"];
                photourl =
                    value.data()?["photo"] ??
                    "https://i1.sndcdn.com/avatars-000384010493-s9f71b-t500x500.jpg";
                coin = value.data()!["coin"].toString();
              });
            })
        : await FirebaseFirestore.instance
            .collection("allusers")
            .doc("google")
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots()
            .listen((value) {
              setState(() {
                name = value.data()!["name"];
                photourl =
                    value.data()?["photo"] ??
                    "https://i1.sndcdn.com/avatars-000384010493-s9f71b-t500x500.jpg";
                coin = value.data()!["coin"].toString();
              });
            });
  }

  @override
  void initState() {
    getuserdata().then((value) {
      checkusername();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown, // küçülte küçülte sığdır
          child: Text(username),
        ),
        actions: [
          Text(coin, style: TextStyle(fontSize: 36)),
          Icon(Icons.currency_lira_outlined, size: 36),
          SizedBox(width: MediaQuery.of(context).size.width * 0.1),
        ],
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OptionsAdamAsmaca()),
                    );
                  },
                  child: Card(
                    child: Column(
                      children: [
                        Text(
                          "Adam Asmaca",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Container(
                          height: 150,
                          width: 150,
                          child: Image.asset(
                            "assets/adam.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                     
    bool frekansli = false;
    int zorluk = 5;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Wordle Ayarları"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text("Frekans Temelli Oyna"),
                  value: frekansli,
                  onChanged: (val) => setState(() => frekansli = val),
                ),
                if (frekansli)
                  Column(
                    children: [
                      const Text("Zorluk Seviyesi (1-10)"),
                      Slider(
                        value: zorluk.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: zorluk.toString(),
                        onChanged: (val) => setState(() => zorluk = val.toInt()),
                      ),
                    ],
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("İptal"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    WordleSettings(
                      frekansTemelli: frekansli,
                      zorlukSeviyesi: zorluk,
                    ),
                  );
                },
                child: const Text("Başla"),
              ),
            ],
          ),
        );
      },
    ).then((settings) {
      if (settings is WordleSettings) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WordleGame(settings: settings),
          ),
        );
      }
    });
  
                  },
                  child: Card(
                    child: Column(
                      children: [
                        Text(
                          "Wordle",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Container(
                          height: 150,
                          width: 150,
                          child: Image.asset(
                            "assets/wordle.jpeg",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PekYakinda()),
                  );
                },
                child: Card(
                  child: Column(
                    children: [
                      Text(
                        "Kelime Oyunu",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Container(
                        height: 150,
                        width: 150,
                        child: Image.asset(
                          "assets/kelime.jpg",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PekYakinda()),
                    );
                  },
                  child: Card(
                    child: Column(
                      children: [
                        Text(
                          "Parolla",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Container(
                          height: 150,
                          width: 150,
                          child: Image.asset(
                            "assets/parolla.jpg",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PekYakinda()),
                    );
                  },
                  child: Card(
                    child: Column(
                      children: [
                        Text(
                          "Çengel Bulmaca",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Container(
                          height: 150,
                          width: 150,
                          child: Image.asset(
                            "assets/cengel.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class PekYakinda extends StatefulWidget {
  const PekYakinda({super.key});

  @override
  State<PekYakinda> createState() => _PekYakindaState();
}

class _PekYakindaState extends State<PekYakinda> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("Geri"),), body: Center(child: Text("Pek Yakında...",style: TextStyle(fontSize: 48),),),);
  }
}
class WordleSettings {
  final bool frekansTemelli;
  final int zorlukSeviyesi;

  WordleSettings({
    required this.frekansTemelli,
    required this.zorlukSeviyesi,
  });
}

class WordleGame extends StatefulWidget {
    final WordleSettings settings;

  const WordleGame({super.key, required this.settings});

  @override
  State<WordleGame> createState() => _WordleGameState();
}

class _WordleGameState extends State<WordleGame> {
  List<Map<String, dynamic>> allWordData = [];
  List<String> validWordList = [];

  String targetWord = "";
  String targetJsonMeaning = "";
  String targetCsvMeaning = "";

  List<String> guesses = List.filled(6, "");
  List<List<Color>> guessColors = List.generate(
    6,
    (_) => List.filled(5, Colors.grey[300]!),
  );
  final Map<String, Color> letterStatus = {};

  int currentRow = 0;
  Timer? timer;
  int secondsPassed = 0;
  bool gameEnded = false;
  bool isWin = false;

  final List<String> keyboardRows = ['ERTYUIOPĞÜ', 'ASDFGHJKLŞ', 'İZCVBNMÖÇ'];

  @override
  void initState() {
    super.initState();
    loadWords();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!gameEnded) {
        setState(() {
          secondsPassed++;
        });
      }
    });
  }

Future<void> loadWords() async {
  final String jsonWordle = await rootBundle.loadString(
    'assets/wordle_oyun_kelimeleri_frekansli_full.json',
  );
  final String jsonValid = await rootBundle.loadString(
    'assets/tum_5harfli_kelimeler.json',
  );

  final List<dynamic> wordleList = jsonDecode(jsonWordle);
  final List<dynamic> validList = jsonDecode(jsonValid);

  List<Map<String, dynamic>> kelimeler = wordleList
      .where((item) =>
          item is Map<String, dynamic> &&
          item["kelime"] != null &&
          item["json_anlam"] != null &&
          item["csv_anlam"] != null)
      .cast<Map<String, dynamic>>()
      .toList();

  if (widget.settings.frekansTemelli) {
    kelimeler = kelimeler.where((e) => e["grup"] == widget.settings.zorlukSeviyesi).toList();
  }

  allWordData = kelimeler
      .map((e) => {
            "kelime": turkishToUpper(e["kelime"]),
            "json_anlam": e["json_anlam"],
            "csv_anlam": e["csv_anlam"],
          })
      .toList();

  validWordList = validList.map((e) => turkishToUpper(e.toString())).toList();

  if (allWordData.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bu ayarlar için uygun kelime bulunamadı.")),
    );
    return;
  }

  allWordData.shuffle(Random());
  final randomItem = allWordData.first;

  setState(() {
    targetWord = randomItem["kelime"];
    targetJsonMeaning = randomItem["json_anlam"];
    targetCsvMeaning = randomItem["csv_anlam"];
  });
}



  void addLetter(String letter) {
    if (gameEnded) return;
    if (guesses[currentRow].length < 5) {
      setState(() {
        guesses[currentRow] += letter;
      });
    }
  }

  void removeLetter() {
    if (gameEnded) return;
    if (guesses[currentRow].isNotEmpty) {
      setState(() {
        guesses[currentRow] = guesses[currentRow].substring(
          0,
          guesses[currentRow].length - 1,
        );
      });
    }
  }

  void submitGuess() {
    if (gameEnded) return;
    if (guesses[currentRow].length != 5) {
      _showSnackBar("Lütfen 5 harf girin!");
      return;
    }

    final guess = guesses[currentRow];

    final bool isValid = validWordList.contains(guess);
    if (!isValid) {
      _showSnackBar("Bu kelime geçerli değil!");
      return;
    }

    _colorizeGuess(currentRow, guess, targetWord);

    if (guess == targetWord) {
      setState(() {
        isWin = true;
        gameEnded = true;
      });
      rewardUser();
      _showResultDialog();
    } else if (currentRow == 5) {
      setState(() {
        gameEnded = true;
      });
      _showResultDialog();
    } else {
      setState(() {
        currentRow++;
      });
    }
  }

  void _colorizeGuess(int rowIndex, String guess, String solution) {
    final Map<String, int> targetLetterCount = {};
    for (final c in solution.split('')) {
      targetLetterCount[c] = (targetLetterCount[c] ?? 0) + 1;
    }

    final List<Color> rowColors = List.filled(5, Colors.grey);
    final tempCounts = Map<String, int>.from(targetLetterCount);

    for (int i = 0; i < 5; i++) {
      final gChar = guess[i];
      if (solution[i] == gChar) {
        rowColors[i] = Colors.green;
        tempCounts[gChar] = tempCounts[gChar]! - 1;
      }
    }

    for (int i = 0; i < 5; i++) {
      final gChar = guess[i];
      if (rowColors[i] == Colors.green) continue;
      if (tempCounts[gChar] != null && tempCounts[gChar]! > 0) {
        rowColors[i] = Colors.yellow[700]!;
        tempCounts[gChar] = tempCounts[gChar]! - 1;
      } else {
        rowColors[i] = Colors.grey;
      }
    }

    setState(() {
      guessColors[rowIndex] = rowColors;
    });

    for (int i = 0; i < 5; i++) {
      final gChar = guess[i];
      final color = rowColors[i];
      final currentBest = letterStatus[gChar] ?? Colors.blue;
      if (color == Colors.green) {
        letterStatus[gChar] = Colors.green;
      } else if (color == Colors.yellow[700]) {
        if (currentBest != Colors.green) {
          letterStatus[gChar] = Colors.yellow[700]!;
        }
      } else {
        if (currentBest == Colors.blue) {
          letterStatus[gChar] = Colors.grey;
        }
      }
    }
  }

  void rewardUser() {
    FirebaseFirestore.instance
        .collection("allusers")
        .doc(
          FirebaseAuth.instance.currentUser!.isAnonymous
              ? "anonymous"
              : "google",
        )
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({"coin": FieldValue.increment(5)});
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isWin ? "🎉 Bildin Baba!" : "Kaybettin!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Kelime: $targetWord",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("📖 JSON Anlam: $targetJsonMeaning"),
              Text("📚 CSV Anlam: $targetCsvMeaning"),
              const SizedBox(height: 16),
              Text("Geçen süre: $secondsPassed saniye"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => WordleGame(settings: widget.settings,)),
                );
              },
              child: const Text("Tekrar Oyna"),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String turkishToUpper(String input) {
    const specialMap = {
      'i': 'İ',
      'ş': 'Ş',
      'ğ': 'Ğ',
      'ü': 'Ü',
      'ö': 'Ö',
      'ç': 'Ç',
      'ı': 'I',
    };
    return input.split('').map((c) => specialMap[c] ?? c.toUpperCase()).join();
  }

  Widget buildGrid() {
    return Column(
      children: List.generate(6, (row) {
        final guess = guesses[row].padRight(5);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final letter = guess[index];
            final color = guessColors[row][index];
            return Container(
              margin: const EdgeInsets.all(4),
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                letter,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget buildKeyboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final letters = 'ERTYUIOPĞÜASDFGHJKLŞİZCVBNMÖÇ'.split('');

        final int rowCount = isMobile ? 6 : 3;
        final int perRow = (letters.length / rowCount).ceil();
        final List<List<String>> letterRows = [];

        for (int i = 0; i < rowCount; i++) {
          final start = i * perRow;
          final end = (i + 1) * perRow;
          letterRows.add(
            letters.sublist(start, end > letters.length ? letters.length : end),
          );
        }

        final List<Widget> rows = [];

        for (int i = 0; i < letterRows.length; i++) {
          final row = letterRows[i];
          rows.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isMobile && i == 0) ...[
                    ElevatedButton(
                      onPressed: removeLetter,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        backgroundColor: Colors.orange,
                      ),
                      child: const Icon(
                        Icons.backspace_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  ...row.map((letter) {
                    final color = letterStatus[letter] ?? Colors.blue;
                    return Padding(
                      padding: const EdgeInsets.all(2),
                      child: ElevatedButton(
                        onPressed: () => addLetter(letter),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(36, 48),
                          backgroundColor: color,
                        ),
                        child: Text(
                          letter,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  if (!isMobile && i == letterRows.length - 1) ...[
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: submitGuess,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        '↩',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        // Mobilde geri & enter tuşları en altta ayrı satırda
        if (isMobile) {
          rows.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: removeLetter,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(60, 48),
                      backgroundColor: Colors.orange,
                    ),
                    child: const Icon(
                      Icons.backspace_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: submitGuess,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(60, 48),
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      '↩',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(children: rows);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (targetWord.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Wordle - Türkçe")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Süre: $secondsPassed sn",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 12),
              buildGrid(),
              const SizedBox(height: 12),
              buildKeyboard(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

class OptionsAdamAsmaca extends StatefulWidget {
  const OptionsAdamAsmaca({super.key});

  @override
  State<OptionsAdamAsmaca> createState() => _OptionsAdamAsmacaState();
}

class _OptionsAdamAsmacaState extends State<OptionsAdamAsmaca> {
  final TextEditingController customTopicController = TextEditingController();

  String selectedCategory = "Rastgele";
  String selectedAiModel = "GPT-4";

  final List<int> gameOptions = [5, 10, 15, 20];
  final List<String> categories = [
    "Rastgele",
    "Meyveler",
    "Sebzeler",
    "Hayvanlar",
    "Meslekler",
    "Ülkeler",
    "Türk Şehirler",
    "Tarihi Kişilikler",
    "Türk Ünlüler",
    "Teknoloji Terimleri",
    "Bilimsel Kavramlar",
    "Gezegenler",
    "Mitoloji",
    "Spor Dalları",
    "Futbol Takımları",
    "Yemekler",
    "İçecekler",
    "Mutfak Eşyaları",
    "Ev Eşyaları",
    "Türk Film İsimleri",
    "Türk Dizi İsimleri",
    "Çizgi Film Karakterleri",
    "Oyun Karakterleri",
    "Türk Atasözleri",
    "Deyimler",
    "Hayali Varlıklar",
    "Silahlar",
    "Müzik Aletleri",
    "Renkler",
    "Taşıtlar",
    "Aile Üyeleri",
    "Okul Dersleri",
    "Doğa Olayları",
    "Türkçe Zor Kelimeler",
    "Özel Konu",
  ];
  bool isLoading = false;
  String? errorMessage;

  // ilk varsayılan konu
  // varsayılan AI
  int selectedGameCount = 10; // kaç kelime alınacak (10 öneri)

  final List<String> aiModels = ["GPT-4", "GPT-3.5 Turbo", "Gemini AI"];

  Future<List<KelimeModel>> rastgeleKelimelerGetir(int adet) async {
    final String jsonString = await rootBundle.loadString(
      'assets/turkce_sozluk_map_full.json',
    );
    final List<dynamic> data = jsonDecode(jsonString);

    final List<KelimeModel> tumKelimeler =
        data
            .map<KelimeModel>((e) => KelimeModel.fromJson(e))
            .where(
              (kelime) =>
                  kelime.kelime.length > 2 && kelime.anlamlar.isNotEmpty,
            )
            .toList();

    tumKelimeler.shuffle(Random());
    return tumKelimeler.take(adet).toList();
  }

  Future<void> generateWords() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final String konu =
        customTopicController.text.trim().isNotEmpty
            ? customTopicController.text.trim()
            : selectedCategory;

    final prompt = '''
Sen bir yapay zeka asistanısın. Sadece geçerli bir JSON nesnesi döndürmelisin.

Lütfen "$konu" konusunda toplam $selectedGameCount adet Türkçe kelime veya kelime grubu üret ve aşağıdaki JSON formatına uygun döndür:

{
  "words": ["kelime1", "kelime2", "kelime3", "..."]
}

Sadece geçerli JSON döndür. Açıklama veya \`\`\` işareti ekleme. UTF-8 ver, bozuk karakter verme.
''';

    try {
      if (selectedAiModel == "GPT-4" || selectedAiModel == "gpt-3.5-turbo") {
        final modelName =
            selectedAiModel == "GPT-4" ? "gpt-4" : "gpt-3.5-turbo";
        final apiKey =
            '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';
        final url = 'https://api.openai.com/v1/chat/completions';

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': modelName,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.7,
          }),
        );

        if (response.statusCode != 200) {
          throw Exception(
            'API Hatası: ${response.statusCode} ${response.body}',
          );
        }

        String content = utf8.decode(response.bodyBytes);
        final data = jsonDecode(content);

        content =
            data['choices'][0]['message']['content']
                .replaceAll(RegExp(r'```json|```'), '')
                .replaceAll(RegExp(r'[\r\n]+'), ' ')
                .trim();

        final jsonData = jsonDecode(content);
        if (jsonData['words'] == null || !(jsonData['words'] is List)) {
          throw Exception("Kelime listesi alınamadı.");
        }

        final List<String> wordList = List<String>.from(jsonData['words']);

        List<String> meanlar = List.generate(
          wordList.length,
          (_) => "Yapay Zeka da ipucu yok",
        );

        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => AdamAsmacaMain(
                  words: wordList,
                  means: meanlar.take(selectedGameCount).toList(),
                ),
          ),
        );
      } else if (selectedAiModel == "Gemini AI") {
        final apiKey = 'AIzaSyB...'; // gizli Gemini API key
        final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

        final response = await model.generateContent([Content.text(prompt)]);
        String? jsonString = response.text?.trim();

        if (jsonString == null) throw Exception("Yanıt boş geldi.");
        jsonString = jsonString.replaceAll(RegExp(r'```json|```'), '').trim();

        final jsonData = jsonDecode(jsonString);
        if (jsonData['words'] == null || !(jsonData['words'] is List)) {
          throw Exception("Kelime listesi alınamadı.");
        }

        final List<String> wordList = List<String>.from(jsonData['words']);

        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => AdamAsmacaMain(
                  words: wordList,
                  means: List.generate(
                    wordList.length,
                    (_) => "Yapay Zeka da ipucu yok",
                  ),
                ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata oluştu: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Adam Asmaca Ayarları")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: const Text(
                        "Kaç oyun oynansın?",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    Center(
                      child: DropdownButton<int>(
                        value: selectedGameCount,
                        items:
                            gameOptions.map((count) {
                              return DropdownMenuItem(
                                value: count,
                                child: Text("$count Oyun"),
                              );
                            }).toList(),
                        onChanged:
                            isLoading
                                ? null
                                : (value) {
                                  setState(() {
                                    selectedGameCount = value!;
                                  });
                                },
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        int selectedDifficulty =
                            5; // Varsayılan zorluk seviyesi

                        await showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text(
                                  "Frekans Temelli Zorluk Seçimi",
                                ),
                                content: StatefulBuilder(
                                  builder:
                                      (context, setState) => Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text("1 = Kolay / 10 = Zor"),
                                          Slider(
                                            min: 1,
                                            max: 10,
                                            divisions: 9,
                                            value:
                                                selectedDifficulty.toDouble(),
                                            label: "$selectedDifficulty",
                                            onChanged:
                                                (value) => setState(() {
                                                  selectedDifficulty =
                                                      value.toInt();
                                                }),
                                          ),
                                        ],
                                      ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(
                                        context,
                                      ); // önce popup'ı kapat

                                      await Future.delayed(
                                        Duration(milliseconds: 100),
                                      ); // küçük bir gecikme, güvenlik için

                                      if (!context.mounted) return;

                                      final String
                                      jsonString = await rootBundle.loadString(
                                        'assets/frekans_gruplu_sozluk_ortaklar.json',
                                      );
                                      final Map<String, dynamic> jsonMap =
                                          jsonDecode(jsonString);
                                      final String grupKey =
                                          selectedDifficulty.toString();

                                      if (!jsonMap.containsKey(grupKey)) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Bu zorluk seviyesi için kelime bulunamadı.",
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final List<dynamic> kelimelerHam =
                                          jsonMap[grupKey];
                                      if (kelimelerHam.isEmpty) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("Bu grup boş."),
                                          ),
                                        );
                                        return;
                                      }

                                      kelimelerHam.shuffle();
                                      final List<dynamic> secilen =
                                          kelimelerHam
                                              .take(selectedGameCount)
                                              .toList();

                                      final List<KelimeModel> kelimeler =
                                          secilen.map<KelimeModel>((item) {
                                            return KelimeModel(
                                              kelime: item["kelime"],
                                              anlamlar: List<String>.from(
                                                item["anlamlar"] ??
                                                    ["Frekansa dayalı oyun"],
                                              ),
                                            );
                                          }).toList();

                                      if (!context.mounted) return;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => AdamAsmacaMain(
                                                words:
                                                    kelimeler
                                                        .map((e) => e.kelime)
                                                        .toList(),
                                                means:
                                                    kelimeler
                                                        .map(
                                                          (e) =>
                                                              e.anlamlar.first,
                                                        )
                                                        .toList(),
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text("Tamam"),
                                  ),
                                ],
                              ),
                        );
                      },
                      child: const Text("🌺 Frekans Temelli Oyna"),
                    ),

                    const SizedBox(height: 24),
                    Center(
                      child: const Text(
                        "Yapay Zeka",
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedCategory,
                            isExpanded: true,
                            items:
                                categories.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  );
                                }).toList(),
                            onChanged:
                                isLoading
                                    ? null
                                    : (value) {
                                      setState(() {
                                        selectedCategory = value!;
                                        customTopicController
                                            .clear(); // elle konu seçilince text temizlensin
                                      });
                                    },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: customTopicController,
                            decoration: const InputDecoration(
                              hintText: "Konu yaz (isteğe bağlı)",
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            onChanged: (value) {
                              if (value.trim().isNotEmpty) {
                                setState(() {
                                  selectedCategory = "Özel Konu";
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    Center(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : generateWords,
                        child: const Text("Yapay Zeka İle Oluştur"),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: const Text(
                        "Sözlük",
                        style: TextStyle(fontSize: 30),
                      ),
                    ),
                    Center(
                      child: ElevatedButton(
                        onPressed:
                            isLoading
                                ? null
                                : () async {
                                  // BURADA OLUŞTURMA LOJİĞİNİ YAZARSIN
                                  List<KelimeModel> kelimeler =
                                      await rastgeleKelimelerGetir(
                                        selectedGameCount,
                                      );
                                  print(
                                    kelimeler
                                        .map((kelime) => kelime.kelime)
                                        .toList(),
                                  );
                                  print(
                                    kelimeler
                                        .map((kelime) => kelime.anlamlar)
                                        .toList(),
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => AdamAsmacaMain(
                                            means:
                                                kelimeler
                                                    .map(
                                                      (kelime) =>
                                                          kelime.anlamlar,
                                                    )
                                                    .toList()
                                                    .map(
                                                      (anlamlar) => anlamlar[0],
                                                    )
                                                    .toList(),
                                            words:
                                                kelimeler
                                                    .map(
                                                      (kelime) => kelime.kelime,
                                                    )
                                                    .toList(),
                                          ),
                                    ),
                                  );
                                },
                        child: const Text(
                          "🇹🇷 Türkçe Sözlük Kullanarak Rastgele Oluştur",
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class KelimeModel {
  final String kelime;
  final List<String> anlamlar;

  KelimeModel({required this.kelime, required this.anlamlar});

  factory KelimeModel.fromJson(Map<String, dynamic> json) {
    return KelimeModel(
      kelime: json['kelime'],
      anlamlar: List<String>.from(json['anlamlar'] ?? []),
    );
  }
}

class AdamAsmacaMain extends StatefulWidget {
  final List<String> words; // oyun kelimeleri dışarıdan alınır
  final List<String> means;

  const AdamAsmacaMain({super.key, required this.words, required this.means});

  @override
  State<AdamAsmacaMain> createState() => _AdamAsmacaMainState();
}

class _AdamAsmacaMainState extends State<AdamAsmacaMain> {
  int currentWordIndex = 0;
  bool isGameOver = false;
  bool isGameOverwin = false;
  bool isai = false;
  void checkai() {
    if (widget.means[currentWordIndex] == "Yapay Zeka da ipucu yok") {
      setState(() {
        isai = true;
      });
    }
  }

  int para = 0;
  void nextWord() {
    if (currentWordIndex < widget.words.length - 1) {
      setState(() {
        currentWordIndex++;
      });
    } else {
      // Tüm kelimeler başarıyla bilindi
      setState(() {
        isGameOverwin = true;
      });
      para =
          (widget.words.length * widget.words.length * (isai ? 0.2 : 1)) as int;
      FirebaseFirestore.instance
          .collection("allusers")
          .doc(
            FirebaseAuth.instance.currentUser!.isAnonymous
                ? "anonymous"
                : "google",
          )
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .update({"coin": FieldValue.increment(para)});

      Future.delayed(Duration(seconds: 3), () {
        if (context.mounted) {
          Navigator.of(context).pop(); // Ana sayfaya dön
        }
      });
    }
  }

  void endGame() {
    setState(() {
      isGameOver = true;
    });
  }

  @override
  void initState() {
    checkai();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (isGameOver) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "💀 Oyun Bitti",
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Kelime: ${widget.words[currentWordIndex]}",
                style: TextStyle(fontSize: 24),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => Home()),
                    (_) => false,
                  );
                },
                child: Text("Ana Menü", style: TextStyle(fontSize: 24)),
              ),
            ],
          ),
        ),
      );
    } else if (isGameOverwin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "👑 Oyun Bitti",
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Tebrikler $para ₺ kazandınız!",
                style: TextStyle(fontSize: 24),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => Home()),
                    (_) => false,
                  );
                },
                child: Text("Ana Menü", style: TextStyle(fontSize: 24)),
              ),
            ],
          ),
        ),
      );
    }

    return AdamAsmaca(
      total: widget.words.length,
      index: currentWordIndex,
      word: widget.words[currentWordIndex],
      mean: widget.means[currentWordIndex],
      onSuccess: nextWord,
      onFail: endGame,
    );
  }
}

class AdamAsmaca extends StatefulWidget {
  final String mean;
  final int total;
  final int index;
  final String word;
  final VoidCallback onSuccess;
  final VoidCallback onFail;
  const AdamAsmaca({
    super.key,
    required this.index,
    required this.mean,
    required this.total,
    required this.word,
    required this.onSuccess,
    required this.onFail,
  });

  @override
  State<AdamAsmaca> createState() => _AdamAsmacaState();
}

class _AdamAsmacaState extends State<AdamAsmaca> {
  int coin = 0;
  Future<void> getcoin() async {
    await FirebaseAuth.instance.currentUser!.isAnonymous
        ? await FirebaseFirestore.instance
            .collection("allusers")
            .doc("anonymous")
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots()
            .listen((value) {
              setState(() {
                coin = value.data()!["coin"];
              });
            })
        : await FirebaseFirestore.instance
            .collection("allusers")
            .doc("google")
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots()
            .listen((value) {
              setState(() {
                coin = value.data()!["coin"];
              });
            });
  }

  @override
  void initState() {
    getcoin();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.index + 1} / ${widget.total}"),
        actions: [
          Text(coin.toString(), style: TextStyle(fontSize: 36)),
          Icon(Icons.currency_lira_outlined, size: 36),
          SizedBox(width: MediaQuery.of(context).size.width * 0.1),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/cmfl.jpeg"),
            fit: BoxFit.cover,
          ),
        ),
        child: HangmanLayout(
          wide: wide,
          word: widget.word,
          mean: widget.mean,
          onSuccess: widget.onSuccess,
          onFail: widget.onFail,
        ),
      ),
    );
  }
}

class HangmanLayout extends StatefulWidget {
  final String mean;
  final bool wide;
  final String word;
  final VoidCallback onSuccess;
  final VoidCallback onFail;

  const HangmanLayout({
    super.key,
    required this.wide,
    required this.mean,
    required this.word,
    required this.onSuccess,
    required this.onFail,
  });

  @override
  State<HangmanLayout> createState() => _HangmanLayoutState();
}

class _HangmanLayoutState extends State<HangmanLayout> {
  List<String> guessedLetters = [];
  List<String> correctLetters = [];
  List<String> wrongLetters = [];
  bool ishidden = false;
  int coin = 0;
  bool bakiyeaz = false;
  bool isai = false;
  void checkai() {
    if (widget.mean == "Yapay Zeka da ipucu yok") {
      setState(() {
        isai = true;
      });
    }
  }

  Future<void> getcoin() async {
    await FirebaseAuth.instance.currentUser!.isAnonymous
        ? await FirebaseFirestore.instance
            .collection("allusers")
            .doc("anonymous")
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots()
            .listen((value) {
              setState(() {
                coin = value.data()!["coin"];
              });
            })
        : await FirebaseFirestore.instance
            .collection("allusers")
            .doc("google")
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .snapshots()
            .listen((value) {
              setState(() {
                coin = value.data()!["coin"];
              });
            });
  }

  Future<String?> harfGetir() async {
    while (true) {
      String randomLetter = widget.word[Random().nextInt(widget.word.length)];
      if (!guessedLetters.contains(randomLetter) &&
          !correctLetters.contains(randomLetter)) {
        print("Rastgele harf: $randomLetter");

        String userType =
            FirebaseAuth.instance.currentUser!.isAnonymous
                ? "anonymous"
                : "google";

        await FirebaseFirestore.instance
            .collection("allusers")
            .doc(userType)
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update({"coin": coin - 10});

        return randomLetter;
      }
    }
  }

  Future<void> showHint() async {
    if (isai) {
      Set<String> uniqueLetters =
          turkishToLower(widget.word.replaceAll(' ', '')).split('').toSet();
      bool hasWon = uniqueLetters.every(
        (char) => guessedLetters.contains(char),
      );
      if (coin >= 10 && !hasWon) {
        String? yeniHarf = await harfGetir();
        if (yeniHarf != null) {
          handleLetterTap(turkishToUpper(yeniHarf));
        }
      } else {
        setState(() {
          bakiyeaz = true;
        });
      }
    } else {
      if (ishidden == false && coin < 25) {
        setState(() {
          bakiyeaz = true;
        });
      }
      if (coin >= 25 && ishidden == false) {
        await FirebaseAuth.instance.currentUser!.isAnonymous
            ? await FirebaseFirestore.instance
                .collection("allusers")
                .doc("anonymous")
                .collection("users")
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .update({"coin": coin - 25})
                .then((value) {
                  setState(() {
                    ishidden = true;
                  });
                })
            : await FirebaseFirestore.instance
                .collection("allusers")
                .doc("google")
                .collection("users")
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .update({"coin": coin - 25})
                .then((value) {
                  setState(() {
                    ishidden = true;
                  });
                });
      }
    }
  }

  bool isGameOver = false;
  Future<void> resetGame() async {
    setState(() {
      ishidden = false;
      guessedLetters.clear();
      correctLetters.clear();
      wrongLetters.clear();
      isGameOver = false;
      // Kelimeyi rastgele değiştiriyorsan burada değiştirirsin
    });
  }

  String turkishToUpper(String input) {
    const specialMap = {
      'i': 'İ',
      'ş': 'Ş',
      'ğ': 'Ğ',
      'ü': 'Ü',
      'ö': 'Ö',
      'ç': 'Ç',
      'ı': 'I',
    };

    return input.split('').map((char) {
      if (specialMap.containsKey(char)) {
        return specialMap[char]!;
      } else {
        return char.toUpperCase();
      }
    }).join();
  }

  String turkishToLower(String input) {
    const specialMap = {
      'İ': 'i',
      'I': 'ı',
      'Ş': 'ş',
      'Ğ': 'ğ',
      'Ü': 'ü',
      'Ö': 'ö',
      'Ç': 'ç',
    };

    return input.split('').map((char) {
      if (specialMap.containsKey(char)) {
        return specialMap[char]!;
      } else {
        return char.toLowerCase();
      }
    }).join();
  }

  Future<void> showWinDialog() async {
    await resetGame();
    showDialog(
      context: context,
      barrierDismissible: false, // tıklayınca kapanmasın
      builder:
          (_) => AlertDialog(
            title: Center(
              child: Text("🎉 Doğru!", style: TextStyle(fontSize: 36)),
            ),
            content: SizedBox(
              width:
                  widget.wide
                      ? MediaQuery.of(context).size.width * 1
                      : MediaQuery.of(context).size.width * 0.8,
              height:
                  widget.wide
                      ? MediaQuery.of(context).size.height * 0.8
                      : MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  children: [
                    Text(
                      "Tebrikler Baba, kelimeyi bildin!",
                      style: TextStyle(fontSize: 24),
                    ),
                    Text(
                      "Kelime: ${widget.word}",
                      style: TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // popup'ı kapat
      }
      // oyunu başlat
    });
  }

  void handleLetterTap(String letter) {
    if (isGameOver) return;

    final lowerLetter = turkishToLower(letter);
    final lowerWord = turkishToLower(widget.word);

    if (guessedLetters.contains(lowerLetter)) return;

    setState(() {
      guessedLetters.add(lowerLetter);

      if (lowerWord.contains(lowerLetter)) {
        correctLetters.add(lowerLetter);
      } else {
        wrongLetters.add(lowerLetter);
      }

      Set<String> uniqueLetters =
          turkishToLower(widget.word.replaceAll(' ', '')).split('').toSet();

      bool hasWon = uniqueLetters.every(
        (char) => guessedLetters.contains(char),
      );

      if (hasWon) {
        Future.delayed(const Duration(milliseconds: 300), () {
          showWinDialog();
        }).then((value) {
          widget.onSuccess();
        });
      }

      if (wrongLetters.length >= BodyPart.values.length) {
        isGameOver = true;

        Future.delayed(const Duration(seconds: 3), () {
          widget.onFail();
        });
      }
    });
  }

  Future<void> next() async {
    if (isai) {
      if (coin >= 25) {
        FirebaseFirestore.instance
            .collection("allusers")
            .doc(
              FirebaseAuth.instance.currentUser!.isAnonymous
                  ? "anonymous"
                  : "google",
            )
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update({"coin": FieldValue.increment(-25)})
            .then((value) {
              Future.delayed(const Duration(milliseconds: 300), () {
                showWinDialog();
              }).then((value) {
                widget.onSuccess();
              });
            });
      }
    } else {
      if (coin >= 50) {
        FirebaseFirestore.instance
            .collection("allusers")
            .doc(
              FirebaseAuth.instance.currentUser!.isAnonymous
                  ? "anonymous"
                  : "google",
            )
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update({"coin": FieldValue.increment(-50)})
            .then((value) {
              Future.delayed(const Duration(milliseconds: 300), () {
                showWinDialog();
              }).then((value) {
                widget.onSuccess();
              });
            });
      }
    }
  }

  int delay = 0;

  @override
  void initState() {
    getcoin();
    checkai();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final String word = widget.word;
    final bool wide = MediaQuery.of(context).size.width > 800;
    bool fullscreen = false;

    if (wide) {
      // 💻 Geniş ekran - SOLDA ADAM
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sol boşluk
          SizedBox(width: MediaQuery.of(context).size.width * 0.03),

          // Sol: Adam asmaca çizimi ve harf boşlukları
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            child: Card(
              color: Colors.black.withOpacity(0.0),
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: CustomPaint(
                      painter: HangmanPainter(
                        wide: true,
                        visibleParts: BodyPart.values.sublist(
                          0,
                          wrongLetters.length,
                        ),
                        isDead: isGameOver,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: LetterPlaceholders(
                      wide: true,
                      word: word,
                      guessedLetters: guessedLetters,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sağ: ipucu, buton ve klavye
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // İpucu bölümü
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                ),
                                iconSize: 84,
                                onPressed:
                                    delay == 0
                                        ? () {
                                          delay = 2;
                                          showHint();
                                          Future.delayed(
                                            Duration(seconds: delay),
                                            () {
                                              setState(() {
                                                delay = 0;
                                              });
                                            },
                                          );
                                        }
                                        : null,
                                icon: Icon(
                                  Icons.lightbulb,
                                  color: Colors.yellow,
                                ),
                              ),
                              Text(
                                isai ? "10₺ " : "25₺ ",
                                style: TextStyle(
                                  fontSize: 24,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                ),
                                iconSize: 84,
                                onPressed:
                                    delay == 0
                                        ? () {
                                          delay = 2;
                                          next();
                                          Future.delayed(
                                            Duration(seconds: delay),
                                            () {
                                              setState(() {
                                                delay = 0;
                                              });
                                            },
                                          );
                                        }
                                        : null,
                                icon: Icon(
                                  Icons.navigate_next_sharp,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                isai ? "25₺ " : "50₺ ",
                                style: TextStyle(
                                  fontSize: 24,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 8),
                      bakiyeaz
                          ? Text(
                            "Bakiye Yetersiz",
                            style: TextStyle(
                              fontSize: 16,
                              backgroundColor: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          )
                          : Text(
                            ishidden ? widget.mean : "",
                            style: TextStyle(
                              fontSize: 16,
                              backgroundColor: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 100,
                          ),
                    ],
                  ),

                  // Klavye
                  TurkishKeyboard(
                    wide: true,
                    usedLetters: guessedLetters,
                    onLetterPressed: isGameOver ? (_) {} : handleLetterTap,
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sağ boşluk
              IconButton(
                icon: Icon(Icons.fullscreen),
                onPressed: () {
                  if (!fullscreen) {
                    fullscreen = true;
                    FullScreenWindow.setFullScreen(true);
                  } else {
                    fullscreen = false;
                    FullScreenWindow.setFullScreen(false);
                  }
                  if (!fullscreen) {
                    fullscreen = true;
                    FullScreenWindow.setFullScreen(true);
                  } else {
                    fullscreen = false;
                    FullScreenWindow.setFullScreen(false);
                  }
                },
              ),
            ],
          ),
        ],
      );
    } else {
      // 📱 Dar ekran - ÜSTTE ADAM
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Center(
              child: Card(
                color: Colors.black.withOpacity(0.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.30,
                      child: CustomPaint(
                        painter: HangmanPainter(
                          wide: false,
                          visibleParts: BodyPart.values.sublist(
                            0,
                            wrongLetters.length,
                          ),
                          isDead: isGameOver,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              child: IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                ),
                                iconSize: 24,
                                onPressed:
                                    delay == 0
                                        ? () {
                                          delay = 2;
                                          showHint();
                                          Future.delayed(
                                            Duration(seconds: delay),
                                            () {
                                              setState(() {
                                                delay = 0;
                                              });
                                            },
                                          );
                                        }
                                        : null,
                                icon: Icon(
                                  Icons.lightbulb,
                                  color: Colors.yellow,
                                ),
                              ),
                            ),
                            Text(
                              isai ? "10₺ " : "25₺ ",
                              style: TextStyle(
                                fontSize: 12,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        Column(
                          children: [
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                              iconSize: 24,
                              onPressed:
                                  delay == 0
                                      ? () {
                                        delay = 2;
                                        next();
                                        Future.delayed(
                                          Duration(seconds: delay),
                                          () {
                                            setState(() {
                                              delay = 0;
                                            });
                                          },
                                        );
                                      }
                                      : null,
                              icon: Icon(
                                Icons.navigate_next_sharp,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              isai ? "25₺ " : "50₺ ",
                              style: TextStyle(
                                fontSize: 12,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      width:
                          MediaQuery.of(context).size.width *
                          0.9, // Genişlik tanımlı olsun
                      child:
                          bakiyeaz
                              ? Text(
                                "Bakiye Yetersiz",
                                style: TextStyle(
                                  fontSize: 16,
                                  backgroundColor: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              )
                              : Text(
                                ishidden ? widget.mean : "",
                                style: TextStyle(
                                  fontSize: 10,
                                  backgroundColor: Colors.white,
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                maxLines: 100,
                              ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.2,
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: LetterPlaceholders(
                        wide: false,
                        word: word,
                        guessedLetters: guessedLetters,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            TurkishKeyboard(
              wide: false,
              usedLetters: guessedLetters,
              onLetterPressed: isGameOver ? (_) {} : handleLetterTap,
            ),
          ],
        ),
      );
    }
  }
}

class TurkishKeyboard extends StatefulWidget {
  final bool wide;
  final void Function(String letter) onLetterPressed;
  final List<String> usedLetters;

  const TurkishKeyboard({
    super.key,
    required this.wide,
    required this.onLetterPressed,
    required this.usedLetters,
  });

  @override
  State<TurkishKeyboard> createState() => _TurkishKeyboardState();
}

class _TurkishKeyboardState extends State<TurkishKeyboard> {
  String turkishToLower(String input) {
    const specialMap = {
      'İ': 'i',
      'I': 'ı',
      'Ş': 'ş',
      'Ğ': 'ğ',
      'Ü': 'ü',
      'Ö': 'ö',
      'Ç': 'ç',
    };

    return input.split('').map((char) {
      return specialMap[char] ?? char.toLowerCase();
    }).join();
  }

  final List<String> turkishLetters = [
    'A',
    'B',
    'C',
    'Ç',
    'D',
    'E',
    'F',
    'G',
    'Ğ',
    'H',
    'I',
    'İ',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'Ö',
    'P',
    'R',
    'S',
    'Ş',
    'T',
    'U',
    'Ü',
    'V',
    'Y',
    'Z',
  ];
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children:
          turkishLetters.map((letter) {
            final isUsed = widget.usedLetters.contains(turkishToLower(letter));

            return ElevatedButton(
              onPressed: isUsed ? () {} : () => widget.onLetterPressed(letter),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isUsed ? Colors.white54 : Colors.lightBlueAccent,
                minimumSize: widget.wide ? Size(70, 70) : Size(40, 40),
                padding: const EdgeInsets.all(0),
              ),
              child: Text(letter, style: const TextStyle(fontSize: 18)),
            );
          }).toList(),
    );
  }
}

class LetterPlaceholders extends StatefulWidget {
  final bool wide;
  final String word;
  final List<String> guessedLetters;

  const LetterPlaceholders({
    super.key,
    required this.word,
    required this.wide,
    required this.guessedLetters,
  });

  @override
  State<LetterPlaceholders> createState() => _LetterPlaceholdersState();
}

class _LetterPlaceholdersState extends State<LetterPlaceholders> {
  String turkishToUpper(String input) {
    const specialMap = {
      'i': 'İ',
      'ş': 'Ş',
      'ğ': 'Ğ',
      'ü': 'Ü',
      'ö': 'Ö',
      'ç': 'Ç',
      'ı': 'I',
    };

    return input.split('').map((char) {
      if (specialMap.containsKey(char)) {
        return specialMap[char]!;
      } else {
        return char.toUpperCase();
      }
    }).join();
  }

  String turkishToLower(String input) {
    const specialMap = {
      'İ': 'i',
      'I': 'ı',
      'Ş': 'ş',
      'Ğ': 'ğ',
      'Ü': 'ü',
      'Ö': 'ö',
      'Ç': 'ç',
    };

    return input.split('').map((char) {
      return specialMap[char] ?? char.toLowerCase();
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Toplam kelime uzunluğuna göre tahmini satır hesabı (çok hassas değil ama pratik)
        int estimatedLineCount =
            ((widget.word.length * 44) / constraints.maxWidth).ceil();

        // 👇 3 satır veya daha fazlaysa küçült!
        double fontSize =
            widget.wide
                ? ((3 > estimatedLineCount && estimatedLineCount >= 2)
                    ? ((widget.wide) ? (20) : (10))
                    : estimatedLineCount >= 3
                    ? widget.wide
                        ? 24
                        : 6
                    : widget.wide
                    ? 38
                    : 18)
                : ((3 > estimatedLineCount && estimatedLineCount >= 2)
                    ? ((widget.wide) ? (20) : (10))
                    : estimatedLineCount >= 3
                    ? widget.wide
                        ? 24
                        : 6
                    : widget.wide
                    ? 38
                    : 18);

        return SizedBox(
          height:
              MediaQuery.of(context).size.height *
              0.15, // Sabit yükseklik — taşmayı önler
          child: Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.start,
              children:
                  widget.word.split('').map((char) {
                    final isSpace = char == ' ';
                    final isGuessed = widget.guessedLetters.contains(
                      turkishToLower(char),
                    );

                    if (isSpace) {
                      return const SizedBox(width: 24);
                    }

                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white, // Arka plan beyaz
                        shape: BoxShape.rectangle, // Daire şeklinde
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: fontSize,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Harf arka planı
                            Text(
                              isGuessed ? turkishToUpper(char) : '',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: fontSize + 3,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class HangmanPainter extends CustomPainter {
  final bool wide;
  final List<BodyPart> visibleParts;
  final bool isDead;

  HangmanPainter({
    required this.visibleParts,
    required this.isDead,
    required this.wide,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (wide) {
      final paint =
          Paint()
            ..color = Colors.black
            ..strokeWidth = 8.0
            ..style = PaintingStyle.stroke;
      const drawingHeight = 300.0;
      final centerX = size.width / 2;
      final baseY = drawingHeight * 1.1;

      // Direk
      canvas.drawLine(
        Offset(centerX - 100, baseY),
        Offset(centerX + 100, baseY),
        paint,
      );
      canvas.drawLine(
        Offset(centerX - 50, baseY),
        Offset(centerX - 50, baseY - 250),
        paint,
      );
      canvas.drawLine(
        Offset(centerX - 50, baseY - 250),
        Offset(centerX + 30, baseY - 250),
        paint,
      );
      canvas.drawLine(
        Offset(centerX + 30, baseY - 250),
        Offset(centerX + 30, baseY - 200),
        paint,
      );

      // Head
      if (visibleParts.contains(BodyPart.head)) {
        canvas.drawCircle(Offset(centerX + 30, baseY - 170), 30, paint);

        if (isDead) {
          final eyeOffsetLeft = Offset(centerX + 18, baseY - 180);
          final eyeOffsetRight = Offset(centerX + 42, baseY - 180);

          // Sol Göz X
          canvas.drawLine(
            eyeOffsetLeft.translate(-5, -5),
            eyeOffsetLeft.translate(5, 5),
            paint,
          );
          canvas.drawLine(
            eyeOffsetLeft.translate(-5, 5),
            eyeOffsetLeft.translate(5, -5),
            paint,
          );

          // Sağ Göz X
          canvas.drawLine(
            eyeOffsetRight.translate(-5, -5),
            eyeOffsetRight.translate(5, 5),
            paint,
          );
          canvas.drawLine(
            eyeOffsetRight.translate(-5, 5),
            eyeOffsetRight.translate(5, -5),
            paint,
          );

          // Ağız (üzgün)
          final mouthStart = Offset(centerX + 20, baseY - 155);
          final mouthEnd = Offset(centerX + 40, baseY - 155);
          canvas.drawArc(
            Rect.fromPoints(mouthStart, mouthEnd.translate(0, 10)),
            0,
            pi,
            false,
            paint,
          );
        }
      }

      // Body
      if (visibleParts.contains(BodyPart.body)) {
        canvas.drawLine(
          Offset(centerX + 30, baseY - 140),
          Offset(centerX + 30, baseY - 70),
          paint,
        );
      }

      // Left Arm
      if (visibleParts.contains(BodyPart.leftArm)) {
        canvas.drawLine(
          Offset(centerX + 30, baseY - 130),
          Offset(centerX - 10, baseY - 100),
          paint,
        );
      }

      // Right Arm
      if (visibleParts.contains(BodyPart.rightArm)) {
        canvas.drawLine(
          Offset(centerX + 30, baseY - 130),
          Offset(centerX + 70, baseY - 100),
          paint,
        );
      }

      // Left Leg
      if (visibleParts.contains(BodyPart.leftLeg)) {
        canvas.drawLine(
          Offset(centerX + 30, baseY - 70),
          Offset(centerX - 10, baseY - 30),
          paint,
        );
      }

      // Right Leg
      if (visibleParts.contains(BodyPart.rightLeg)) {
        canvas.drawLine(
          Offset(centerX + 30, baseY - 70),
          Offset(centerX + 70, baseY - 30),
          paint,
        );
      }
    } else {
      final paint =
          Paint()
            ..color = Colors.black
            ..strokeWidth = 8.0
            ..style = PaintingStyle.stroke;
      const drawingHeight = 200.0;
      final centerX = size.width / 2;
      final baseY = drawingHeight * 1.07;

      // Direk
      canvas.drawLine(
        Offset(centerX - 100, baseY),
        Offset(centerX + 100, baseY),
        paint,
      );
      canvas.drawLine(
        Offset(centerX - 50, baseY),
        Offset(centerX - 50, baseY - 200),
        paint,
      );
      canvas.drawLine(
        Offset(centerX - 50, baseY - 200),
        Offset(centerX + 30, baseY - 200),
        paint,
      );
      canvas.drawLine(
        Offset(centerX + 30, baseY - 200),
        Offset(centerX + 30, baseY - 170),
        paint,
      );

      // Head
      // Head
      if (visibleParts.contains(BodyPart.head)) {
        final headTopY = baseY - 170;
        final headCenter = Offset(centerX + 30, headTopY + 30);

        // Kafa
        canvas.drawCircle(headCenter, 30, paint);

        if (isDead) {
          final eyeOffsetLeft = headCenter.translate(-12, -10);
          final eyeOffsetRight = headCenter.translate(12, -10);

          // Sol Göz X
          canvas.drawLine(
            eyeOffsetLeft.translate(-5, -5),
            eyeOffsetLeft.translate(5, 5),
            paint,
          );
          canvas.drawLine(
            eyeOffsetLeft.translate(-5, 5),
            eyeOffsetLeft.translate(5, -5),
            paint,
          );

          // Sağ Göz X
          canvas.drawLine(
            eyeOffsetRight.translate(-5, -5),
            eyeOffsetRight.translate(5, 5),
            paint,
          );
          canvas.drawLine(
            eyeOffsetRight.translate(-5, 5),
            eyeOffsetRight.translate(5, -5),
            paint,
          );

          // Ağız (üzgün)
          final mouthStart = headCenter.translate(-10, 15);
          final mouthEnd = headCenter.translate(10, 15);
          canvas.drawArc(
            Rect.fromPoints(mouthStart, mouthEnd.translate(0, 8)),
            0,
            pi,
            false,
            paint,
          );
        }
      }

      // Body
      if (visibleParts.contains(BodyPart.body)) {
        canvas.drawLine(
          Offset(centerX + 30, baseY - 110),
          Offset(centerX + 30, baseY - 50),
          paint,
        );
      }

      // Left Arm
      if (visibleParts.contains(BodyPart.leftArm)) {
        canvas.drawLine(
          Offset(centerX + 30, baseY - 100),
          Offset(centerX - 5, baseY - 70),
          paint,
        );
      }

      // Right Arm
      if (visibleParts.contains(BodyPart.rightArm)) {
        canvas.drawLine(
          Offset(centerX + 30, baseY - 100),
          Offset(centerX + 65, baseY - 70),
          paint,
        );
      }

      // Left Leg
      if (visibleParts.contains(BodyPart.leftLeg)) {
        canvas.drawLine(
          Offset(centerX + 30, baseY - 50),
          Offset(centerX - 5, baseY - 10),
          paint,
        );
      }

      // Right Leg
      if (visibleParts.contains(BodyPart.rightLeg)) {
        canvas.drawLine(
          Offset(centerX + 30, baseY - 50),
          Offset(centerX + 65, baseY - 10),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant HangmanPainter oldDelegate) =>
      oldDelegate.visibleParts != visibleParts || oldDelegate.isDead != isDead;
}
