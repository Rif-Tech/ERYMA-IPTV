import 'package:flutter/material.dart';

import '../../core/db/database.dart';
import '../movies/movies_screen.dart';

class SeriesScreen extends StatelessWidget {
  const SeriesScreen({super.key});
  @override
  Widget build(BuildContext context) => const ContentBrowser(kind: ContentKind.series);
}
