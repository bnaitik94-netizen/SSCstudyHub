class Chapter {
  final String title;
  final String pdfFileName;

  const Chapter(this.title, this.pdfFileName);
}

class Subject {
  final String name;
  final List<Chapter> chapters;

  const Subject(this.name, this.chapters);
}
