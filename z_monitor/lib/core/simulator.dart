import 'dart:async';
import 'dart:math';
import 'data_models.dart';
import 'zone_engine.dart';

class DataSimulator {
  final ZoneEngine _engine = ZoneEngine();
  final Random _random = Random();

  // Stream: Flutter'da "sürekli akan veri borusu" demektir. 
  // Su yerine ZAxisData paketleri akacak.
  Stream<ZAxisData> get zAxisStream async* {
    double time = 0;
    while (true) {
      // Saniyede 2 kere veri gönder (500 milisaniye bekle)
      await Future.delayed(const Duration(milliseconds: 500));
      
      time += 0.5;
      // Gerçeğe yakın dalgalanan bir RMS simülasyonu (Sinüs dalgası + Rastgele gürültü)
      double baseRms = 2.5 + sin(time) * 10.0; 
      double noise = (_random.nextDouble());
      double currentRms = baseRms + noise;
      if (currentRms < 0) currentRms = 0.1; // Eksiye düşmesin

      // Ürettiğimiz sahte RMS'i beynimize (ZoneEngine) sorup rengini/harfini öğreniyoruz
      String currentZone = _engine.evaluateZone(currentRms);

      // Boruya (Stream) yeni veri paketini fırlat
      yield ZAxisData(
        rms: currentRms,
        peak: currentRms * 1.4, 
        temperature: 30.0 + (_random.nextDouble() * 2), // 30-32 derece arası
        zone: currentZone,
      );
    }
  }
}