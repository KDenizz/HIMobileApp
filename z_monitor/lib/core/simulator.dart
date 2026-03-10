import 'dart:async';
import 'dart:math';
import 'data_models.dart';
import 'zone_engine.dart';

class DataSimulator {
  final ZoneEngine _engine = ZoneEngine();
  final Random _random = Random();
  
  // DÜZELTME 4: Artık her seferinde yeni Stream üretmek yerine, 
  // herkesin aynı veriyi dinleyebileceği bir "Yayın (Broadcast)" kanalı kurduk.
  final StreamController<ZAxisData> _controller = StreamController<ZAxisData>.broadcast();
  Stream<ZAxisData> get zAxisStream => _controller.stream;

  Timer? _timer;
  double _time = 0;

  // Sınıf çağrıldığında simülasyonu otomatik başlat
  DataSimulator() {
    _startSimulation();
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _time += 0.5;
      
      // DÜZELTME 5: Daha gerçekçi, endüstriyel titreşim dalgalanması (2.0 ile 5.0 arası)
      double baseRms = 3.5 + sin(_time) * 1.5; 
      double noise = (_random.nextDouble() - 0.5) * 0.5; // Hafif sensör gürültüsü
      
      double currentRms = baseRms + noise;
      if (currentRms < 0) currentRms = 0.1; // Negatife inme koruması

      String currentZone = _engine.evaluateZone(currentRms);

      // Üretilen veriyi kanala (Stream) fırlat
      _controller.add(ZAxisData(
        rms: currentRms,
        peak: currentRms * 1.4, 
        temperature: 30.0 + (_random.nextDouble() * 2), // 30-32 derece arası stabil
        zone: currentZone,
      ));
    });
  }

  // Hafıza sızıntısını önlemek için kapatma metodu
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}