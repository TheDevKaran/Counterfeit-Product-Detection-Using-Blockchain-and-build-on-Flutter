import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockchainService {
  late Web3Client _client;
  late String _rpcUrl;
  late EthereumAddress _contractAddress;
  late Credentials _credentials;
  late DeployedContract _contract;
  late ContractFunction _addProduct;
  late ContractFunction _verifyProduct;
  late ContractFunction _getAllProductIds;
  late ContractFunction _getProductDetails;
  late ContractFunction _getProductCount;

  // Singleton pattern
  static final BlockchainService _instance = BlockchainService._internal();

  factory BlockchainService() {
    return _instance;
  }

  BlockchainService._internal();

  Future<void> initialize() async {
    // Initialize HTTP client for Web3
    _rpcUrl = ''; // Default Ganache URL, replace with your RPC URL
    _client = Web3Client(_rpcUrl, http.Client());

    // Set contract address
    _contractAddress = EthereumAddress.fromHex(''); // Replace with your contract address

    // Set credentials from private key
    _credentials = EthPrivateKey.fromHex(''); // Replace with your private key

    // Load contract ABI
    String abiContent = await rootBundle.loadString('assets/Company.json');
    var jsonABI = jsonDecode(abiContent);
    var contractABI = jsonABI['abi'] as List<dynamic>;  // Correct type casting

    // Create contract instance
    _contract = DeployedContract(
        ContractAbi.fromJson(jsonEncode(contractABI), 'Company'),
        _contractAddress
    );

    // Get contract functions
    _addProduct = _contract.function('addProduct');
    _verifyProduct = _contract.function('verifyProduct');
    _getAllProductIds = _contract.function('getAllProductIds');
    _getProductDetails = _contract.function('getProductDetails');
    _getProductCount = _contract.function('getProductCount');
  }

  Future<int> addProduct(String name, String batchId, String manufacturerId) async {
    final response = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: _addProduct,
        parameters: [name, batchId, manufacturerId],
      ),
      chainId: 11155111, // Replace with your network chain ID
    );

    // Wait for transaction to be mined
    TransactionReceipt? receipt = await _client.getTransactionReceipt(response);
    while (receipt == null) {
      await Future.delayed(const Duration(seconds: 1));
      receipt = await _client.getTransactionReceipt(response);
    }

    // Get the latest product count to identify the new product ID
    final productCount = await getProductCount();
    return productCount - 1; // The ID of the newly added product
  }

  Future<Map<String, dynamic>> verifyProduct(int productId) async {
    final response = await _client.call(
      contract: _contract,
      function: _verifyProduct,
      params: [BigInt.from(productId)],
    );

    String status = response[0];
    Product product = Product(
      id: productId,
      name: response[1][0],
      batchId: response[1][1],
      manufacturerId: response[1][2],
      manufactureDate: (response[1][3] as BigInt).toInt(),
      isRegistered: response[1][4],
      registeredBy: response[1][5].toString(),
    );

    return {
      'status': status,
      'product': product,
    };
  }

  Future<List<int>> getAllProductIds() async {
    final response = await _client.call(
      contract: _contract,
      function: _getAllProductIds,
      params: [],
    );

    List<BigInt> bigIntList = (response[0] as List).cast<BigInt>();
    return bigIntList.map((bigInt) => bigInt.toInt()).toList();
  }

  Future<Product> getProductDetails(int productId) async {
    final response = await _client.call(
      contract: _contract,
      function: _getProductDetails,
      params: [BigInt.from(productId)],
    );

    return Product(
      id: productId,
      name: response[0][0],
      batchId: response[0][1],
      manufacturerId: response[0][2],
      manufactureDate: (response[0][3] as BigInt).toInt(),
      isRegistered: response[0][4],
      registeredBy: response[0][5].toString(),
    );
  }

  Future<int> getProductCount() async {
    final response = await _client.call(
      contract: _contract,
      function: _getProductCount,
      params: [],
    );

    return (response[0] as BigInt).toInt();
  }

  // Store product information locally to generate QR code
  Future<void> saveProductLocally(int productId, Product product) async {
    final prefs = await SharedPreferences.getInstance();
    final productJson = jsonEncode(product.toJson());
    await prefs.setString('product_$productId', productJson);
  }

  // Retrieve locally stored product information
  Future<Product?> getLocalProduct(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final productJson = prefs.getString('product_$productId');

    if (productJson != null) {
      return Product.fromJson(jsonDecode(productJson));
    }
    return null;
  }

  // Save all registered products locally
  Future<void> saveAllProductsLocally() async {
    final productIds = await getAllProductIds();
    final prefs = await SharedPreferences.getInstance();

    for (var id in productIds) {
      final product = await getProductDetails(id);
      await prefs.setString('product_$id', jsonEncode(product.toJson()));
    }

    await prefs.setStringList('all_product_ids',
        productIds.map((id) => id.toString()).toList());
  }

  // Get all locally stored products
  Future<List<Product>> getAllLocalProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productIds = prefs.getStringList('all_product_ids') ?? [];

    List<Product> products = [];
    for (var idStr in productIds) {
      final id = int.parse(idStr);
      final productJson = prefs.getString('product_$id');
      if (productJson != null) {
        products.add(Product.fromJson(jsonDecode(productJson)));
      }
    }

    return products;
  }
}
