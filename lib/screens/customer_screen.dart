import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/product.dart';
import '../services/blockchain_service.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final BlockchainService _blockchainService = BlockchainService();
  final MobileScannerController _scannerController = MobileScannerController();

  bool _isScanning = true;
  bool _isVerifying = false;
  String? _qrData;
  Product? _product;
  String? _status;
  String? _errorMessage;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _verifyProduct(String qrData) async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _qrData = qrData;
    });

    try {
      // Parse QR data to extract product information
      final product = Product.fromQrData(qrData);

      if (product == null) {
        setState(() {
          _status = 'Counterfeit';
          _errorMessage = 'Invalid QR code format';
          _isVerifying = false;
        });
        return;
      }

      // Verify on blockchain
      final result = await _blockchainService.verifyProduct(product.id);

      setState(() {
        _status = result['status'];
        _product = result['product'];
        _isVerifying = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error';
        _errorMessage = 'Error verifying product: ${e.toString()}';
        _isVerifying = false;
      });
    }
  }

  void _restartScan() {
    setState(() {
      _isScanning = true;
      _qrData = null;
      _product = null;
      _status = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.deepPurple,
        title: const Text('Verify Product'),
      ),
      body: _isScanning ? _buildScanner() : _buildVerificationResult(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && _isScanning) {
              final barcode = barcodes.first;
              if (barcode.rawValue != null) {
                setState(() {
                  _isScanning = false;
                });
                _verifyProduct(barcode.rawValue!);
              }
            }
          },
        ),
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.transparent,
              width: 0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Scan Product QR Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 3.0,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Position the QR code within the frame',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 3.0,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationResult() {
    final Color statusColor = _status == 'Authenticated'
        ? Colors.green
        : _status == 'Counterfeit'
        ? Colors.red
        : Colors.orange;

    final IconData statusIcon = _status == 'Authenticated'
        ? Icons.verified
        : _status == 'Counterfeit'
        ? Icons.dangerous
        : Icons.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isVerifying) ...[
            const SizedBox(height: 40),
            const Center(
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verifying Product...',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            // Status Card
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: statusColor,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      statusIcon,
                      size: 80,
                      color: statusColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _status ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Product Details
            if (_product != null && _status == 'Authenticated') ...[
              const Text(
                'Product Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailRow('Product Name', _product!.name, Icons.inventory_2),
                      const Divider(),
                      _buildDetailRow('Batch ID', _product!.batchId, Icons.numbers),
                      const Divider(),
                      _buildDetailRow('Manufacturer ID', _product!.manufacturerId, Icons.factory),
                      const Divider(),
                      _buildDetailRow('Registration Date', _product!.formattedDate, Icons.date_range),
                    ],
                  ),
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 30),

            // Scan Again Button
            ElevatedButton.icon(
              onPressed: _restartScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Another Product'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}