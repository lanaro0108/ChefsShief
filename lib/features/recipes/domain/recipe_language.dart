/// Local culinary labels and common search terms. Recipe prose is translated
/// separately; changing a label never changes a saved recipe.
abstract final class RecipeLanguage {
  static String normalize(String value) {
    var result = value.trim().toLowerCase();
    const accents = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const plain = 'aaaaaeeeeiiiiooooouuuuc';
    for (var index = 0; index < accents.length; index++) {
      result = result.replaceAll(accents[index], plain[index]);
    }
    return result.replaceAll(RegExp(r'\s+'), ' ');
  }

  static const categories = {
    'Beef': 'Carne bovina',
    'Breakfast': 'Café da manhã',
    'Chicken': 'Frango',
    'Dessert': 'Sobremesas',
    'Goat': 'Carne de cabra',
    'Lamb': 'Cordeiro',
    'Miscellaneous': 'Outras receitas',
    'Pasta': 'Massas',
    'Pork': 'Carne suína',
    'Seafood': 'Peixes e frutos do mar',
    'Side': 'Acompanhamentos',
    'Starter': 'Entradas',
    'Vegan': 'Vegano',
    'Vegetarian': 'Vegetariano',
  };

  static const areas = {
    'American': 'Americana', 'Argentinian': 'Argentina',
    'Australian': 'Australiana', 'Brazilian': 'Brasileira',
    'British': 'Britânica', 'Canadian': 'Canadense',
    'Chinese': 'Chinesa', 'Croatian': 'Croata', 'Dutch': 'Holandesa',
    'Egyptian': 'Egípcia', 'Filipino': 'Filipina', 'French': 'Francesa',
    'Greek': 'Grega', 'Indian': 'Indiana', 'Irish': 'Irlandesa',
    'Italian': 'Italiana', 'Jamaican': 'Jamaicana', 'Japanese': 'Japonesa',
    'Kenyan': 'Queniana', 'Malaysian': 'Malaia', 'Mexican': 'Mexicana',
    'Moroccan': 'Marroquina', 'Polish': 'Polonesa', 'Portuguese': 'Portuguesa',
    'Russian': 'Russa', 'Saudi Arabian': 'Saudita', 'Spanish': 'Espanhola',
    'Thai': 'Tailandesa', 'Tunisian': 'Tunisiana', 'Turkish': 'Turca',
    'Ukrainian': 'Ucraniana', 'Uruguayan': 'Uruguaia', 'Vietnamese': 'Vietnamita',
    'Unknown': 'Cozinha do mundo',
  };

  static String category(String value) => categories[value] ?? value;
  static String area(String value) => areas[value] ?? value;

  static String? searchCategory(String query) => const {
    'frango': 'Chicken', 'chicken': 'Chicken',
    'massa': 'Pasta', 'massas': 'Pasta', 'pasta': 'Pasta',
    'sobremesa': 'Dessert', 'sobremesas': 'Dessert', 'dessert': 'Dessert',
    'vegetariano': 'Vegetarian', 'vegetariana': 'Vegetarian',
    'vegetarian': 'Vegetarian', 'vegano': 'Vegan', 'vegan': 'Vegan',
    'carne bovina': 'Beef', 'carne suina': 'Pork', 'porco': 'Pork',
    'cordeiro': 'Lamb', 'frutos do mar': 'Seafood', 'peixe': 'Seafood',
    'acompanhamentos': 'Side', 'entradas': 'Starter',
    'cafe da manha': 'Breakfast',
  }[normalize(query)];

  static String searchName(String query) {
    final normalized = normalize(query);
    const phrases = {
      'bolo de chocolate': 'chocolate cake',
      'bolo de cenoura': 'carrot cake',
      'bolo de limao': 'lemon cake',
      'frango com curry': 'chicken curry',
      'frango ao curry': 'chicken curry',
      'arroz com frango': 'chicken rice',
      'sopa de tomate': 'tomato soup',
      'carne moida': 'minced beef',
      'pure de batata': 'mashed potato',
      'torta de maca': 'apple pie',
      'pao de alho': 'garlic bread',
      'macarrao': 'pasta', 'bolo': 'cake', 'bolos': 'cake',
      'sopa': 'soup', 'arroz': 'rice', 'batata': 'potato',
      'salmao': 'salmon', 'camarao': 'prawn', 'salada': 'salad',
      'panqueca': 'pancake', 'panquecas': 'pancake',
      'lasanha': 'lasagne', 'biscoito': 'biscuit', 'biscoitos': 'biscuit',
      'chocolate': 'chocolate', 'pudim': 'pudding', 'queijo': 'cheese',
      'tomate': 'tomato', 'cogumelo': 'mushroom', 'cogumelos': 'mushroom',
    };
    if (phrases.containsKey(normalized)) return phrases[normalized]!;
    // Keep international names and unknown text intact.
    return query.trim();
  }

  static List<String> readableSteps(List<String> paragraphs) => [
    for (final paragraph in paragraphs)
      if (paragraph.length > 260)
        ...paragraph.split(RegExp(r'(?<=[.!?])\s+(?=[A-ZÀ-Ý])'))
      else
        paragraph,
  ];
}
