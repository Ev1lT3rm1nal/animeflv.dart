import 'episode_info.dart';

class Episode {
  String? anime;
  String? episode;
  String? id;
  String? imagePreview;

  Episode({this.anime, this.episode, this.id, this.imagePreview});

  Episode.fromJson(Map<String, dynamic> json) {
    anime = json['anime'];
    episode = json['episode'];
    id = json['id'];
    imagePreview = json['imagePreview'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['anime'] = anime;
    data['episode'] = episode;
    data['id'] = id;
    data['imagePreview'] = imagePreview;
    return data;
  }

  Episode.fromEpisodeInfo(EpisodeInfo episodeInfo) {
    anime = episodeInfo.anime;
    episode = episodeInfo.episode.toString();
    id = episodeInfo.id;
    imagePreview = episodeInfo.imagePreview;
  }
}
