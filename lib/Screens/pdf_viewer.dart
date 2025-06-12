import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

class PDFViewScreen extends StatelessWidget {
  final String url;
  final String judul;

  const PDFViewScreen({super.key, required this.url, required this.judul});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(judul),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: const Center(child: CircularProgressIndicator()),
      bottomSheet: SizedBox(
        height: MediaQuery.of(context).size.height - 100,
        child: PDF().fromUrl(
          url,
          placeholder: (progress) => Center(child: Text('$progress %')),
          errorWidget: (error) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }
}
