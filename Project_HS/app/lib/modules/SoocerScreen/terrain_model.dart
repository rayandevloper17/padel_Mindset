class Terrain {
  final int id;
  final String name;
  final String type;
  final String imageUrl;

  Terrain({
    required this.id,
    required this.name,
    required this.type,
    required this.imageUrl,
  });

  factory Terrain.fromJson(Map<String, dynamic> json) {
    return Terrain(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      type: json['type'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'image_url': imageUrl,
  };
}
