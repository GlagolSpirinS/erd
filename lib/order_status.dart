enum OrderStatus {
  // 1. Оформление и подтверждение
  awaitingConfirmation('Ожидает подтверждения'),
  confirmed('Подтвержден'),
  rejected('Отклонен'),

  // 2. Оплата
  awaitingPayment('Ожидает оплаты'),
  paid('Оплачен'),
  paymentFailed('Оплата не прошла'),
  refunded('Возврат/Отмена оплаты'),

  // 3. Обработка и подготовка
  processing('В обработке'),
  readyForShipment('Готов к отгрузке'),
  transferredToDelivery('Передан в доставку'),

  // 4. Доставка
  inTransit('В пути'),
  delivered('Доставлен'),
  deliveryFailed('Не удалось доставить'),

  // 5. Завершение
  completed('Выполнен'),
  cancelled('Отменен'),

  // 6. Дополнительные статусы
  onHold('На удержании'),
  partiallyCompleted('Частично выполнен'),
  returnExchange('Возврат/Обмен');

  final String displayName;
  const OrderStatus(this.displayName);

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.displayName == status,
      orElse: () => throw ArgumentError('Неизвестный статус: $status'),
    );
  }

  static List<OrderStatus> getByCategory(String category) {
    switch (category) {
      case 'Оформление и подтверждение':
        return [
          OrderStatus.awaitingConfirmation,
          OrderStatus.confirmed,
          OrderStatus.rejected,
        ];
      case 'Оплата':
        return [
          OrderStatus.awaitingPayment,
          OrderStatus.paid,
          OrderStatus.paymentFailed,
          OrderStatus.refunded,
        ];
      case 'Обработка и подготовка':
        return [
          OrderStatus.processing,
          OrderStatus.readyForShipment,
          OrderStatus.transferredToDelivery,
        ];
      case 'Доставка':
        return [
          OrderStatus.inTransit,
          OrderStatus.delivered,
          OrderStatus.deliveryFailed,
        ];
      case 'Завершение':
        return [OrderStatus.completed, OrderStatus.cancelled];
      case 'Дополнительные статусы':
        return [
          OrderStatus.onHold,
          OrderStatus.partiallyCompleted,
          OrderStatus.returnExchange,
        ];
      default:
        return [];
    }
  }

  static List<String> get categories => [
    'Оформление и подтверждение',
    'Оплата',
    'Обработка и подготовка',
    'Доставка',
    'Завершение',
    'Дополнительные статусы',
  ];
}
