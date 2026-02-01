#include <Arduino.h>

// Pin tanımlamaları
const int trigPin = 5;       // Ultrasonik sensör TRIG pini
const int echoPin = 18;      // Ultrasonik sensör ECHO pini

const int YESIL_LED_PIN = 19;      // YEŞİL LED (YAKIN mesafede yanar)
const int SARI_LED_PIN  = 21;      // SARI LED (ORTA mesafede yanar)
const int KIRMIZI_LED_PIN = 4;     // KIRMIZI LED (UZAK mesafede yanar)

// Mesafe eşik değerleri (cm cinsinden)
const int yakinMesafe = 10;    // Yakın mesafe (0-10cm) - YEŞİL yanar
const int ortaMesafe = 20;     // Orta mesafe (10-20cm) - SARI yanar
const int uzakMesafe = 30;     // Uzak mesafe (20-30cm) - KIRMIZI yanar

// Mesafe ölçüm fonksiyonu
long mesafeOlc() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  
  long sure = pulseIn(echoPin, HIGH, 30000); 
  
  long mesafe = sure * 0.0343 / 2;
  
  return mesafe;
}

void setup() {
  Serial.begin(115200);
  
  // Pin modlarını ayarla
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(YESIL_LED_PIN, OUTPUT);
  pinMode(SARI_LED_PIN, OUTPUT);
  pinMode(KIRMIZI_LED_PIN, OUTPUT);
  
  // LED'leri başlangıçta kapat
  digitalWrite(YESIL_LED_PIN, LOW);
  digitalWrite(SARI_LED_PIN, LOW);
  digitalWrite(KIRMIZI_LED_PIN, LOW);
  
  Serial.println("Mesafe Sensörlü LED Kontrol Sistemi Başlatıldı");
  
  // LED Testi
  Serial.println("LED Testi Başlıyor...");
  digitalWrite(YESIL_LED_PIN, HIGH);
  delay(300);
  digitalWrite(YESIL_LED_PIN, LOW);
  digitalWrite(SARI_LED_PIN, HIGH);
  delay(300);
  digitalWrite(SARI_LED_PIN, LOW);
  digitalWrite(KIRMIZI_LED_PIN, HIGH);
  delay(300);
  digitalWrite(KIRMIZI_LED_PIN, LOW);
  delay(500);
  
  Serial.println("LED Testi Tamamlandı! Normal Çalışma Başlıyor...");
}

void loop() {
  long mesafe = mesafeOlc();
  
  Serial.print("Mesafe: ");
  Serial.print(mesafe);
  Serial.println(" cm");
  
  // Önce tüm LED'leri kapat
  digitalWrite(YESIL_LED_PIN, LOW);
  digitalWrite(SARI_LED_PIN, LOW);
  digitalWrite(KIRMIZI_LED_PIN, LOW);
  
  // 1. KONTROL: ÇOK YAKIN (0-10 cm) - YEŞİL LED
  if (mesafe > 0 && mesafe <= yakinMesafe) {
    digitalWrite(KIRMIZI_LED_PIN, HIGH);
    Serial.println(">>> YAKIN MESAFE (0-10cm) - Yeşil LED Yanıyor 🟢 <<<");
  }
  // 2. KONTROL: ORTA MESAFE (10-20 cm) - SARI LED
  else if (mesafe > yakinMesafe && mesafe <= ortaMesafe) {
    digitalWrite(SARI_LED_PIN, HIGH);
    Serial.println(">> ORTA MESAFE (10-20cm) - Sarı LED Yanıyor 🟡 <<");
  }
  // 3. KONTROL: UZAK MESAFE (20-30 cm) - KIRMIZI LED
  else if (mesafe > ortaMesafe && mesafe <= uzakMesafe) {
    digitalWrite(YESIL_LED_PIN, HIGH);
    Serial.println("> UZAK MESAFE (20-30cm) - Kırmızı LED Yanıyor 🔴 <");
  }
  // 4. KONTROL: ÇOK UZAK (30cm+) veya HATA - TÜM LED'LER KAPALI
  else {
    Serial.println("--- ÇOK UZAK (30cm+) veya Algılama Hatası - Tüm LED'ler Kapalı ---");
  }
  
  delay(100); // 100ms bekleme
}