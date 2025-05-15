class Model {
  final int id;
  final String name;

  Model({
    required this.id,
    required this.name,
  });

  factory Model.fromMap(Map<String, dynamic> map) {
    return Model(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

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