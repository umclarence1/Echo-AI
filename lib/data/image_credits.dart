class ImageCredit {
  final String label;
  final String author;
  final String license;
  final String source;

  const ImageCredit({
    required this.label,
    required this.author,
    required this.license,
    required this.source,
  });
}

/// Attribution for the real photos used where ARASAAC has no pictogram
/// (Ghanaian dishes, trotro). Required by their Creative Commons licenses.
/// All sourced from Wikimedia Commons.
const List<ImageCredit> imageCredits = [
  ImageCredit(
    label: 'Fufu',
    author: 'HarunaSylvester',
    license: 'CC BY-SA 4.0',
    source: 'Wikimedia Commons - "Fufu 1.jpg"',
  ),
  ImageCredit(
    label: 'Banku',
    author: 'Afimaame',
    license: 'CC BY-SA 4.0',
    source: 'Wikimedia Commons - "Banku and Okro stew.jpg"',
  ),
  ImageCredit(
    label: 'Kenkey',
    author: 'Danieljatuat',
    license: 'CC BY-SA 4.0',
    source: 'Wikimedia Commons - "Kenkey (Ghana Food).jpg"',
  ),
  ImageCredit(
    label: 'Jollof Rice',
    author: 'Queen Murja10',
    license: 'CC BY-SA 4.0',
    source: 'Wikimedia Commons - "Ghana Jollof Rice with Chicken.jpg"',
  ),
  ImageCredit(
    label: 'Waakye',
    author: 'Ruby Kodie',
    license: 'CC BY-SA 4.0',
    source: 'Wikimedia Commons - "Waakye 001.jpg"',
  ),
  ImageCredit(
    label: 'Kelewele',
    author: 'Mac-Jordan Degadjor; derivative by Tbom824',
    license: 'CC BY 2.0',
    source: 'Wikimedia Commons - "Kelewele.jpg"',
  ),
  ImageCredit(
    label: 'Trotro',
    author: 'Lisa Coulaud',
    license: 'CC BY-SA 4.0',
    source: 'Wikimedia Commons - "Gare routiere de minibus Tro Tro (Accra).jpg"',
  ),
];
