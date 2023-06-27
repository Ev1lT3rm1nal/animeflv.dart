class EpisodeInfo {
  String anime;
  String episode;
  String id;
  String? imagePreview;

  EpisodeInfo({
    required this.anime,
    required this.episode,
    required this.id,
    this.imagePreview,
  });

  EpisodeInfo.fromJson(Map<String, dynamic> json)
      : anime = json['anime'],
        episode = json['episode'],
        id = json['id'],
        imagePreview = json['imagePreview'];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['anime'] = anime;
    data['episode'] = episode;
    data['id'] = id;
    data['imagePreview'] = imagePreview;
    return data;
  }
}
