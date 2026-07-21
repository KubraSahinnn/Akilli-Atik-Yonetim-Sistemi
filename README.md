# Akıllı Atık Yönetim Sistemi

Bu proje, **ESP32** tabanlı sensör verileri kullanarak atık seviyesini ölçen, toplanan verileri bir **API** üzerinden işleyen ve **mobil uygulama** aracılığıyla kullanıcıya sunan entegre bir akıllı atık yönetim sistemidir.

## İçindekiler

- [Genel Bakış](#genel-bakış)
- [Sistem Mimarisi](#sistem-mimarisi)
- [Proje Yapısı](#proje-yapısı)
- [Bileşenler](#bileşenler)
- [Kurulum](#kurulum)
- [Kullanılan Teknolojiler](#kullanılan-teknolojiler)

## Genel Bakış

Sistem, çöp konteynerlerine yerleştirilen sensörler aracılığıyla doluluk seviyesini gerçek zamanlı ölçer, bu veriyi bir backend API'ye iletir ve toplanan verileri bir mobil uygulama üzerinden kullanıcıya/yetkiliye sunar. Ayrıca toplanan veriler üzerinde veri analizi ve modelleme çalışmaları yapılmaktadır.

## Sistem Mimarisi

```
[ESP32 + Sensör] --> [Flask Backend API] --> [Flutter Mobil Uygulama]
                              |
                              v
                     [Veri Analizi / Modelleme]
```

## Proje Yapısı

```
Akilli-Atik-Yonetim-Sistemi/
├── embedded/           # ESP32 tabanlı gömülü sistem kodu (C++)
├── backend/             # Flask tabanlı backend API (Python)
├── mobile/atikproje/    # Flutter mobil uygulama
├── data-science/        # Veri analizi ve modelleme (Jupyter Notebook / Python)
└── .gitignore
```

## Bileşenler

- **ESP32 Tabanlı Gömülü Sistem (C++)** — Sensörlerden atık seviyesi verisini toplar ve API'ye iletir
- **Flask Backend API (Python)** — Gelen sensör verilerini işler, saklar ve mobil uygulamaya sunar
- **Flutter Mobil Uygulama (UI)** — Atık seviyelerinin gerçek zamanlı takibini kullanıcıya sunar
- **Veri Analizi ve Modelleme (Python)** — Toplanan verilerin analiz edilmesi ve modellenmesi

## Kurulum

### 1. Gömülü Sistem (ESP32)

```
embedded/ klasöründeki kodu Arduino IDE veya PlatformIO ile ESP32 kartına yükleyin.
Wi-Fi ve API endpoint bilgilerini ilgili konfigürasyon dosyasında güncelleyin.
```

### 2. Backend (Flask API)

```bash
cd backend
pip install -r requirements.txt
python app.py
```

### 3. Mobil Uygulama (Flutter)

```bash
cd mobile/atikproje
flutter pub get
flutter run
```

### 4. Veri Analizi

```bash
cd data-science
pip install -r requirements.txt
jupyter notebook
```

> Not: Klasör/dosya adları veya çalıştırma komutları projenle birebir uyuşmuyorsa (örn. backend giriş dosyası `app.py` değilse) bu bölümü güncellemen gerekebilir.

## Kullanılan Teknolojiler

| Katman | Teknoloji |
|---|---|
| Gömülü Sistem | C++ (ESP32) |
| Backend | Python (Flask) |
| Mobil Uygulama | Dart (Flutter) |
| Veri Analizi | Python (Jupyter Notebook) |
