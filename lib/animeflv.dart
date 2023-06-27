library animeflv;

import 'package:animeflv/models/anime.dart';
import 'package:animeflv/models/anime_info.dart';
import 'package:animeflv/models/episode.dart';
import 'package:animeflv/models/server_info.dart';
import 'package:dio/dio.dart';
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'dart:convert';

import 'globals.dart';

// ===================================================================================================================================================
// class that will contain all the methods
class AnimeFlv {
  // =================================================================================================================================================
  // function to fetch last episodes added to animeflv
  static final Dio _dio = Dio();

  static Future<List<Episode>> getLastEpisodes() async {
    // get request to base animeflv url
    final res = await _dio.get(BASE_URL);
    if (res.statusCode == 200) {
      // get html and look for last episodes list
      final body = res.data.toString();
      final soup = BeautifulSoup(body);
      List<Episode> lastEpisodes = [];
      final lastEpisodesElements =
          soup.findAll('', selector: '.ListEpisodios li a.fa-play');
      // for every episode found we save some data
      for (var episode in lastEpisodesElements) {
        lastEpisodes.add(Episode(
          anime: episode.find('', selector: '.Title')?.string,
          episode: episode
              .find('', selector: '.Capi')
              ?.string
              .replaceAll('Episodio ', ''),
          id: episode['href']?.split('ver/')[1],
          imagePreview:
              '$BASE_URL${episode.find('', selector: '.Image img')?['src']}',
        ));
      }
      // return last episodes found
      return lastEpisodes;
    }
    return [];
  }

  // =================================================================================================================================================
  // function to get the latest uploaded animes
  static Future<List<Anime>> getLastAddedAnimes() async {
    // get request to base animeflv url
    final res = await _dio.get(BASE_URL);
    if (res.statusCode == 200) {
      // get html and look for last animes list
      final body = res.data.toString();
      final soup = BeautifulSoup(body);
      List<Anime> lastAnimes = [];
      final lastAnimesElements =
          soup.findAll('', selector: '.ListAnimes article.Anime');
      // for every anime found we save some data
      for (var anime in lastAnimesElements) {
        final id = anime.a?['href'];

        lastAnimes.add(Anime(
          id: id?.substring(1, id.length),
          title: anime.find('', selector: 'a h3')?.string,
          poster:
              '$BASE_URL${anime.find('', selector: '.Image figure img')?['src']}',
          banner:
              '$BASE_URL${anime.find('', selector: '.Image figure img')?['src']?.replaceAll('covers', 'banners').trim()}',
          type: anime.find('', selector: 'div.Description p span.Type')?.string,
          synopsis: anime
              .findAll('', selector: 'div.Description p')[1]
              .string
              .trim()
              .replaceAll('<br/>', ''),
          rating:
              anime.find('', selector: 'div.Description p span.Vts')?.string,
        ));
      }
      // return last animes found
      return lastAnimes;
    }
    return [];
  }

  // =================================================================================================================================================
  // function to get on air animes
  static Future<List<Anime>> getAiringAnimes() async {
    // get request to base animeflv url
    final res = await _dio.get(BASE_URL);
    if (res.statusCode == 200) {
      // get html and look for last animes list
      final body = res.data.toString();
      final soup = BeautifulSoup(body);
      List<Anime> airingAnimes = [];
      final airingAnimesElements = soup.findAll('', selector: '.ListSdbr li');
      // for every anime found we save some data
      for (var anime in airingAnimesElements) {
        final id = anime.a?['href'];
        airingAnimes.add(Anime(
          id: id?.substring(1, id.length),
          title: anime.a?.string
              .replaceAll('${anime.find('', selector: '.Type')!.string}', '')
              .trim(),
          type: anime.find('', selector: '.Type')?.string,
        ));
      }
      // return list with on air animes
      return airingAnimes;
    }
    return [];
  }

