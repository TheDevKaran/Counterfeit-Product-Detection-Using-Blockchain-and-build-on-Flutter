class Product {
  final int id;
  final String name;
  final String batchId;
  final String manufacturerId;
  final int manufactureDate;
  final bool isRegistered;
  final String registeredBy;

  Product({
    required this.id,
    required this.name,
    required this.batchId,
    required this.manufacturerId,
    required this.manufactureDate,
    required this.isRegistered,
    required this.registeredBy,
  });

  // Convert timestamp to readable date
  String get formattedDate {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(manufactureDate * 1000);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // Create from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      batchId: json['batchId'],
      manufacturerId: json['manufacturerId'],
      manufactureDate: json['manufactureDate'],
      isRegistered: json['isRegistered'],
      registeredBy: json['registeredBy'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'batchId': batchId,
      'manufacturerId': manufacturerId,
      'manufactureDate': manufactureDate,
      'isRegistered': isRegistered,
      'registeredBy': registeredBy,
    };
  }

  // Convert to QR data
  String toQrData() {
    return '$id|$name|$batchId|$manufacturerId|$manufactureDate|$isRegistered|$registeredBy';
  }

  // Create from QR data
  static Product? fromQrData(String qrData) {
    try {
      final parts = qrData.split('|');
      if (parts.length != 7) return null;

      return Product(
        id: int.parse(parts[0]),
        name: parts[1],
        batchId: parts[2],
        manufacturerId: parts[3],
        manufactureDate: int.parse(parts[4]),
        isRegistered: parts[5].toLowerCase() == 'true',
        registeredBy: parts[6],
      );
    } catch (e) {
      return null;
    }
  }
}