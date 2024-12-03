#include <DHT.h>
#include <SoftwareSerial.h>

#define DHTPIN 13
#define DHTTYPE DHT22
#define FLOW_PIN 2    // Pino do sensor de fluxo
#define RELAY_PIN 31   // Pino do relé para a solenoide

DHT dht(DHTPIN, DHTTYPE);
SoftwareSerial bluetooth(11, 10); // RX, TX

volatile int pulseCount = 0;  // Contador de pulsos do sensor de fluxo
float flowRate = 0.0;         // Vazão em L/min
float totalLiters = 0.0;      // Volume total em litros
unsigned long lastTime = 0;   // Tempo da última medição

// Fator de calibração do sensor YF-S401
const float pulsesPerLiter = 5880.0; // Pulsos por litro

// Função chamada pelo interrupt
void pulseCounter() {
  pulseCount++;
}

void setup() {
  Serial.begin(9600);
  bluetooth.begin(9600);
  dht.begin();

  pinMode(FLOW_PIN, INPUT_PULLUP);
  pinMode(RELAY_PIN, OUTPUT);

  // Garante que a solenoide esteja sempre fechada inicialmente
  digitalWrite(RELAY_PIN, HIGH); // HIGH para desligar o relé (dependendo da lógica do módulo de relé)

  // Configura o interrupt para o sensor de fluxo
  attachInterrupt(digitalPinToInterrupt(FLOW_PIN), pulseCounter, FALLING);

  Serial.println("Sistema iniciado! Solenoide fechada.");
  bluetooth.println("Sistema iniciado! Solenoide fechada.");
}

void loop() {
  // Leitura da temperatura
  float temperature = dht.readTemperature();

  // Cálculo da vazão
  unsigned long currentTime = millis();
  unsigned long elapsedTime = currentTime - lastTime;

  if (elapsedTime >= 1000) { // Atualiza a cada segundo
    noInterrupts();
    // Calcula a vazão em L/min
    flowRate = (pulseCount / pulsesPerLiter) * 60.0;
    // Incrementa o volume total em litros
    totalLiters += (pulseCount / pulsesPerLiter);
    pulseCount = 0; // Reseta o contador
    interrupts();

    lastTime = currentTime;

    // Converte o volume total para mL e para inteiro
    int totalMilliliters = (int)(totalLiters * 1000.0);

    // Envia os dados via Bluetooth
    bluetooth.print("Temperatura:");
    bluetooth.print(temperature);
    bluetooth.println("°C");

    bluetooth.print("Fluxo:");
    bluetooth.print(flowRate);
    bluetooth.println(" L/min");

    bluetooth.print("Volume:");
    bluetooth.print(totalMilliliters);  // Volume como inteiro
    bluetooth.println(" mL");

    Serial.print("Vazão: ");
    Serial.print(flowRate);
    Serial.println(" L/min");

    Serial.print("Volume total: ");
    Serial.print(totalMilliliters);  // Volume como inteiro
    Serial.println(" mL");
  }

  // Processa os comandos recebidos via Bluetooth
  if (bluetooth.available()) {
    String command = bluetooth.readStringUntil('\n');  // Lê o comando recebido até a nova linha
    command.trim(); // Remove espaços em branco e caracteres extras

    Serial.println("Comando recebido: " + command);

    if (command == "SOLENOID_ON") {
      digitalWrite(RELAY_PIN, LOW); // Liga a solenoide
      Serial.println("Solenoide ligada");
      bluetooth.println("Solenoide ligada");
    } else if (command == "SOLENOID_OFF") {
      digitalWrite(RELAY_PIN, HIGH); // Desliga a solenoide
      Serial.println("Solenoide desligada");
      bluetooth.println("Solenoide desligada");
    } else {
      Serial.println("Comando desconhecido: " + command);
      bluetooth.println("Comando desconhecido");
    }
  }

  delay(200); // Pequeno atraso para evitar sobrecarga
}
