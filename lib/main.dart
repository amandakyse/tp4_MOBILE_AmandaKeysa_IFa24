
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'article_model.dart';

void main() {
  runApp(const BeritaKiniApp());
}

const navy = Color(0xFF102A43);
const blue = Color(0xFF2878D0);
const bgColor = Color(0xFFF4F7FB);

class BeritaKiniApp extends StatelessWidget {
  const BeritaKiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BeritaKini',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bgColor,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
      ),
      home: const NewsPage(),
    );
  }
}

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final ApiService apiService = ApiService();
  final TextEditingController searchController =
      TextEditingController();
  final ScrollController scrollController = ScrollController();

  late Future<List<Article>> newsFuture;

  String selectedCategory = 'Semua';
  String searchQuery = '';
  bool showBackToTop = false;

  final List<String> categories = [
    'Semua',
    'Teknologi',
    'Bisnis',
    'Olahraga',
    'Hiburan',
  ];

  @override
  void initState() {
    super.initState();
    newsFuture = apiService.fetchArticles();

    scrollController.addListener(() {
      final shouldShow = scrollController.offset > 300;

      if (shouldShow != showBackToTop && mounted) {
        setState(() {
          showBackToTop = shouldShow;
        });
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void refreshNews() {
    setState(() {
      newsFuture = apiService.fetchArticles();
    });
  }

  List<Article> filterArticles(List<Article> articles) {
    return articles.where((article) {
      final title = article.title.toLowerCase();
      final description =
          (article.description ?? '').toLowerCase();

      return title.contains(searchQuery) ||
          description.contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: showBackToTop
          ? FloatingActionButton(
              backgroundColor: navy,
              foregroundColor: Colors.white,
              tooltip: 'Kembali ke atas',
              onPressed: () {
                scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Icon(Icons.arrow_upward_rounded),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FutureBuilder<List<Article>>(
                future: newsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: blue,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildMessage(
                      'Gagal memuat berita.\n${snapshot.error}',
                    );
                  }

                  final articles =
                      filterArticles(snapshot.data ?? []);

                  if (articles.isEmpty) {
                    return _buildMessage(
                      'Berita tidak ditemukan.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      refreshNews();
                      await newsFuture;
                    },
                    child: ListView(
                      controller: scrollController,
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        20, 20, 20, 30,
                      ),
                      children: [
                        const Text(
                          'Halo, selamat datang!',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Temukan informasi terbaru hari ini.',
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 9),
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              return ChoiceChip(
                                label: Text(category),
                                selected:
                                    selectedCategory == category,
                                showCheckmark: false,
                                onSelected: (_) {
                                  setState(() {
                                    selectedCategory = category;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Berita Terbaru',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildFeaturedArticle(articles.first),
                        const SizedBox(height: 26),
                        const Text(
                          'Berita Lainnya',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...articles.skip(1).map(_buildNewsCard),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: navy,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.newspaper_rounded,
                color: Colors.white,
                size: 30,
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BeritaKini',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Informasi terkini untukmu',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase().trim();
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari berita...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedArticle(Article article) {
    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(article.urlToImage, 210),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HEADLINE UTAMA',
                  style: TextStyle(
                    color: blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  article.title,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((article.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(article.description!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(Article article) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildImage(
                article.urlToImage,
                100,
                width: 110,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                article.title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(
    String? url,
    double height, {
    double? width,
  }) {
    if (url == null || url.isEmpty) {
      return Container(
        height: height,
        width: width ?? double.infinity,
        color: const Color(0xFFE6EDF5),
        child: const Icon(Icons.image_not_supported),
      );
    }

    return Image.network(
      url,
      height: height,
      width: width ?? double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: width ?? double.infinity,
        color: const Color(0xFFE6EDF5),
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: blue,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: refreshNews,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
