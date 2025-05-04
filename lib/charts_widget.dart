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
  late Future<List<TransactionType>> transactionTypes;
  late Future<List<ProductPriceByCategory>> productPrices;
  late Future<List<SupplierDistribution>> supplierDistribution;
  late Future<List<ProductStock>> productsInStock;

  @override
  void initState() {
    super.initState();
    final dbHelper = DatabaseHelper();
    categorySales = dbHelper.getCategorySales();
    transactionTypes = dbHelper.getTransactionTypes();
    productPrices = dbHelper.getProductPricesByCategory();
    supplierDistribution = dbHelper.getSupplierDistribution();
    productsInStock = dbHelper.getProductsInStock();
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
            FutureBuilder<List<ProductStock>>(
              future: productsInStock,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                }
                return _buildChartCard(
                  context,
                  'Товары на складе',
                  SfCircularChart(
                    title: ChartTitle(text: 'Товары на складе'),
                    legend: Legend(
                      isVisible: true,
                      position: LegendPosition.bottom,
                    ),
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      format: 'Товар: point.x\nКоличество: point.y',
                    ),
                    series: <CircularSeries>[
                      PieSeries<ProductStock, String>(
                        dataSource: snapshot.data!,
                        xValueMapper: (data, _) => data.productName,
                        yValueMapper: (data, _) => data.quantity,
                        dataLabelSettings: DataLabelSettings(
                          isVisible: true,
                          labelPosition: ChartDataLabelPosition.outside,
                        ),
                        enableTooltip: true,
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