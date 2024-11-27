import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  // Lista de históricos de bebidas e créditos
  final List<Map<String, String>> _drinkHistory = [
    {'date': '2024-08-01', 'drink': 'Pilsen', 'amount': '500ml', 'price': 'R\$ 10,00'},
    {'date': '2024-08-10', 'drink': 'IPA', 'amount': '300ml', 'price': 'R\$ 15,00'},
    {'date': '2024-08-15', 'drink': 'Lager', 'amount': '400ml', 'price': 'R\$ 12,00'},
  ];

  HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[100], // Fundo amarelo claro
      body: Center(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9), // Fundo branco com opacidade
            borderRadius: BorderRadius.circular(16), // Bordas arredondadas
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 3,
                blurRadius: 7,
                offset: Offset(0, 3), // Sombra suave
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Histórico de Consumo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, // Preto suave para o texto
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _drinkHistory.length,
                  itemBuilder: (context, index) {
                    final item = _drinkHistory[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['drink']!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${item['amount']} - ${item['price']}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54, // Texto secundário
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Data: ${item['date']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
