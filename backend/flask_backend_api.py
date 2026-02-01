# ====================================================================
# IŞIK KİRLİLİĞİ TAHMİN API - PRODUCTION READY
# Flask Backend API - Mobil Uygulama İçin
# ====================================================================

from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import numpy as np
import pandas as pd
import cv2
import os
from werkzeug.utils import secure_filename
from PIL import Image
from PIL.ExifTags import TAGS
import traceback
from datetime import datetime

app = Flask(__name__)
CORS(app)  # Mobil uygulamadan CORS izni

# ====================================================================
# KONFİGÜRASYON
# ====================================================================

UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
MODEL_PATH = 'light_pollution_model_complete.pkl'

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # Max 16MB

os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# ====================================================================
# MODEL YÜKLEME
# ====================================================================

print("🚀 Flask API başlatılıyor...")
print(f"📁 Upload klasörü: {UPLOAD_FOLDER}")

try:
    model_package = joblib.load(MODEL_PATH)
    model = model_package['model']
    scaler = model_package['scaler']
    selected_features = model_package['selected_features']
    original_features = model_package['feature_engineering_steps']['original_features']
    
    print(f"✅ Model başarıyla yüklendi: {MODEL_PATH}")
    print(f"   • Model Tipi: {model_package['metadata']['model_name']}")
    print(f"   • Test R²: {model_package['performance']['test_r2']:.4f}")
    print(f"   • Test RMSE: {model_package['performance']['test_rmse']:.4f}")
    print(f"   • Eğitim Tarihi: {model_package['metadata']['training_date']}")
    print(f"   • Seçili Özellik Sayısı: {len(selected_features)}")
    
except Exception as e:
    print(f"❌ Model yüklenemedi: {e}")
    model = None
    scaler = None
    selected_features = None

# ====================================================================
# YARDIMCI FONKSİYONLAR
# ====================================================================

