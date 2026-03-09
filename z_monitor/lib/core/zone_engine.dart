import 'package:flutter/material.dart';

class ZoneEngine {
  // ISO 20816-3 (Grup 1 - Rigid) Limitleri
  final double limitAB = 2.3;
  final double limitBC = 4.5;
  final double limitCD = 7.1;

  // 1. Gelen RMS değerine göre Zone harfini belirler
  String evaluateZone(double rmsVal) {
    if (rmsVal < limitAB) {
      return "A";
    } else if (rmsVal < limitBC) {
      return "B";
    } else if (rmsVal < limitCD) {
      return "C";
    } else {
      return "D";
    }
  }

  // 2. Zone harfine göre o dev halkanın rengini belirler
  Color getZoneColor(String zoneChar) {
    switch (zoneChar) {
      case "A":
        return const Color(0xFF2ecc71); // Yeşil
      case "B":
        return const Color.fromARGB(255, 219, 208, 52); // Mavi
      case "C":
        return const Color.fromARGB(255, 223, 135, 3); // Sarı
      case "D":
        return const Color(0xFFe74c3c); // Kırmızı
      default:
        return Colors.grey; // Veri yoksa Gri
    }
  }
}