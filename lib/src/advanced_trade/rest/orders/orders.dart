import 'dart:convert';

import 'package:coinbase_cloud_advanced_trade_client/src/advanced_trade/models/credential.dart';
import 'package:coinbase_cloud_advanced_trade_client/src/advanced_trade/models/order.dart';
import 'package:coinbase_cloud_advanced_trade_client/src/advanced_trade/services/network.dart';
import 'package:http/http.dart' as http;

// Recursive for Paginated requests
Future<List<Order>> getOrders(
    {int? limit = 1000,
    String? cursor,
    required Credential credential,
    bool isSandbox = false}) async {
  List<Order> orders = [];
  Map<String, dynamic>? queryParameters = {'limit': '$limit'};
  (cursor != null) ? queryParameters.addAll({'cursor': cursor}) : null;

  http.Response response = await getAuthorized('/orders/historical/batch',
      queryParameters: queryParameters,
      credential: credential,
      isSandbox: isSandbox);

  if (response.statusCode == 200) {
    String data = response.body;
    var jsonResponse = jsonDecode(data);
    var jsonAccounts = jsonResponse['orders'];
    String? jsonCursor = jsonResponse['cursor'];

    for (var jsonObject in jsonAccounts) {
      orders.add(Order.fromCBJson(jsonObject));
    }
    // Recursive Break
    if (jsonCursor != null && jsonCursor != '') {
      // Recursive Call
      List<Order> paginatedAccounts = await getOrders(
          limit: limit,
          cursor: jsonCursor,
          credential: credential,
          isSandbox: isSandbox);
      orders.addAll(paginatedAccounts);
    }
  } else {
    var url = response.request?.url.toString();
    print('Request to URL $url failed: Response code ${response.statusCode}');
    print('Error Response Message: ${response.body}');
  }

  return orders;
}

Future<Order?> getOrder(
    {required String orderId,
    required Credential credential,
    bool isSandbox = false}) async {
  Order? order;

  http.Response response = await getAuthorized('/orders/historical/$orderId',
      credential: credential, isSandbox: isSandbox);

  if (response.statusCode == 200) {
    String data = response.body;
    var jsonResponse = jsonDecode(data);
    var jsonOrder = jsonResponse['order'];
    order = Order.fromCBJson(jsonOrder);
  } else {
    var url = response.request?.url.toString();
    print('Request to URL $url failed: Response code ${response.statusCode}');
    print('Error Response Message: ${response.body}');
  }

  return order;
}
