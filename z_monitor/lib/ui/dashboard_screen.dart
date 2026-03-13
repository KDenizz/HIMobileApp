import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/data_models.dart';
import '../core/simulator.dart';
import '../core/zone_engine.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DataSimulator _simulator = DataSimulator();
  final ZoneEngine _zoneEngine = ZoneEngine();
  late StreamSubscription<ZAxisData> _subscription;
  
  // EKRANDAKİ KARTLARIN LİSTESİ (Başlangıçta 1 tane Z-RMS kartı olsun)
  final List<FeatureCardModel> _activeCards = [
    FeatureCardModel(selectedFeature: "Z-RMS", isChartVisible: true)
  ];
  
  bool _isConnected = false;
  String _deviceName = "Select Device...";
  double _currentTime = 0.0;

  // Seçilebilecek özelliklerin havuzu
  final List<String> _availableFeatures = ["Z-RMS", "Z-Peak", "Temperature"];
  String _getUnit(String feature) {
    if (feature.contains("RMS") || feature.contains("Peak")) return " mm/s";
    if (feature == "Temperature") return " °C";
    return "";
  }

  @override
  void initState() {
    super.initState();
    // Simülatörden (ileride Bluetooth'tan) gelen veriyi dinliyoruz
    _subscription = _simulator.zAxisStream.listen((data) {
      if (!_isConnected) {
        return;
      }
      setState(() {
        _currentTime += 0.5;

        // Ekranda kaç tane kart açıksa, hepsinin değerlerini anlık olarak güncelle!
        for (var card in _activeCards) {
          // Kart hangi veriyi izliyorsa onu seç
          double newVal = 0.0;
          if (card.selectedFeature == "Z-RMS") {
            newVal = data.rms;
          } else if (card.selectedFeature == "Z-Peak"){
            newVal = data.peak;
          } 
          else if (card.selectedFeature == "Temperature"){
            newVal = data.temperature;            
          } 

          // Değerleri Güncelle
          card.currentVal = newVal;
          if (newVal > card.maxVal) card.maxVal = newVal;
          if (newVal < card.minVal) card.minVal = newVal;

          // Eğer grafiği açıksa geçmişe kaydet
          if (card.isChartVisible) {
            card.chartData.add(FlSpot(_currentTime, newVal));
            if (card.chartData.length > 40) card.chartData.removeAt(0); // Son 20 saniye
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  // Yeni Kart Ekleme Fonksiyonu
  void _addNewCard() {
    setState(() {
      _activeCards.add(FeatureCardModel(selectedFeature: "Z-RMS"));
    });
  }

  // Kart Silme Fonksiyonu
  void _removeCard(int index) {
    setState(() {
      _activeCards.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D), // Simsiyah arka plan
      
      // 1. SABİT ÜST BAR (Connection Box)
        appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: SafeArea(
          child: InkWell(
            onTap: _showConnectionDialog, // Tıklanınca popup açılacak
            child: Container(
              margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isConnected ? const Color(0xFF2ecc71) : const Color(0xFF333333)), // Bağlıysa yeşil çerçeve
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Connected Device", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text("$_deviceName ▼", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isConnected ? "🟢 Connected" : "🔴 Disconnected", 
                        style: TextStyle(color: _isConnected ? const Color(0xFF2ecc71) : Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                      Text( _isConnected ? "Tap to disconnect/edit" : "Tap to connect", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),


      // 2. DİNAMİK LİSTE (Kartların Alt Alta Dizildiği Yer)
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 10, bottom: 100), // En altta butona yer kalsın
        itemCount: _activeCards.length,
        itemBuilder: (context, index) {
          return _buildFeatureCard(index);
        },
      ),

      // 3. SABİT ALT BUTON (Yeni Veri İzle)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _addNewCard,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("NEW DATA MONITOR", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3498db),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  // --- KART TASARIMI (LEGO PARÇASI) ---
  Widget _buildFeatureCard(int index) {
    var card = _activeCards[index];
    Color currentColor = const Color.fromARGB(255, 214, 244, 248);

    if (card.selectedFeature == "Z-RMS") {
      String zoneChar = _zoneEngine.evaluateZone(card.currentVal);
      currentColor = _zoneEngine.getZoneColor(zoneChar);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        children: [
          // Üst Satır: Combo Box ve Silme Butonu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,


            children: [
              // Açılır Menü (Feature Seçimi)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: card.selectedFeature,
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    items: _availableFeatures.map((String feature) {
                      return DropdownMenuItem(value: feature, child: Text(feature));
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          card.selectedFeature = newValue;
                          card.resetMaxMin(); // Yeni veriye geçince eskisini sıfırla
                        });
                      }
                    },
                  ),
                ),
              ),
              // Çarpı Butonu (Kartı Kapat)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                onPressed: () => _removeCard(index),
              )
            ],
          ),
          
          const SizedBox(height: 10),


          // Değerler Satırı: Current, Max, Min
        // Değerler Satırı: Current, Max, Min
          Builder(builder: (context) {
            String unit = card.selectedFeature == "Temperature" ? "°C" : "mm/s";
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildValueCol("Current", "${card.currentVal.toStringAsFixed(2)} $unit", currentColor, 28),
                _buildValueCol("Max", card.maxVal == -9999.0 ? "-" : "${card.maxVal.toStringAsFixed(2)} $unit", Colors.white, 16),
                _buildValueCol("Min", card.minVal == 9999.0 ? "-" : "${card.minVal.toStringAsFixed(2)} $unit", Colors.white, 16),
              ],
            );
          }),

          const SizedBox(height: 15),
          const Divider(color: Color(0xFF333333), thickness: 1),

          // Alt Butonlar: Grafik Aç/Kapat ve Reset
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    card.isChartVisible = !card.isChartVisible;
                    if (card.isChartVisible) card.chartData.clear();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      Icon(card.isChartVisible ? Icons.show_chart : Icons.bar_chart, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(card.isChartVisible ? "Hide Chart" : "Show Chart", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showResetDialog(card),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Row(
                    children: const [
                      Icon(Icons.refresh, color: Colors.grey, size: 16),
                      SizedBox(width: 4),
                      Text("Reset", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              )
            ],
          ),

          // GRAFİK ALANI (Eğer isChartVisible true ise çizilir)
          if (card.isChartVisible) ...[
            const SizedBox(height: 10),
            Container(
              height: 120,
              padding: const EdgeInsets.only(top: 10, right: 10),
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: card.maxVal == -9999.0 ? 10.0 : (card.maxVal * 1.2),
                  minX: card.chartData.isEmpty ? 0 : card.chartData.first.x,
                  maxX: card.chartData.isEmpty ? 20 : card.chartData.last.x,
                  lineBarsData: [
                    LineChartBarData(
                      spots: card.chartData,
                      isCurved: true,
                      color: const Color(0xFF00E5FF),
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: const Color(0xFF00E5FF).withValues(alpha: .1)),
                    )
                  ],
                  // EKSEN İSİMLERİ VE DEĞERLERİ (X ve Y Ekseni)
                   titlesData: FlTitlesData(
                    show: true, 
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
                    
                    // ALT EKSEN (X - Zaman)
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text("Time (s)", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      axisNameSize: 20,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22, 
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: Text("${value.toInt()}", style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          );
                        },
                      ),
                    ),

                    // SOL EKSEN (Y - Değerler)
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(_getUnit(card.selectedFeature).trim(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      axisNameSize: 20,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30, 
                        getTitlesWidget: (value, meta) {
                          return Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.grey, fontSize: 10));
                        },
                      ),
                    ),
                  ),

                  
                  // Grafiğin etrafındaki çerçeveyi de belirginleştirelim
                  borderData: FlBorderData(
                    show: true, 
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFF333333), width: 1), // Sadece alt çizgi
                      left: BorderSide(color: Color(0xFF333333), width: 1),   // Sadece sol çizgi
                    )
                  ),
                ),
              ),
            )
          ]
        ],
      ),
    );
  }

  // Değer sütünları için yardımcı metod (Kod kalabalığını önler)
  Widget _buildValueCol(String label, String value, Color valColor, double valSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: TextStyle(color: valColor, fontSize: valSize, fontWeight: FontWeight.bold)),
      ],
    );
  }
  // --- POPUP: BAĞLANTI VE İSİMLENDİRME EKRANI ---
  void _showConnectionDialog() {
    TextEditingController nameController = TextEditingController(text: _deviceName == "Select Device..." ? "" : _deviceName);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text("Device Connection", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Enter Machine/Port Name",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF3498db))),
                ),
              ),
            ],
          ),
          actions: [
            if (_isConnected) // Eğer zaten bağlıysa Disconnect butonu göster
              TextButton(
                onPressed: () {
                  setState(() {
                    _isConnected = false;
                    _deviceName = "Select Device...";
                  });
                  Navigator.pop(context);
                },
                child: const Text("Disconnect", style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3498db)),
              onPressed: () {
                setState(() {
                  _deviceName = nameController.text.isEmpty ? "Unknown Machine" : nameController.text;
                  _isConnected = true;
                });
                Navigator.pop(context);
              },
              child: const Text("Connect", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  // --- POPUP: RESET ONAY EKRANI ---
  void _showResetDialog(FeatureCardModel card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Are you sure?", style: TextStyle(color: Colors.white)),
        content: const Text("Max, Min and chart history will be cleared.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() => card.resetMaxMin());
              Navigator.pop(context);
            },
            child: const Text("Reset Data", style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }
}