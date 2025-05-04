import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/blockchain_service.dart';

class ProductsScreen extends StatefulWidget {
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> products = [];

  void loadProducts() async {
    final ids = await BlockchainService().getAllProductIds();
    List<Product> fetchedProducts = [];

    for (var id in ids) {
      final product = await BlockchainService().getProductDetails(id);
      fetchedProducts.add(product);
    }

    setState(() {
      products = fetchedProducts;
    });
  }


  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.deepPurple,
          title: const Text('Registered Products')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (_, i) {
          final p = products[i];
          return ListTile(
            title: Text(p.name),
            subtitle: Text('Batch ID: ${p.batchId}\nManufactured on: ${p.formattedDate}'),
            trailing: Icon(p.isRegistered ? Icons.check_circle : Icons.error, color: p.isRegistered ? Colors.green : Colors.red),
          );
        },
      ),

    );
  }
}
