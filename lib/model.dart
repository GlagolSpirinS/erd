class ChartData {
  final String name;
  final int value;

  ChartData(this.name, this.value);
}

class CategorySales {
  final String categoryName;
  final int salesCount;

  CategorySales(this.categoryName, this.salesCount);
}

class TransactionType {
  final String type;
  final int amount;

  TransactionType(this.type, this.amount);
}

class ProductPriceByCategory {
  final String categoryName;
  final double averagePrice;

  ProductPriceByCategory(this.categoryName, this.averagePrice);
}

class SupplierDistribution {
  final String supplierName;
  final int productCount;

  SupplierDistribution(this.supplierName, this.productCount);
}