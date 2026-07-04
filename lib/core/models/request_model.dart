class RequestModel {
  final String id;
  final String userId;
  final String userName;
  final String category;
  final String itemName;
  final String imageUrl;
  final double estimatedPrice;
  final int quantity;
  final String? location;
  final List<String> maintenanceItems;
  final String priority;
  final String status;
  final String assignedRole;
  final String? comment;
  final String? notes;
  final DateTime createdAt;
  final DateTime? reviewedAt;

  RequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.category,
    required this.itemName,
    required this.imageUrl,
    required this.estimatedPrice,
    this.quantity = 1,
    this.location,
    this.maintenanceItems = const [],
    required this.priority,
    required this.status,
    required this.assignedRole,
    this.comment,
    this.notes,
    required this.createdAt,
    this.reviewedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'category': category,
        'itemName': itemName,
        'imageUrl': imageUrl,
        'estimatedPrice': estimatedPrice,
        'quantity': quantity,
        'location': location,
        'maintenanceItems': maintenanceItems,
        'priority': priority,
        'status': status,
        'assignedRole': assignedRole,
        'comment': comment,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'reviewedAt': reviewedAt?.toIso8601String(),
      };

  factory RequestModel.fromMap(Map<String, dynamic> map) => RequestModel(
        id: map['id'] as String,
        userId: map['userId'] as String,
        userName: map['userName'] as String,
        category: map['category'] as String,
        itemName: map['itemName'] as String,
        imageUrl: map['imageUrl'] as String,
        estimatedPrice: (map['estimatedPrice'] as num).toDouble(),
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        location: map['location'] as String?,
        maintenanceItems: map['maintenanceItems'] != null
            ? List<String>.from(map['maintenanceItems'] as List)
            : [],
        priority: map['priority'] as String,
        status: map['status'] as String,
        assignedRole: map['assignedRole'] as String,
        comment: map['comment'] as String?,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        reviewedAt: map['reviewedAt'] != null
            ? DateTime.parse(map['reviewedAt'] as String)
            : null,
      );

  String get priorityLabel {
    switch (priority) {
      case 'urgent':
        return 'عاجل';
      case 'medium':
        return 'متوسط';
      case 'low':
        return 'منخفض';
      default:
        return priority;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'approved':
        return 'موافق عليه';
      case 'rejected':
        return 'مرفوض';
      case 'hold':
        return 'معلق';
      default:
        return status;
    }
  }

  bool get isPurchase => category == 'purchase';
  bool get isMaintenance => category == 'maintenance';
}
