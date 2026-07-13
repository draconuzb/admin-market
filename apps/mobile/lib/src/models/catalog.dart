import '../core/format.dart';

class Category {
  Category({required this.id, required this.nameUz, required this.nameRu, required this.nameEn});
  final int id;
  final String nameUz;
  final String nameRu;
  final String nameEn;

  String name(String lang) => switch (lang) {
        'ru' => nameRu,
        'en' => nameEn,
        _ => nameUz,
      };

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as int,
        nameUz: j['name_uz'] as String,
        nameRu: j['name_ru'] as String,
        nameEn: j['name_en'] as String,
      );
}

class Factory {
  Factory({required this.id, required this.name, this.region, this.address, this.logoUrl});
  final int id;
  final String name;
  final String? region;
  final String? address;
  final String? logoUrl;

  factory Factory.fromJson(Map<String, dynamic> j) => Factory(
        id: j['id'] as int,
        name: j['name'] as String,
        region: j['region'] as String?,
        address: j['address'] as String?,
        logoUrl: j['logo_url'] as String?,
      );
}

class Product {
  Product({
    required this.id,
    required this.factoryId,
    required this.categoryId,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    required this.price,
    required this.minOrderQty,
    required this.stockQty,
    required this.isFeatured,
    this.isActive = true,
    this.descriptionUz,
    this.descriptionRu,
    this.descriptionEn,
    this.images = const [],
    this.factory,
  });

  final int id;
  final int factoryId;
  final int categoryId;
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final num price;
  final int minOrderQty;
  final int stockQty;
  final bool isFeatured;
  final bool isActive;
  final String? descriptionUz;
  final String? descriptionRu;
  final String? descriptionEn;
  final List<String> images;
  final Factory? factory;

  bool get inStock => stockQty > 0;

  String name(String lang) => switch (lang) {
        'ru' => nameRu,
        'en' => nameEn,
        _ => nameUz,
      };

  String? description(String lang) => switch (lang) {
        'ru' => descriptionRu,
        'en' => descriptionEn,
        _ => descriptionUz,
      };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as int,
        factoryId: j['factory_id'] as int,
        categoryId: j['category_id'] as int,
        nameUz: j['name_uz'] as String,
        nameRu: j['name_ru'] as String,
        nameEn: j['name_en'] as String,
        price: parseNum(j['price']),
        minOrderQty: j['min_order_qty'] as int,
        stockQty: j['stock_qty'] as int,
        isFeatured: j['is_featured'] as bool? ?? false,
        isActive: j['is_active'] as bool? ?? true,
        descriptionUz: j['description_uz'] as String?,
        descriptionRu: j['description_ru'] as String?,
        descriptionEn: j['description_en'] as String?,
        images: (j['images'] as List?)?.map((e) => e['url'] as String).toList() ?? const [],
        factory: j['factory'] != null
            ? Factory.fromJson(j['factory'] as Map<String, dynamic>)
            : null,
      );
}
