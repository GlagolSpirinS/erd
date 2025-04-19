class ChartData {
  final String name;
  final int value;

  ChartData(this.name, this.value);
}

// Модели для данных из БД
class WarehouseStock {
  final String warehouseName;
  final int totalQuantity;

  WarehouseStock(this.warehouseName, this.totalQuantity);
}

class CategorySales {
  final String categoryName;
  final int salesCount;

  CategorySales(this.categoryName, this.salesCount);
}

class OrderStatus {
  final String status;
  final int count;

  OrderStatus(this.status, this.count);
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

class MonthlySales {
  final String month;
  final double totalSales;

  MonthlySales(this.month, this.totalSales);
}

class CustomerOrders {
  final String customerName;
  final int orderCount;

  CustomerOrders(this.customerName, this.orderCount);
}

class WarehouseValue {
  final String warehouseName;
  final double totalValue;

  WarehouseValue(this.warehouseName, this.totalValue);
}