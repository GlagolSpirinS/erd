import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

import 'database_helper.dart';
import 'model.dart';

class ChartsWidget extends StatefulWidget {
  @override
  _ChartsWidgetState createState() => _ChartsWidgetState();
}

class _ChartsWidgetState extends State<ChartsWidget> {
  late Future<List<CategorySales>> categorySales;
  late Future<List<OrderStatus>> orderStatus;
  late Future<List<TransactionType>> transactionTypes;
  late Future<List<ProductPriceByCategory>> productPrices;
  late Future<List<SupplierDistribution>> supplierDistribution;
  late Future<List<MonthlySales>> monthlySales;
  late Future<List<CustomerOrders>> customerOrders;

  @override
  void initState() {
    super.initState();
    final dbHelper = DatabaseHelper();
    categorySales = dbHelper.getCategorySales();
    orderStatus = dbHelper.getOrderStatusDistribution();
    transactionTypes = dbHelper.getTransactionTypes();
    productPrices = dbHelper.getProductPricesByCategory();
    supplierDistribution = dbHelper.getSupplierDistribution();
    monthlySales = dbHelper.getMonthlySales();
    customerOrders = dbHelper.getCustomerOrders();
  }

  Widget _buildChartCard(BuildContext context, String title, Widget chart) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 10),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 300),
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 16),
            FutureBuilder<List<CategorySales>>(
              future: categorySales,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                }
                return _buildChartCard(
                  context,
                  'Продажи по категориям',
                  SfCartesianChart(
                    title: ChartTitle(text: 'Продажи по категориям'),
                    primaryXAxis: CategoryAxis(),
                    primaryYAxis: NumericAxis(),
                    series: <CartesianSeries>[
                      LineSeries<CategorySales, String>(
                        dataSource: snapshot.data!,
                        xValueMapper: (data, _) => data.categoryName,
                        yValueMapper: (data, _) => data.salesCount,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            FutureBuilder<List<OrderStatus>>(
              future: orderStatus,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                }
                return _buildChartCard(
                  context,
                  'Распределение заказов по статусам',
                  SfCircularChart(
                    title: ChartTitle(text: 'Распределение заказов по статусам'),
                    series: <CircularSeries>[
                      PieSeries<OrderStatus, String>(
                        dataSource: snapshot.data!,
                        xValueMapper: (data, _) => data.status,
                        yValueMapper: (data, _) => data.count,
                        dataLabelSettings: DataLabelSettings(isVisible: true),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            FutureBuilder<List<TransactionType>>(
              future: transactionTypes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                }
                return _buildChartCard(
                  context,
                  'Накладная по типам',
                  SfCartesianChart(
                    title: ChartTitle(text: 'Накладная по типам'),
                    primaryXAxis: CategoryAxis(),
                    primaryYAxis: NumericAxis(),
                    series: <CartesianSeries>[
                      BarSeries<TransactionType, String>(
                        dataSource: snapshot.data!,
                        xValueMapper: (data, _) => data.type,
                        yValueMapper: (data, _) => data.amount,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            FutureBuilder<List<ProductPriceByCategory>>(
              future: productPrices,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                }
                return _buildChartCard(
                  context,
                  'Средняя цена товаров по категориям',
                  SfCartesianChart(
                    title: ChartTitle(text: 'Средняя цена товаров по категориям'),
                    primaryXAxis: CategoryAxis(),
                    primaryYAxis: NumericAxis(
                      numberFormat: NumberFormat.currency(locale: 'ru_RU', symbol: '₽'),
                    ),
                    series: <CartesianSeries>[
                      ColumnSeries<ProductPriceByCategory, String>(
                        dataSource: snapshot.data!,
                        xValueMapper: (data, _) => data.categoryName,
                        yValueMapper: (data, _) => data.averagePrice,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            FutureBuilder<List<SupplierDistribution>>(
              future: supplierDistribution,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                }
                return _buildChartCard(
                  context,
                  'Распределение товаров по поставщикам',
                  SfCircularChart(
                    title: ChartTitle(text: 'Распределение товаров по поставщикам'),
                    series: <CircularSeries>[
                      PieSeries<SupplierDistribution, String>(
                        dataSource: snapshot.data!,
                        xValueMapper: (data, _) => data.supplierName,
                        yValueMapper: (data, _) => data.productCount,
                        dataLabelSettings: DataLabelSettings(isVisible: true),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            FutureBuilder<List<MonthlySales>>(
              future: monthlySales,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                }
                return _buildChartCard(
                  context,
                  'Динамика продаж по месяцам',
                  SfCartesianChart(
                    title: ChartTitle(text: 'Динамика продаж по месяцам'),
                    primaryXAxis: CategoryAxis(),
                    primaryYAxis: NumericAxis(
                      numberFormat: NumberFormat.currency(locale: 'ru_RU', symbol: '₽'),
                    ),
                    series: <CartesianSeries>[
                      LineSeries<MonthlySales, String>(
                        dataSource: snapshot.data!,
                        xValueMapper: (data, _) => data.month,
                        yValueMapper: (data, _) => data.totalSales,
                        color: Colors.green,
                        markerSettings: MarkerSettings(isVisible: true),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            FutureBuilder<List<CustomerOrders>>(
              future: customerOrders,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                }
                return _buildChartCard(
                  context,
                  'Топ-10 клиентов по количеству заказов',
                  SfCartesianChart(
                    title: ChartTitle(text: 'Топ-10 клиентов по количеству заказов'),
                    primaryXAxis: CategoryAxis(),
                    primaryYAxis: NumericAxis(),
                    series: <CartesianSeries>[
                      BarSeries<CustomerOrders, String>(
                        dataSource: snapshot.data!,
                        xValueMapper: (data, _) => data.customerName,
                        yValueMapper: (data, _) => data.orderCount,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}