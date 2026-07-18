class EnglishQuizQuestion {
  const EnglishQuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final int id;
  final String question;
  final List<String> options;
  final int correctIndex;
}

/// Simple English questions for a 10-year-old — vocabulary and basic grammar.
/// 5 are picked at random each day; correctIndex is the index into [options].
const List<EnglishQuizQuestion> kEnglishQuizBank = [
  EnglishQuizQuestion(id: 1, question: 'What color is the sky?', options: ['Green', 'Blue', 'Red', 'Yellow'], correctIndex: 1),
  EnglishQuizQuestion(id: 2, question: 'What color is grass?', options: ['Green', 'Purple', 'Blue', 'Black'], correctIndex: 0),
  EnglishQuizQuestion(id: 3, question: 'How many days are in a week?', options: ['5', '6', '7', '8'], correctIndex: 2),
  EnglishQuizQuestion(id: 4, question: 'How many months are in a year?', options: ['10', '11', '12', '13'], correctIndex: 2),
  EnglishQuizQuestion(id: 5, question: 'What is the opposite of "big"?', options: ['Small', 'Tall', 'Fast', 'Heavy'], correctIndex: 0),
  EnglishQuizQuestion(id: 6, question: 'What is the opposite of "hot"?', options: ['Warm', 'Cold', 'Wet', 'Dry'], correctIndex: 1),
  EnglishQuizQuestion(id: 7, question: 'What is the opposite of "happy"?', options: ['Sad', 'Angry', 'Tired', 'Sleepy'], correctIndex: 0),
  EnglishQuizQuestion(id: 8, question: 'What is the opposite of "up"?', options: ['Left', 'Down', 'Right', 'Over'], correctIndex: 1),
  EnglishQuizQuestion(id: 9, question: 'Which animal says "meow"?', options: ['Dog', 'Cat', 'Cow', 'Duck'], correctIndex: 1),
  EnglishQuizQuestion(id: 10, question: 'Which animal says "woof"?', options: ['Dog', 'Cat', 'Bird', 'Sheep'], correctIndex: 0),
  EnglishQuizQuestion(id: 11, question: 'What do we call a baby dog?', options: ['Kitten', 'Puppy', 'Cub', 'Chick'], correctIndex: 1),
  EnglishQuizQuestion(id: 12, question: 'What do we call a baby cat?', options: ['Kitten', 'Puppy', 'Foal', 'Lamb'], correctIndex: 0),
  EnglishQuizQuestion(id: 13, question: 'What is the plural of "child"?', options: ['Childs', 'Children', 'Childes', 'Childrens'], correctIndex: 1),
  EnglishQuizQuestion(id: 14, question: 'What is the plural of "mouse"?', options: ['Mouses', 'Mice', 'Mices', 'Mouse'], correctIndex: 1),
  EnglishQuizQuestion(id: 15, question: 'What is the plural of "book"?', options: ['Books', 'Bookes', 'Book', 'Booken'], correctIndex: 0),
  EnglishQuizQuestion(id: 16, question: 'Which one is a fruit?', options: ['Carrot', 'Potato', 'Apple', 'Onion'], correctIndex: 2),
  EnglishQuizQuestion(id: 17, question: 'Which one is a vegetable?', options: ['Banana', 'Carrot', 'Orange', 'Grape'], correctIndex: 1),
  EnglishQuizQuestion(id: 18, question: 'What do you drink when you are thirsty?', options: ['Water', 'Bread', 'Rice', 'Meat'], correctIndex: 0),
  EnglishQuizQuestion(id: 19, question: 'Which meal do you eat in the morning?', options: ['Dinner', 'Lunch', 'Breakfast', 'Snack'], correctIndex: 2),
  EnglishQuizQuestion(id: 20, question: 'How do you say "مرحبا" in English?', options: ['Goodbye', 'Hello', 'Please', 'Sorry'], correctIndex: 1),
  EnglishQuizQuestion(id: 21, question: 'How do you say "شكرا" in English?', options: ['Sorry', 'Please', 'Thank you', 'Welcome'], correctIndex: 2),
  EnglishQuizQuestion(id: 22, question: 'How do you say "مع السلامة" in English?', options: ['Hello', 'Goodbye', 'Yes', 'No'], correctIndex: 1),
  EnglishQuizQuestion(id: 23, question: 'What do you use to write?', options: ['Pen', 'Plate', 'Spoon', 'Shoe'], correctIndex: 0),
  EnglishQuizQuestion(id: 24, question: 'What do you sit on at school?', options: ['Table', 'Chair', 'Board', 'Bag'], correctIndex: 1),
  EnglishQuizQuestion(id: 25, question: 'Where do you learn with a teacher?', options: ['Kitchen', 'School', 'Garage', 'Garden'], correctIndex: 1),
  EnglishQuizQuestion(id: 26, question: 'What do you use to see far away? (a body part)', options: ['Ears', 'Eyes', 'Nose', 'Hands'], correctIndex: 1),
  EnglishQuizQuestion(id: 27, question: 'What do you use to hear?', options: ['Eyes', 'Mouth', 'Ears', 'Feet'], correctIndex: 2),
  EnglishQuizQuestion(id: 28, question: 'How many fingers does one hand have?', options: ['4', '5', '6', '10'], correctIndex: 1),
  EnglishQuizQuestion(id: 29, question: 'What is 2 + 3 in English words?', options: ['Four', 'Five', 'Six', 'Seven'], correctIndex: 1),
  EnglishQuizQuestion(id: 30, question: 'What is 10 - 4 in English words?', options: ['Five', 'Six', 'Seven', 'Eight'], correctIndex: 1),
  EnglishQuizQuestion(id: 31, question: 'What day comes after Sunday?', options: ['Saturday', 'Monday', 'Tuesday', 'Friday'], correctIndex: 1),
  EnglishQuizQuestion(id: 32, question: 'What day comes before Friday?', options: ['Wednesday', 'Thursday', 'Saturday', 'Monday'], correctIndex: 1),
  EnglishQuizQuestion(id: 33, question: 'What is the weather like when it rains?', options: ['Sunny', 'Rainy', 'Dry', 'Hot'], correctIndex: 1),
  EnglishQuizQuestion(id: 34, question: 'What do you wear on your feet?', options: ['Hat', 'Gloves', 'Shoes', 'Scarf'], correctIndex: 2),
  EnglishQuizQuestion(id: 35, question: 'What do you wear on your head when it is sunny?', options: ['Hat', 'Shoes', 'Belt', 'Socks'], correctIndex: 0),
  EnglishQuizQuestion(id: 36, question: 'Who is your father\'s father to you?', options: ['Uncle', 'Grandfather', 'Cousin', 'Brother'], correctIndex: 1),
  EnglishQuizQuestion(id: 37, question: 'Who is your mother\'s sister to you?', options: ['Aunt', 'Grandmother', 'Niece', 'Sister'], correctIndex: 0),
  EnglishQuizQuestion(id: 38, question: 'What do you call your father\'s son (not you)?', options: ['Brother', 'Cousin', 'Uncle', 'Nephew'], correctIndex: 0),
  EnglishQuizQuestion(id: 39, question: 'Which is the correct sentence?', options: ['She go to school', 'She goes to school', 'She going to school', 'She gone to school'], correctIndex: 1),
  EnglishQuizQuestion(id: 40, question: 'Which is the correct sentence?', options: ['I is happy', 'I am happy', 'I are happy', 'I be happy'], correctIndex: 1),
];
