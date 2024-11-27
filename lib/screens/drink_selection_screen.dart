import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'beer_filling_animation_without_logo.dart'; // Import da animação
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class DrinkSelectionScreen extends StatefulWidget {
  const DrinkSelectionScreen({super.key});

  @override
  DrinkSelectionScreenState createState() => DrinkSelectionScreenState();
}

class DrinkSelectionScreenState extends State<DrinkSelectionScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> drinks = [
    {
      "name": "Chopp Brahma",
      "type": "Chopp",
      "price": 0.60,
      "image": "assets/images/choppb.jpg"
    },
    {
      "name": "Coca-Cola",
      "type": "Refrigerante",
      "price": 0.60,
      "image": "assets/images/coca.jpg"
    },
    {
      "name": "Chopp Heineken",
      "type": "Chopp",
      "price": 0.60,
      "image": "assets/images/chopph.jpg"
    },
  ];

  int _selectedDrinkIndex = -1;
  bool _shouldShowAnimation = false;
  String _temperature = "Carregando...";
  String _connectionStatus = "Solicitando permissões...";
  BluetoothConnection? connection;

  String _buffer = ""; // Buffer para armazenar dados recebidos
  double _credits = 15.0; // Créditos iniciais do cliente
  double _volume = 0.0; // Volume em mililitros
  double _price = 0.0; // Preço por mililitro da bebida selecionada
  double _flowRate = 0.0; // Fluxo em L/min

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    setState(() {
      _connectionStatus = "Solicitando permissões...";
    });

    try {
      // Solicita permissões
      final status = await [
        Permission.location,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();

      if (status.values.any((perm) => perm.isDenied)) {
        _showPermissionDeniedDialog();
        return;
      }

      setState(() {
        _connectionStatus = "Buscando dispositivos Bluetooth...";
      });

      // Conecta ao HC-05
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      final hc05 = devices.firstWhere(
        (device) => device.name == "HC-05",
        orElse: () => throw Exception("HC-05 não encontrado"),
      );

      connection = await BluetoothConnection.toAddress(hc05.address);
      setState(() {
        _connectionStatus = "Conectado ao HC-05!";
      });

      _listenToBluetoothData();
    } catch (e) {
      setState(() {
        _connectionStatus = "Erro ao conectar: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao conectar ao Bluetooth: $e")),
      );
    }
  }

  void _listenToBluetoothData() {
    connection?.input?.listen((data) {
      _buffer += String.fromCharCodes(data); // Adiciona os dados ao buffer

      while (_buffer.contains("\n")) {
        final index = _buffer.indexOf("\n");
        final message = _buffer.substring(0, index).trim();
        _buffer = _buffer.substring(index + 1);

        print('Mensagem recebida: $message');

        if (message.startsWith("Temperatura:")) {
          final temp = message
              .split(":")[1]
              .replaceAll(RegExp(r'[^\d.]'), '')
              .trim();
          setState(() {
            _temperature = "$temp °C";
          });
        } else if (message.startsWith("Fluxo:")) {
          final flow = message
              .split(":")[1]
              .replaceAll(RegExp(r'[^\d.]'), '') // Remove caracteres indesejados
              .trim();
          setState(() {
            _flowRate = double.tryParse(flow) ?? 0.0; // Atualiza o fluxo em L/min
            print('Fluxo recebido: $_flowRate L/min');
          });
        } else if (message.startsWith("Volume:")) {
          final volume = message
              .split(":")[1]
              .replaceAll(RegExp(r'[^\d.]'), '') // Remove caracteres indesejados
              .trim();
          setState(() {
            _volume = double.tryParse(volume) ?? 0.0; // Atualiza o volume total
            // Atualiza os créditos
            _credits -= (_volume * _price) / 1000;
            if (_credits < 0) _credits = 0;
            print('Volume recebido: $_volume mL');
          });
        } else if (message.startsWith("Créditos:")) {
          final credit = message.split(":")[1].trim();
          setState(() {
            _credits = double.tryParse(credit) ?? 0.0;
          });
        }
      }
    }).onDone(() {
      setState(() {
        _connectionStatus = "Conexão encerrada.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Conexão Bluetooth encerrada.")),
      );
    });
  }

  void _sendCommand(String command) {
    if (connection != null && connection!.isConnected) {
      connection?.output.add(Uint8List.fromList(command.codeUnits));
      connection?.output.allSent;
      print("Comando enviado: $command");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bluetooth não conectado.")),
      );
    }
  }

  void _selectDrink(int index) {
    if (_credits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Créditos insuficientes para abrir a solenoide.")),
      );
      return;
    }

    setState(() {
      _selectedDrinkIndex = index;
      _shouldShowAnimation = true;
      _price = drinks[index]['price']; // Define o preço da bebida selecionada
    });

    _sendCommand("SOLENOID${index + 1}_ON");
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Permissões necessárias"),
          content: Text(
              "As permissões de Bluetooth e Localização são necessárias para o funcionamento do aplicativo."),
          actions: [
            TextButton(
              child: Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Configurações"),
              onPressed: () {
                openAppSettings(); // Abre as configurações do app
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    connection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/beer_background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Text(
                    _connectionStatus,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Selecione sua Bebida',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: drinks.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _selectDrink(index),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: Colors.amber[400]!, width: 2),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 4))
                            ],
                          ),
                          width: 160,
                          height: 220,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: _selectedDrinkIndex == index &&
                                        _shouldShowAnimation
                                    ? BeerFillingAnimationWithoutLogo()
                                    : Container(),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(drinks[index]['image'],
                                        height: 120,
                                        width: 120,
                                        fit: BoxFit.cover),
                                  ),
                                  SizedBox(height: 10),
                                  Text(drinks[index]['name'],
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                      textAlign: TextAlign.center),
                                  SizedBox(height: 5),
                                  Text(drinks[index]['type'],
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700]),
                                      textAlign: TextAlign.center),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text("Temperatura: $_temperature",
                          style: TextStyle(fontSize: 18)),
                      Text("Fluxo: $_flowRate L/min",
                          style: TextStyle(fontSize: 18, color: Colors.blue)),
                      Text("Volume Total: $_volume mL",
                          style: TextStyle(fontSize: 18)),
                      Text("Preço por mL: R\$ ${_price.toStringAsFixed(2)}",
                          style: TextStyle(fontSize: 18)),
                      Text("Créditos: R\$ ${_credits.toStringAsFixed(2)}",
                          style: TextStyle(
                              fontSize: 18, color: Colors.green)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => _sendCommand("SOLENOID_ON"),
                            child: Text("Abrir Solenoide"),
                          ),
                          SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _sendCommand("SOLENOID_OFF"),
                            child: Text("Fechar Solenoide"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
