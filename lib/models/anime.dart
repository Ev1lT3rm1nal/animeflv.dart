class Anime {
  String? id;
  String? title;
  String? poster;
  String? banner;
  String? type;
  String? synopsis;
  String? rating;

  Anime(
      {this.id,
      this.title,
      this.poster,
      this.banner,
      this.type,
      this.synopsis,
      this.rating});

  Anime.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    poster = json['poster'];
    banner = json['banner'];
    type = json['type'];
    synopsis = json['synopsis'];
    rating = json['rating'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['poster'] = poster;
    data['banner'] = banner;
    data['type'] = type;
    data['synopsis'] = synopsis;
    data['rating'] = rating;
    return data;
  }
}
