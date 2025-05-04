import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../services/blockchain_service.dart';
import '../models/product.dart';

class ManufacturerScreen extends StatefulWidget {
  const ManufacturerScreen({super.key});

  @override
  State<ManufacturerScreen> createState() => _ManufacturerScreenState();
}

class _ManufacturerScreenState extends State<ManufacturerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _batchIdController = TextEditingController();
  final _manufacturerIdController = TextEditingController();

  final BlockchainService _blockchainService = BlockchainService();

  bool _isLoading = false;
  Product? _product;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _batchIdController.dispose();
    _manufacturerIdController.dispose();
    super.dispose();
  }

  Future<void> _registerProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productId = await _blockchainService.addProduct(
        _nameController.text,
        _batchIdController.text,
        _manufacturerIdController.text,
      );

      final product = await _blockchainService.getProductDetails(productId);

      // Save product locally
      await _blockchainService.saveProductLocally(productId, product);

      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error registering product: ${e.toString()}';
      });
    }
  }

  Future<void> _saveQrCode() async {
    // This is a simplified version. In a real app, you'd implement actual image saving
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR Code saved to gallery')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manufacturer Portal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_product == null) ...[
              const Text(
                'Register New Product',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildRegistrationForm(),
            ] else ...[
              _buildProductQrCode(),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Product Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.inventory),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter product name';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _batchIdController,
            decoration: const InputDecoration(
              labelText: 'Batch ID',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter batch ID';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _manufacturerIdController,
            decoration: const InputDecoration(
              labelText: 'Manufacturer ID',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.factory),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter manufacturer ID';
              }
              return null;
            },
          ),
          const SizedBox(height: 25),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _registerProduct,
            icon: _isLoading
                ? Container(
              width: 24,
              height: 24,
              padding: const EdgeInsets.all(2.0),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
                : const Icon(Icons.upload),
            label: Text(_isLoading ? 'Registering...' : 'Register Product'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductQrCode() {
    if (_product == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Product Registered!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Product Name'),
                  subtitle: Text(_product!.name),
                  leading: const Icon(Icons.inventory_2),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Batch ID'),
                  subtitle: Text(_product!.batchId),
                  leading: const Icon(Icons.numbers),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Manufacturer ID'),
                  subtitle: Text(_product!.manufacturerId),
                  leading: const Icon(Icons.factory),
                ),
                const Divider(),
                ListTile(
                  title: const Text('Registration Date'),
                  subtitle: Text(_product!.formattedDate),
                  leading: const Icon(Icons.date_range),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Product QR Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: QrImageView(
                  data: _product!.toQrData(),
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Scan this QR code to verify product authenticity',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _saveQrCode,
              icon: const Icon(Icons.download),
              label: const Text('Save QR Code'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _product = null;
                });
                _nameController.clear();
                _batchIdController.clear();
                _manufacturerIdController.clear();
              },
              icon: const Icon(Icons.add),
              label: const Text('New Product'),
            ),
          ],
        ),
      ],
    );
  }
}