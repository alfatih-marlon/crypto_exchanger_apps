import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';

class CoinDetailPage extends StatefulWidget {
  const CoinDetailPage({required this.coinId, Key? key}) : super(key: key);

  final String coinId;

  @override
  _CoinDetailPageState createState() => _CoinDetailPageState();
}

class _CoinDetailPageState extends State<CoinDetailPage> {
  List<CoinData> data = [];
  Coin? coin;
  String selectedInterval = 'h1';

  @override
  void initState() {
    super.initState();
    fetchCoinDetails();
    fetchChartData();
  }

  Future<void> fetchCoinDetails() async {
    var response = await http
        .get(Uri.parse('https://api.coincap.io/v2/assets/${widget.coinId}'));

    print('Response data: ${response.body}');

    if (response.statusCode == 200) {
      setState(() {
        Map<String, dynamic> jsonData = json.decode(response.body)['data'];
        coin = Coin.fromJson(jsonData);
      });
    } else {
      throw Exception('Failed to load coin details');
    }
  }

  Future<void> fetchChartData() async {
    var response = await http.get(Uri.parse(
        'https://api.coincap.io/v2/assets/${widget.coinId}/history?interval=$selectedInterval'));

    print('Response data: ${response.body}');

    if (response.statusCode == 200) {
      setState(() {
        List jsonData = json.decode(response.body)['data'];
        data = jsonData.map((json) => CoinData.fromJson(json)).toList();
      });
    } else {
      throw Exception('Failed to load chart data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coin Details'),
      ),
      body: (coin != null && data.isNotEmpty)
          ? Column(
              children: <Widget>[
                ListTile(
                  title: Text(coin!.name),
                  subtitle: Text(
                      "Price: ${coin!.priceUsd}\nRank: ${coin!.rank}\nSymbol: ${coin!.symbol}"),
                ),
                DropdownButton<String>(
                  value: selectedInterval,
                  items: <String>[
                    'm1',
                    'm5',
                    'm15',
                    'm30',
                    'h1',
                    'h2',
                    'h6',
                    'h12',
                    'd1'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedInterval = newValue!;
                      fetchChartData();
                    });
                  },
                ),
                SfCartesianChart(
                  primaryXAxis: DateTimeAxis(),
                  series: <ChartSeries>[
                    HiloOpenCloseSeries<CoinData, DateTime>(
                      dataSource: data,
                      xValueMapper: (CoinData sales, _) => sales.time,
                      lowValueMapper: (CoinData sales, _) => sales.low,
                      highValueMapper: (CoinData sales, _) => sales.high,
                      openValueMapper: (CoinData sales, _) => sales.open,
                      closeValueMapper: (CoinData sales, _) => sales.close,
                    ),
                  ],
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

class Coin {
  Coin({
    required this.id,
    required this.rank,
    required this.symbol,
    required this.name,
    required this.priceUsd,
  });

  final String id;
  final String rank;
  final String symbol;
  final String name;
  final String priceUsd;

  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
      id: json['id'],
      rank: json['rank'],
      symbol: json['symbol'],
      name: json['name'],
      priceUsd: json['priceUsd'],
    );
  }
}

class CoinData {
  CoinData({
    required this.time,
    required this.open,
    required this.close,
    required this.high,
    required this.low,
  });

  final DateTime time;
  final double open;
  final double close;
  final double high;
  final double low;

  factory CoinData.fromJson(Map<String, dynamic> json) {
    double price = double.parse(json['priceUsd'].toString());
    return CoinData(
      time: DateTime.fromMillisecondsSinceEpoch((json['time'] as num).toInt()),
      open: price - 10, // dummy open price
      close: price,
      high: price + 10, // dummy high price
      low: price - 20, // dummy low price
    );
  }
}
