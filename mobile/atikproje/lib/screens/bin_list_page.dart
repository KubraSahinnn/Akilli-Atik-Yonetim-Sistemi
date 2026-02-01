import 'dart:ui'; // glass efekt için
import 'package:flutter/material.dart';
import '../models/bin.dart';
import 'bin_detail_page.dart'; // screens klasöründeyse yolunu ona göre yaz

// Şimdilik sahte veriyi burada tanımlıyoruz:
final List<Bin> mockBins = [
  Bin(
    id: 'BIN_001',
    location: 'Mühendislik Fakültesi - Giriş',
    fillLevel: 20,
    lastUpdate: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
  Bin(
    id: 'BIN_002',
    location: 'Mühendislik Fakültesi - Kat 2',
    fillLevel: 55,
    lastUpdate: DateTime.now().subtract(const Duration(minutes: 12)),
  ),
  Bin(
    id: 'BIN_003',
    location: 'Kütüphane Önü',
    fillLevel: 90,
    lastUpdate: DateTime.now().subtract(const Duration(minutes: 1)),
  ),
];

class BinListPage extends StatefulWidget {
  const BinListPage({super.key});

  @override
  State<BinListPage> createState() => _BinListPageState();
}

class _BinListPageState extends State<BinListPage> {
  // Hepsi / Bos / Orta / Dolu
  String _selectedFilter = 'Hepsi';

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

  // Filtreye göre gösterilecek kutular
  List<Bin> get _filteredBins {
    switch (_selectedFilter) {
      case 'Bos':
        return mockBins.where((b) => b.fillLevel < 30).toList();
      case 'Orta':
        return mockBins
            .where((b) => b.fillLevel >= 30 && b.fillLevel < 70)
            .toList();
      case 'Dolu':
        return mockBins.where((b) => b.fillLevel >= 70).toList();
      default:
        return mockBins;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst başlık
              const Text(
                'Atık Doluluk Takibi',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Akıllı çöp kutularının anlık doluluk durumunu görüntüle.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 16),

              // Küçük özet kutusu (opsiyonel)
              _buildSummaryCard(),

              const SizedBox(height: 16),

              // Liste başlığı
              const Text(
                'Tüm Kutular',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // Filtre chip satırı
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Hepsi'),
                    _buildFilterChip('Bos'),
                    _buildFilterChip('Orta'),
                    _buildFilterChip('Dolu'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Liste
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredBins.length,
                  itemBuilder: (context, index) {
                    final bin = _filteredBins[index];
                    final color = _getColorFromFill(bin.fillLevel);
                    final statusText = _getStatusText(bin.fillLevel);

                    return _buildBinCard(
                      context: context,
                      bin: bin,
                      color: color,
                      statusText: statusText,
                      index: index,
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

  // Filtre chip
  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label == 'Bos' ? 'Boş' : label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedFilter = label;
          });
        },
        selectedColor: const Color(0xFF16A34A),
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isSelected ? const Color(0xFF16A34A) : Colors.grey.shade300,
          ),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // Özet kartı (ortalama doluluk vs. Demo için basit)
  Widget _buildSummaryCard() {
    // Demo: ortalama doluluk hesaplayalım
    final avgFill =
        mockBins.isEmpty
            ? 0
            : mockBins.map((b) => b.fillLevel).reduce((a, b) => a + b) /
                mockBins.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF22C55E), Color(0xFF16A34A), Color(0xFF059669)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.25),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Genel Durum',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ortalama doluluk: %${avgFill.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tek kutu kartı
  Widget _buildBinCard({
    required BuildContext context,
    required Bin bin,
    required Color color,
    required String statusText,
    required int index,
  }) {
    // Hafif giriş animasyonu (aşağıdan kayarak & fade-in)
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BinDetailPage(bin: bin)),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Sol yuvarlak ikon + Hero animasyonu
                    Hero(
                      tag: 'bin-icon-${bin.id}',
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.9),
                              color.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Orta metinler
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bin.location,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // İnce özel progress bar
                          _buildProgressBar(color: color, value: bin.fillLevel),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Sağ yüzde ve ok
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '%${bin.fillLevel}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade500,
                          size: 20,
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
    );
  }

  Widget _buildProgressBar({required Color color, required int value}) {
    final double ratio = value.clamp(0, 100) / 100.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth * ratio;

        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: barWidth,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
