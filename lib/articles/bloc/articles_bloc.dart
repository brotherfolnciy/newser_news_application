import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:news_application/articles/models/models.dart';
import 'package:news_application/utils/load_info.dart';
import 'package:news_repository/news_repository.dart';
import 'package:logger/logger.dart';

part 'articles_event.dart';
part 'articles_state.dart';

class ArticlesBloc extends Bloc<ArticlesEvent, ArticlesState> {
  ArticlesBloc({required newsRepository})
      : _newsRepository = newsRepository,
        super(const ArticlesState(articles: [])) {
    on<ArticlesLoadInfoChanged>(_articleLoadInfoChanged);
    on<SelectedSectionIndexChanged>(_onSelectedSectionIndexChanged);
    on<LoadArticlesByIndex>(_onLoadSectionArticlesByIndex);
    on<LoadArticlesBySectionName>(_onLoadSectionArticlesBySectionName);
  }

  final NewsRepository _newsRepository;
  final Logger logger = Logger();

  void _onLoadSectionArticlesByIndex(
    LoadArticlesByIndex event,
    Emitter<ArticlesState> emit,
  ) async {
    await _onLoadSectionArticles(
        _getSectionNameByIndex(event.sectionIndex), emit);
  }

  void _onLoadSectionArticlesBySectionName(
    LoadArticlesBySectionName event,
    Emitter<ArticlesState> emit,
  ) async {
    await _onLoadSectionArticles(event.sectionName, emit);
  }

  Future<void> _onLoadSectionArticles(
    String sectionName,
    Emitter<ArticlesState> emit,
  ) async {
    _articleLoadInfoChanged(ArticlesLoadInfoChanged(LoadInfo.load), emit);
    await _getSectionArticles(sectionName, emit).then(
      (value) {
        emit.call(
          state.copyWith(articles: _getArticlesData(value.articles)),
        );
        _articleLoadInfoChanged(ArticlesLoadInfoChanged(LoadInfo.loaded), emit);
      },
    ).onError((error, stackTrace) {
      _articleLoadInfoChanged(
          ArticlesLoadInfoChanged(LoadInfo.error.copyWith(message: 'error')),
          emit);
    });
  }

  void _articleLoadInfoChanged(
    ArticlesLoadInfoChanged event,
    Emitter<ArticlesState> emit,
  ) async {
    if (event.info.status == LoadStatus.load) {
      emit.call(state.copyWith(loadInfo: event.info));
    } else if (event.info.status == LoadStatus.notLoaded) {
      emit.call(state.copyWith(loadInfo: event.info));
    } else if (event.info.status == LoadStatus.loaded) {
      emit.call(state.copyWith(loadInfo: event.info));
    } else if (event.info.status == LoadStatus.error) {
      emit.call(state.copyWith(loadInfo: event.info));
    }
    logger.i(
        'Articles load status changed: ${event.info.status} with message: ${event.info.message}');
  }

  void _onSelectedSectionIndexChanged(
    SelectedSectionIndexChanged event,
    Emitter<ArticlesState> emit,
  ) {
    emit.call(state.copyWith(
        selectedSectionName: _getSectionNameByIndex(event.sectionIndex)));
  }

  String _getSectionNameByIndex(int index) {
    String? section = _newsRepository.getSections[index].section;
    return section ?? 'world';
  }

  Future<SectionArticles> _getSectionArticles(
    String section,
    Emitter<ArticlesState> emit,
  ) async {
    return await _newsRepository
        .getSectionArticles(section)
        .onError((error, stackTrace) {
      _articleLoadInfoChanged(ArticlesLoadInfoChanged(LoadInfo.error), emit);
      throw Exception(error);
    });
  }

  List<ArticleData> _getArticlesData(List<Article> articles) {
    return articles
        .map(
          (e) => ArticleData(
            title: e.title,
            slugName: e.slug_name,
            section: e.section,
            subsection: e.subsection,
            url: e.url,
            subheadline: e.subhead_line,
            source: e.source,
            publishedDate: _formateDateFromString(e.published_date),
            multimedia: _getMultimediaData(e.multimedia),
            abstract: e.abstract,
            byline: e.byline,
          ),
        )
        .toList();
  }

  String? _formateDateFromString(String? date) {
    return date;
  }

  List<MultimediaData>? _getMultimediaData(List<Multimedia>? multimedia) {
    if (multimedia != null) {
      return multimedia
          .map(
            (e) => MultimediaData(
              url: e.url,
              format: e.format,
              height: e.height,
              width: e.width,
              type: e.type,
              subtype: e.subtype,
              caption: e.caption,
              copyright: e.copyright,
            ),
          )
          .toList();
    } else {
      return null;
    }
  }
}