def allowed_file(filename):
    """Dosya uzantısı kontrolü"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def extract_exif_data(image_path):
    """EXIF verilerinden metadata çıkar"""
    try:
        image = Image.open(image_path)
        exif_data = image._getexif()
        
        metadata = {
            'exposure_time': 0.16,  # default
            'iso': None,
            'aperture': None,
            'camera_make': None,
            'camera_model': None
        }
        
        if exif_data:
            for tag_id, value in exif_data.items():
                tag = TAGS.get(tag_id, tag_id)
                
                if tag == 'ExposureTime':
                    if isinstance(value, tuple):
                        metadata['exposure_time'] = value[0] / value[1]
                    else:
                        metadata['exposure_time'] = float(value)
                
                elif tag == 'ISOSpeedRatings':
                    metadata['iso'] = value
                
                elif tag == 'FNumber':
                    if isinstance(value, tuple):
                        metadata['aperture'] = value[0] / value[1]
                    else:
                        metadata['aperture'] = float(value)
                
                elif tag == 'Make':
                    metadata['camera_make'] = value
                
                elif tag == 'Model':
                    metadata['camera_model'] = value
        
        return metadata
    
    except Exception as e:
        return {'exposure_time': 0.16}

def process_image_basic(image_path):
    """
    Temel görüntü işleme - Rs, Gs, Bs, Is çıkarımı
    """
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError("Görüntü okunamadı")
    
    # RGB'ye çevir ve normalize et
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_normalized = img_rgb.astype(np.float32) / 255.0
    
    # Kanal ortalamaları
    r_mean = np.mean(img_normalized[:, :, 0])
    g_mean = np.mean(img_normalized[:, :, 1])
    b_mean = np.mean(img_normalized[:, :, 2])
    
    # Luminance
    luminance = 0.299 * r_mean + 0.587 * g_mean + 0.114 * b_mean
    
    # Logaritmik dönüşüm (veri seti formatı)
    epsilon = 1e-10
    Rs = -np.log10(r_mean + epsilon)
    Gs = -np.log10(g_mean + epsilon)
    Bs = -np.log10(b_mean + epsilon)
    Is = -np.log10(luminance + epsilon)
    
    return {
        'Rs': Rs,
        'Gs': Gs,
        'Bs': Bs,
        'Is': Is,
        'raw_r': r_mean,
        'raw_g': g_mean,
        'raw_b': b_mean,
        'luminance': luminance
    }

def apply_feature_engineering(base_features, altitude=0):
    """
    Feature engineering adımlarını uygula
    Model eğitimindeki ile aynı işlemler
    """
    # Pandas DataFrame oluştur
    df = pd.DataFrame([{
        'Altitude': altitude,
        'Exposure time': base_features['exposure_time'],
        'Is': base_features['Is'],
        'Rs': base_features['Rs'],
        'Gs': base_features['Gs'],
        'Bs': base_features['Bs']
    }])
    
    # 1. Spektral oranlar
    df['R_G_ratio'] = df['Rs'] / (df['Gs'] + 1e-10)
    df['R_B_ratio'] = df['Rs'] / (df['Bs'] + 1e-10)
    df['G_B_ratio'] = df['Gs'] / (df['Bs'] + 1e-10)
    
    # 2. Toplam spektral enerji
    df['Total_Spectral_Energy'] = df['Rs'] + df['Gs'] + df['Bs']
    
    # 3. Normalize RGB
    total_rgb = df['Rs'] + df['Gs'] + df['Bs']
    df['Rs_norm'] = df['Rs'] / (total_rgb + 1e-10)
    df['Gs_norm'] = df['Gs'] / (total_rgb + 1e-10)
    df['Bs_norm'] = df['Bs'] / (total_rgb + 1e-10)
    
    # 4. Yükseklik interaksiyonları
    df['Altitude_x_Exposure'] = df['Altitude'] * df['Exposure time']
    df['Altitude_x_Is'] = df['Altitude'] * df['Is']
    
    # 5. Logaritmik dönüşümler
    df['log_Exposure'] = np.log1p(df['Exposure time'])
    df['log_Altitude'] = np.log1p(df['Altitude'])
    
    # 6. Polinom özellikler
    df['Rs_squared'] = df['Rs'] ** 2
    df['Gs_squared'] = df['Gs'] ** 2
    df['Rs_Gs_interaction'] = df['Rs'] * df['Gs']
    
    # 7. İstatistiksel özellikler
    df['RGB_mean'] = (df['Rs'] + df['Gs'] + df['Bs']) / 3
    df['RGB_std'] = df[['Rs', 'Gs', 'Bs']].std(axis=1)
    df['RGB_range'] = df[['Rs', 'Gs', 'Bs']].max(axis=1) - df[['Rs', 'Gs', 'Bs']].min(axis=1)
    
    # Seçili özellikleri al
    # Eksik olan özellikler için 0 değeri koy
    feature_values = []
    for feat in selected_features:
        if feat in df.columns:
            feature_values.append(df[feat].values[0])
        else:
            feature_values.append(0.0)
    
    return np.array(feature_values).reshape(1, -1)

def classify_pollution_level(nsb_score):
    """
    NSB skoruna göre kirlilik seviyesi belirle
    Bortle Scale tabanlı
    """
    if nsb_score >= 21:
        return {
            'level': 'Çok Düşük',
            'level_en': 'Very Low',
            'description': 'Mükemmel karanlık gökyüzü. Samanyolu net görünür.',
            'color': '#00ff00',
            'bortle_class': 1,
            'recommendation': 'Astrofotoğraf için mükemmel koşullar!'
        }
    elif nsb_score >= 20:
        return {
            'level': 'Düşük',
            'level_en': 'Low',
            'description': 'Çok iyi gözlem koşulları. Samanyolu kolayca görünür.',
            'color': '#7fff00',
            'bortle_class': 2,
            'recommendation': 'Çıplak gözle gözlem için harika!'
        }
    elif nsb_score >= 19:
        return {
            'level': 'Orta-Düşük',
            'level_en': 'Medium-Low',
            'description': 'İyi gözlem koşulları. Samanyolu görülebilir.',
            'color': '#ffff00',
            'bortle_class': 3,
            'recommendation': 'Gözlem için uygun koşullar.'
        }
    elif nsb_score >= 18:
        return {
            'level': 'Orta',
            'level_en': 'Medium',
            'description': 'Orta derecede ışık kirliliği. Sınırlı gözlem.',
            'color': '#ffa500',
            'bortle_class': 4,
            'recommendation': 'Teleskop ile gözlem yapılabilir.'
        }
    elif nsb_score >= 17:
        return {
            'level': 'Orta-Yüksek',
            'level_en': 'Medium-High',
            'description': 'Belirgin ışık kirliliği. Zor gözlem koşulları.',
            'color': '#ff6600',
            'bortle_class': 5,
            'recommendation': 'Gelişmiş ekipman gerekli.'
        }
    elif nsb_score >= 16:
        return {
            'level': 'Yüksek',
            'level_en': 'High',
            'description': 'Yüksek ışık kirliliği. Sadece parlak cisimler görünür.',
            'color': '#ff3300',
            'bortle_class': 6,
            'recommendation': 'Gözlem için uygun değil.'
        }
    else:
        return {
            'level': 'Çok Yüksek',
            'level_en': 'Very High',
            'description': 'Aşırı ışık kirliliği. Yıldız gözlemi neredeyse imkansız.',
            'color': '#ff0000',
            'bortle_class': 7,
            'recommendation': 'Şehir merkezi - gözlem yapmayın.'
        }

# ====================================================================
# API ENDPOINTS
# ====================================================================

@app.route('/', methods=['GET'])
def home():
    """API ana sayfa"""
    if model is None:
        return jsonify({
            'status': 'error',
            'message': 'Model yüklenemedi. Sistem yöneticisiyle iletişime geçin.'
        }), 500
    
    return jsonify({
        'message': '🌃 Işık Kirliliği Tespit API',
        'version': '2.0',
        'status': 'online',
        'model_info': {
            'name': model_package['metadata']['model_name'],
            'training_date': model_package['metadata']['training_date'],
            'performance': {
                'test_r2': round(model_package['performance']['test_r2'], 4),
                'test_rmse': round(model_package['performance']['test_rmse'], 4)
            }
        },
        'endpoints': {
            '/analyze': 'POST - Fotoğraf analizi (multipart/form-data)',
            '/health': 'GET - API sağlık kontrolü',
            '/model-info': 'GET - Model detayları'
        }
    })

@app.route('/health', methods=['GET'])
def health_check():
    """API sağlık kontrolü"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'model_loaded': model is not None,
        'scaler_loaded': scaler is not None,
        'features_count': len(selected_features) if selected_features else 0
    })