  // =================================================================================================================================================
  // function to fetch the download links for the episode with id = given id
  static Future<List<ServerInfo>> downloadLinksByEpisodeId(String id) async {
    // get request using the provided id
    final res = await _dio.get('$ANIME_VIDEO_URL$id');
    if (res.statusCode == 200) {
      // parse html to string and look for the table with the downloads info
      final body = res.data.toString();
      final soup = BeautifulSoup(body);
      final table = soup.find('table', attrs: {'class': 'RTbl'});

      try {
        // extract the links and save them into ret
        final rows = parseTable(table);
        List<ServerInfo> ret = [];

        for (var row in rows) {
          if (row['FORMATO'].string == 'SUB') {
            // ret.add({
            //   'server': row['SERVIDOR'].string,
            //   'url': row['DESCARGAR'].a['href'].toString().replaceAllMapped(
            //       RegExp(
            //           r'^http[s]?://ouo.io/[A-Za-z0-9]+/[A-Za-z0-9]+\?[A-Za-z0-9]+='),
            //       (match) => '"${match.group}"')
            // });

            ret.add(ServerInfo(
              row['DESCARGAR'].a['href'].toString().replaceAllMapped(
                  RegExp(
                      r'^http[s]?://ouo.io/[A-Za-z0-9]+/[A-Za-z0-9]+\?[A-Za-z0-9]+='),
                  (match) => '"${match.group}"'),
              row['SERVIDOR'].string,
            ));
          }
        }
        // for zippyshare we can get a direct download link so we create it and replace it
        for (var server in ret) {
          if (server.server == 'Zippyshare') {
            try {
              final resZS = await _dio.get(server.url);
              if (resZS.statusCode != 200) {
                return ret;
              }
              final body = resZS.data.toString();
              final soup = BeautifulSoup(body);

              final scripts = soup.findAll('script');
              for (var script in scripts) {
                final content = script.toString();
                if (!content.contains('var n = ')) {
                  return ret;
                }
                final n = int.parse(content
                        .split('\n')[1]
                        .trim()
                        .split('var n = ')[1]
                        .split('%')[0]) %
                    2;
                final b = int.parse(content
                        .split('\n')[2]
                        .trim()
                        .split('var b = ')[1]
                        .split('%')[0]) %
                    3;
                final z = int.parse(content
                    .split('\n')[3]
                    .trim()
                    .split('var z = ')[1]
                    .split(';')[0]);
                final title = content.split('\n')[4].trim().split('"')[3];
                final serverurl = server.url
                    .replaceAll('v', 'd')
                    .replaceAll('file.html', '${n + b + z - 3}$title');
                server.url = serverurl;
              }
            } catch (e) {
              print(e);
            }
          }
        }
        // return a list with the download links and info
        return ret;
      } catch (e) {}
    }
    return List.empty();
  }

  // =================================================================================================================================================
  // function that allows you to search an anime using a query
  static Future<List<Anime>> search(String searchQuery) async {
    // get request with the given query
    final res = await Dio().get('$SEARCH_URL$searchQuery');
    if (res.statusCode == 200) {
      // get the body and look for the animes found
      final body = res.data.toString();
      final soup = BeautifulSoup(body);
      final elements = soup.findAll('article', class_: 'Anime alt B');
      List<Anime> animes = [];
      // for each of the animes found we'll save some data
      for (var element in elements) {
        var id =
            element.find('', selector: 'div.Description a.Button')?['href'];
        try {
          animes.add(Anime(
            id: id?.substring(1, id.length),
            title: element.find('', selector: 'a h3')?.string,
            poster: element.find('', selector: '.Image figure img')?['src'],
            banner: element
                .find('', selector: '.Image figure img')?['src']
                ?.replaceAll('covers', 'banners')
                .trim(),
            type: element
                .find('', selector: 'div.Description p span.Type')
                ?.string,
            synopsis: element
                .findAll('', selector: 'div.Description p')[1]
                .string
                .trim()
                .replaceAll('<br/>', ''),
            rating: element
                .find('', selector: 'div.Description p span.Vts')
                ?.string,
          ));
        } catch (e) {}
      }
      // return the list of animes found
      return animes;
    }
    return [];
  }

  // =================================================================================================================================================
  // function that gives you the servers of the episode with id = given id
  static Future<List> getVideoServers(String episodeId) async {
    // get request with the anime url using the given id
    final res = await _dio.get('$ANIME_VIDEO_URL$episodeId');
    if (res.statusCode == 200) {
      // get html and look for the scripts as animeflv saves the servers in one
      final body = res.data.toString();
      final soup = BeautifulSoup(body);
      final scripts = soup.findAll('script');
      var servers = [];
      // for every script found we'll look for the one with the servers
      for (var script in scripts) {
        final content = script.toString();
        if (content.contains('var videos = {')) {
          final videos = content.split('var videos = ')[1].split(';')[0];
          final data = json.decode(videos);
          if (data.containsKey('SUB')) servers.add(data['SUB']);
        }
      }
      // return a list of available servers with their data
      return servers[0];
    }
    return [];
  }

  // =================================================================================================================================================
  // function to get the info of an anime with its episodes
  static Future<AnimeInfo> getAnimeInfo(String animeId) async {
    // call function to get episodes info
    final animeEpisodesInfo = await _getAnimeEpisodesInfo(animeId);

    List<Episode> episodes = animeEpisodesInfo[0]!;
    final genres = animeEpisodesInfo[1]!;
    AnimeInfo extraInfo = animeEpisodesInfo[2]!;

    // return {
    //   'id': animeId,
    //   'title': extraInfo['title'],
    //   'poster': extraInfo['poster'],
    //   'banner': extraInfo['banner'],
    //   'synopsis': extraInfo['synopsis'],
    //   'rating': extraInfo['rating'],
    //   'debut': extraInfo['debut'],
    //   'type': extraInfo['type'],
    //   'airing': extraInfo['airing'],
    //   'nextEpisode': extraInfo['nextEpisode'],
    //   'relatedAnime': extraInfo['relatedAnime'],
    //   'genres': genres,
    //   'episodes': List.from(episodes.reversed),
    // };
    return extraInfo
      ..id = animeId
      ..episodes = episodes.reversed.toList()
      ..genres = genres;
  }

