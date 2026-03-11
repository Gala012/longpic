class PosterTemplate {
  final String id;
  final String name;
  final String thumbnail;
  final String templateUrl;
  final List<ImageSlot> imageSlots;
  final int requiredImageCount;
  bool isDownloaded;
  PosterTemplate({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.templateUrl,
    required this.imageSlots,
    required this.requiredImageCount,
    this.isDownloaded = true,
  });
  factory PosterTemplate.fromJson(Map<String, dynamic> json) {
    return PosterTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      thumbnail: json['thumbnail'] as String,
      templateUrl: json['templateUrl'] as String,
      imageSlots: (json['imageSlots'] as List)
          .map((slot) => ImageSlot.fromJson(slot as Map<String, dynamic>))
          .toList(),
      requiredImageCount: json['requiredImageCount'] as int,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'thumbnail': thumbnail,
      'templateUrl': templateUrl,
      'imageSlots': imageSlots.map((slot) => slot.toJson()).toList(),
      'requiredImageCount': requiredImageCount,
    };
  }
}
class ImageSlot {
  final int x;
  final int y;
  final int width;
  final int height;
  final String shape;
  ImageSlot({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.shape,
  });
  factory ImageSlot.fromJson(Map<String, dynamic> json) {
    return ImageSlot(
      x: json['x'] as int,
      y: json['y'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
      shape: json['shape'] as String,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'shape': shape,
    };
  }
}
