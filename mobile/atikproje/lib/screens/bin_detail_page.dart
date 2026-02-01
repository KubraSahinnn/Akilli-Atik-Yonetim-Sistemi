
import 'dart:ui'; // glass efekti için
import 'package:flutter/material.dart';
import '../models/bin.dart';

class BinDetailPage extends StatelessWidget {
  final Bin bin;

  const BinDetailPage({super.key, required this.bin});

  Color _getColorFromFill(int fillLevel) {
    if (fillLevel < 30) return const Color(0xFF16A34A); // yeşil
    if (fillLevel < 70) return const Color(0xFFF59E0B); // turuncu
    return const Color(0xFFDC2626); // kırmızı
  }

  String _getStatusText(int fillLevel) {
    if (fillLevel < 30) return 'Boş / Az Dolu';
    if (fillLevel < 70) return 'Orta Dolu';
    if (fillLevel < 90) return 'Neredeyse Dolu';
    return 'Tam Dolu';
  }

  String _getSuggestionText(int fillLevel) {
    if (fillLevel < 50) return 'Toplama gerekmiyor.';
    if (fillLevel < 80) return 'Yakın zamanda toplama planlanabilir.';
    return 'En kısa sürede toplama önerilir.';
  }

  String _formatDate(DateTime dt) {
    // 01.12.2025 20:10 gibi basit bir format
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.$year  $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorFromFill(bin.fillLevel);
    final statusText = _getStatusText(bin.fillLevel);
    final suggestionText = _getSuggestionText(bin.fillLevel);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withOpacity(0.96),
              color.withOpacity(0.7),
              const Color(0xFFF4F6FB),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst satır (geri butonu + başlık)
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),
                    const Text(
                      'Kutu Detayı',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Konum + durum chip
                Text(
                  bin.location,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Ortadaki büyük dairesel gösterge
                Center(
                  child: Hero(
                    tag: 'bin-icon-${bin.id}',
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.28),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 170,
                          height: 170,
                          child: CircularProgressIndicator(
                            value: bin.fillLevel / 100.0,
                            strokeWidth: 16,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '%${bin.fillLevel}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Doluluk',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Alt taraf (beyaz / glass kart alanı)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Detaylı Bilgiler',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: Colors.green.shade50,
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.bolt,
                                          size: 14,
                                          color: Color(0xFF16A34A),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Canlı veri',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF166534),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              _infoRow(
                                icon: Icons.location_on_outlined,
                                title: 'Konum',
                                value: bin.location,
                              ),
                              const SizedBox(height: 12),
                              _infoRow(
                                icon: Icons.change_circle_outlined,
                                title: 'Durum',
                                value: statusText,
                              ),
                              const SizedBox(height: 12),
                              _infoRow(
                                icon: Icons.update,
                                title: 'Son Güncelleme',
                                value: _formatDate(bin.lastUpdate),
                              ),

                              const SizedBox(height: 18),

                              // Toplama önerisi kartı
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: color,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Toplama Önerisi',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            suggestionText,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Proje açıklama notu
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: Colors.green.shade600,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Bu ekran, akıllı atık yönetim sisteminde tek bir çöp kutusunun anlık doluluk analizi için tasarlanmıştır.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}