  // =================================================================================================================================================
  // function to get episodesInfo
  static Future<List> _getAnimeEpisodesInfo(String animeId) async {
    // get request with url using given animeId
    final res = await _dio.get('$BASE_URL/$animeId');
    if (res.statusCode == 200) {
      // getting html
      final body = res.data.toString();
      final soup = BeautifulSoup(body);

      // saving some extra info about the anime that is not about the episodes
      // Map extraInfo = {
      //   'title': soup.find('', selector: 'h1.Title')?.string,
      //   'poster':
      //       '$BASE_URL${soup.find("", selector: "div.Image figure img")?["src"]}',
      //   'synopsis': soup
      //       .find('', selector: 'div.Description p')
      //       ?.string
      //       .trim()
      //       .replaceAll('<br/>', ''),
      //   'rating': soup.find('', selector: 'span#votes_prmd')?.string,
      //   'debut': soup.find('', selector: 'p.AnmStts')?.string,
      //   'type': soup.find('', selector: 'span.Type')?.string,
      //   'airing': false,
      //   'previousEpisode':
      //       soup.find('', selector: 'a.CapNvPv.fa-chevron-left')?.string,
      //   'nextEpisode':
      //       soup.find('', selector: 'a.CapNvNx.fa-chevron-right')?.string,
      //   // 'relatedAnimes': soup
      //   //     .findAll('', selector: '.ListAnmRel li')
      //   //     .map(
      //   //       ((e) => {
      //   //             'id': e.a?.attributes['href']?.substring(1),
      //   //             'title': e.a?.text,
      //   //             'relation':
      //   //                 e.text.split('(').reversed.first.replaceAll(')', ''),
      //   //           }),
      //   //     )
      //   //     .toList()
      // };

      AnimeInfo extraInfo = AnimeInfo(
        title: soup.find('', selector: 'h1.Title')!.string,
        poster:
            '$BASE_URL${soup.find("", selector: "div.Image figure img")?["src"]}',
        banner:
            '$BASE_URL${soup.find("", selector: "div.Image figure img")?["src"]}'
                .replaceAll('covers', 'banners'),
        synopsis: soup
            .find('', selector: 'div.Description p')!
            .string
            .trim()
            .replaceAll('<br/>', ''),
        rating: soup.find('', selector: 'span#votes_prmd')!.string,
        debut: soup.find('', selector: 'p.AnmStts')!.string,
        type: soup.find('', selector: 'span.Type')!.string,
        airing: false,
        // relatedAnimes: soup
        //     .findAll('', selector: '.ListAnmRel li')
        //     .map(
        //       ((e) => {
        //             'id': e.a?.attributes['href']?.substring(1),
        //             'title': e.a?.text,
        //             'relation':
        //                 e.text.split('(').reversed.first.replaceAll(')', ''),
        //           }),
        //     )
        //     .toList()
      );

      // extraInfo['banner'] =
      //     extraInfo['poster']?.replaceAll('covers', 'banners');
      // getting the genres of the anime
      List<String> genres = [];
      final elements = soup.findAll('', selector: '.Nvgnrs a');
      for (var element in elements) {
        if (element['href']!.contains('='))
          genres.add(element['href']!.split('=')[1]);
      }

      // fetch the episodes
      var infoIds = [];
      var episodesData = [];
      List<Episode> episodes = [];

      try {
        final data = RegExp(r'var episodes = (.*?);', caseSensitive: false)
            .firstMatch(soup.body.toString())
            ?.group(1);

        if (data != null) {
          for (var episodeData in json.decode(data)) {
            episodesData.add([episodeData[0], episodeData[1]]);
          }
        }

        final animeInfo =
            RegExp(r'var anime_info = (.".*?",".*?".);', caseSensitive: false)
                .firstMatch(body)
                ?.group(1);

        if (animeInfo != null) {
          infoIds.add(json.decode(animeInfo));
        }

        if (infoIds[0].length == 4) {
          // extraInfo['airing'] = true;
          // extraInfo['nextEpisode'] = infoIds[0][3];
          extraInfo.airing = true;
          extraInfo.dateNextEpisode = DateTime.parse(infoIds[0][3]);
        }
        // now we convert this data to a map with the episode, the episodeId and the preview
        final animeId = infoIds[0][2];
        for (var episodeData in episodesData) {
          // episodes.add({
          //   'anime': extraInfo['title'],
          //   'episode': episodeData[0],
          //   'id': '$animeId-${episodeData[0]}',
          //   'imagePreview':
          //       '$BASE_EPISODE_IMG_URL${infoIds[0][0]}/${episodeData[0]}/th_3.jpg',
          // });
          episodes.add(
            Episode(
              anime: extraInfo.title,
              episode: episodeData[0]!.toString(),
              id: '$animeId-${episodeData[0]}',
              imagePreview:
                  '$BASE_EPISODE_IMG_URL${infoIds[0][0]}/${episodeData[0]}/th_3.jpg',
            ),
          );
        }
      } catch (e) {
        print(e);
      }

      // we return the episodes and the aditional fetched info
      return [episodes, genres, extraInfo];
    }
    return [];
  }
}
