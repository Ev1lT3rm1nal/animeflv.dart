import 'episode.dart';

class AnimeInfo {
  String? id;
  String title;
  String poster;
  String banner;
  String synopsis;
  String rating;
  String debut;
  String type;
  List<String>? genres;
  late List<Episode> episodes;
  bool airing;
  DateTime? dateNextEpisode;

  AnimeInfo({
    this.id,
    required this.title,
    required this.poster,
    required this.banner,
    required this.synopsis,
    required this.rating,
    required this.debut,
    required this.type,
    required this.airing,
    this.genres,
    this.dateNextEpisode,
  });

  AnimeInfo.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        poster = json['poster'],
        banner = json['banner'],
        synopsis = json['synopsis'],
        rating = json['rating'],
        debut = json['debut'],
        type = json['type'],
        genres = json['genres'].cast<String>(),
        episodes = json['episodes'] != null
            ? (json['episodes'] as List)
                .map((e) => Episode.fromJson(e))
                .toList()
            : [],
        airing = json['airing'],
        dateNextEpisode = json['dateNextEpisode'] != null
            ? DateTime.parse(json['dateNextEpisode'])
            : null;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['poster'] = poster;
    data['banner'] = banner;
    data['synopsis'] = synopsis;
    data['rating'] = rating;
    data['debut'] = debut;
    data['type'] = type;
    data['genres'] = genres;
    data['episodes'] = episodes.map((v) => v.toJson()).toList();
    data['airing'] = airing;
    // yyyy-MM-dd format
    data['dateNextEpisode'] =
        dateNextEpisode?.toIso8601String().substring(0, 10);
    return data;
  }
}
