import 'package:fl_chart/fl_chart.dart';

// 1. Cihazdan gelen anlık ham veri paketi (Eski dostumuz)
class ZAxisData {
  final double rms;
  final double peak;
  final double temperature;
  final String zone;

  ZAxisData({
    required this.rms,
    required this.peak,
    required this.temperature,
    required this.zone,
  });

  factory ZAxisData.empty() {
    return ZAxisData(rms: 0.0, peak: 0.0, temperature: 0.0, zone: "-");
  }
}

// 2. YENİ: Ekranda dinamik olarak eklenecek her bir "İzleme Kartı"nın hafızası
class FeatureCardModel {
  String selectedFeature; // Örn: "Z-RMS" veya "Z-Peak"
  bool isChartVisible;    // Grafik açık mı kapalı mı?
  double currentVal;
  double maxVal;
  double minVal;
  List<FlSpot> chartData; // Grafiğin çizileceği geçmiş veri noktaları

  FeatureCardModel({
    required this.selectedFeature,
    this.isChartVisible = false,
    this.currentVal = 0.0,
    this.maxVal = -9999.0, // İlk gelen değer bunu ezecek
    this.minVal = 9999.0,  // İlk gelen değer bunu ezecek
    List<FlSpot>? chartData,
  }) : chartData = chartData ?? [];

  // Reset butonuna basıldığında çağrılacak fonksiyon
  void resetMaxMin() {
    maxVal = currentVal;
    minVal = currentVal;
    chartData.clear();
  }
}