@app.route('/model-info', methods=['GET'])
def model_info():
    """Model detayları"""
    if model is None:
        return jsonify({'error': 'Model yüklü değil'}), 500
    
    return jsonify({
        'model_name': model_package['metadata']['model_name'],
        'training_date': model_package['metadata']['training_date'],
        'training_samples': model_package['metadata']['training_samples'],
        'test_samples': model_package['metadata']['test_samples'],
        'performance': model_package['performance'],
        'features': {
            'count': len(selected_features),
            'names': selected_features
        }
    })

@app.route('/analyze', methods=['POST'])
def analyze_image():
    """
    Fotoğraf analiz endpoint'i - Ana fonksiyon
    
    Gönderilecek veriler:
        file: Fotoğraf dosyası (jpg, jpeg, png)
        exposure_time: (opsiyonel) Manuel pozlama süresi
        altitude: (opsiyonel) Çekim yüksekliği (metre)
    
    Dönen JSON:
        success: bool
        nsb_score: float (tahmin edilen NSB değeri)
        pollution_level: str (kirlilik seviyesi)
        details: dict (detaylı bilgiler)
    """
    
    # Model kontrolü
    if model is None:
        return jsonify({
            'success': False,
            'error': 'Model yüklü değil. Sistem yöneticisiyle iletişime geçin.'
        }), 500
    
    # Dosya kontrolü
    if 'file' not in request.files:
        return jsonify({
            'success': False,
            'error': 'Dosya bulunamadı. "file" parametresiyle görüntü gönderin.'
        }), 400
    
    file = request.files['file']
    
    if file.filename == '':
        return jsonify({
            'success': False,
            'error': 'Dosya seçilmemiş.'
        }), 400
    
    if not allowed_file(file.filename):
        return jsonify({
            'success': False,
            'error': 'Geçersiz dosya formatı. Sadece PNG, JPG, JPEG desteklenir.'
        }), 400
    
    try:
        # Dosyayı kaydet
        filename = secure_filename(file.filename)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"{timestamp}_{filename}"
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)
        
        # Opsiyonel parametreler
        manual_exposure = request.form.get('exposure_time', None)
        manual_altitude = request.form.get('altitude', 0)
        
        if manual_exposure:
            manual_exposure = float(manual_exposure)
        if manual_altitude:
            manual_altitude = float(manual_altitude)
        else:
            manual_altitude = 0
        
        # 1. EXIF metadata çıkar
        metadata = extract_exif_data(filepath)
        
        # Manuel exposure varsa kullan
        if manual_exposure:
            metadata['exposure_time'] = manual_exposure
        
        # 2. Temel görüntü işleme
        image_features = process_image_basic(filepath)
        
        # 3. Feature engineering için birleştir
        combined_features = {
            'exposure_time': metadata['exposure_time'],
            'Is': image_features['Is'],
            'Rs': image_features['Rs'],
            'Gs': image_features['Gs'],
            'Bs': image_features['Bs']
        }
        
        # 4. Feature engineering uygula
        model_input = apply_feature_engineering(combined_features, manual_altitude)
        
        # 5. Ölçeklendir
        model_input_scaled = scaler.transform(model_input)
        
        # 6. Tahmin yap
        nsb_prediction = model.predict(model_input_scaled)[0]
        
        # 7. Kirlilik seviyesi belirle
        pollution_info = classify_pollution_level(nsb_prediction)
        
        # 8. Dosyayı temizle
        try:
            os.remove(filepath)
        except:
            pass
        
        # 9. Sonucu döndür
        response = {
            'success': True,
            'timestamp': datetime.now().isoformat(),
            'nsb_score': round(float(nsb_prediction), 2),
            'pollution_level': pollution_info['level'],
            'pollution_level_en': pollution_info['level_en'],
            'description': pollution_info['description'],
            'recommendation': pollution_info['recommendation'],
            'color_code': pollution_info['color'],
            'bortle_class': pollution_info['bortle_class'],
            'details': {
                'exposure_time': round(metadata['exposure_time'], 4),
                'altitude': manual_altitude,
                'intensity': round(float(image_features['Is']), 4),
                'red_intensity': round(float(image_features['Rs']), 4),
                'green_intensity': round(float(image_features['Gs']), 4),
                'blue_intensity': round(float(image_features['Bs']), 4),
                'luminance': round(float(image_features['luminance']), 4)
            },
            'camera_info': {
                'iso': metadata.get('iso'),
                'aperture': metadata.get('aperture'),
                'camera_make': metadata.get('camera_make'),
                'camera_model': metadata.get('camera_model')
            }
        }
        
        return jsonify(response)
        
    except Exception as e:
        # Hata durumunda detaylı log
        error_trace = traceback.format_exc()
        print(f"❌ Hata oluştu:\n{error_trace}")
        
        # Dosya temizliği
        try:
            if 'filepath' in locals():
                os.remove(filepath)
        except:
            pass
        
        return jsonify({
            'success': False,
            'error': f'İşlem sırasında hata: {str(e)}',
            'error_type': type(e).__name__
        }), 500

# ====================================================================
# UYGULAMA BAŞLATMA
# ====================================================================

if __name__ == '__main__':
    print("\n" + "="*70)
    print("🚀 IŞIK KİRLİLİĞİ TAHMİN API BAŞLATILIYOR")
    print("="*70)
    print(f"📁 Upload klasörü: {UPLOAD_FOLDER}")
    print(f"🤖 Model durumu: {'✅ Yüklü' if model else '❌ Yüklenemedi'}")
    
    if model:
        print(f"📊 Model performansı:")
        print(f"   • Test R²: {model_package['performance']['test_r2']:.4f}")
        print(f"   • Test RMSE: {model_package['performance']['test_rmse']:.4f}")
        print(f"   • Test MAE: {model_package['performance']['test_mae']:.4f}")
    
    print("\n🌐 API Endpoints:")
    print("   • GET  /           - Ana sayfa")
    print("   • GET  /health     - Sağlık kontrolü")
    print("   • GET  /model-info - Model bilgileri")
    print("   • POST /analyze    - Fotoğraf analizi")
    
    print("\n🔥 Sunucu başlatılıyor: http://0.0.0.0:5000")
    print("="*70 + "\n")
    
    app.run(host='0.0.0.0', port=5000, debug=False)