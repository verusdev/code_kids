import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../theme/app_theme.dart';
import '../game_common.dart';

/// Часть системы: эмодзи + короткая подпись.
class PartItem {
  const PartItem(this.emoji, this.label);

  final String emoji;
  final String label;
}

/// Уровень игры «Части и целое»: у системы не хватает одной части.
class PartsLevel {
  const PartsLevel({
    required this.title,
    required this.wholeEmoji,
    required this.parts,
    required this.missingIndex,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  /// Название системы, например «Растение».
  final String title;

  /// Эмодзи самой системы (целого).
  final String wholeEmoji;

  /// Полный набор частей; одна из них на уровне скрыта (показан ❓).
  final List<PartItem> parts;
  final int missingIndex;

  /// Варианты ответа: какая часть пропала.
  final List<PartItem> options;
  final int correctIndex;
  final String explanation;
}

final List<PartsLevel> _partsLevels = [
  const PartsLevel(
    title: 'Растение',
    wholeEmoji: '🌱',
    parts: [
      PartItem('💧', 'Вода'),
      PartItem('☀️', 'Свет'),
      PartItem('🌍', 'Земля'),
      PartItem('🌬️', 'Воздух'),
    ],
    missingIndex: 3,
    options: [
      PartItem('🌬️', 'Воздух'),
      PartItem('🎈', 'Шарик'),
      PartItem('🍬', 'Конфета'),
    ],
    correctIndex: 0,
    explanation: 'Растению нужны вода 💧, свет ☀️, земля 🌍 и воздух 🌬️. '
        'Убери любую часть — и оно не вырастет.',
  ),
  const PartsLevel(
    title: 'Круговорот воды',
    wholeEmoji: '🌧️',
    parts: [
      PartItem('☀️', 'Солнце'),
      PartItem('☁️', 'Облако'),
      PartItem('🌧️', 'Дождь'),
      PartItem('🏞️', 'Река'),
    ],
    missingIndex: 3,
    options: [
      PartItem('🏞️', 'Река'),
      PartItem('🔥', 'Костёр'),
      PartItem('🧊', 'Лёд'),
    ],
    correctIndex: 0,
    explanation: 'Это круговорот воды: солнце ☀️ поднимает воду вверх, '
        'получается облако ☁️, идёт дождь 🌧️, а вода стекает в реку 🏞️. '
        'Потом всё повторяется!',
  ),
  const PartsLevel(
    title: 'Лес',
    wholeEmoji: '🌳',
    parts: [
      PartItem('🌳', 'Деревья'),
      PartItem('🐦', 'Птицы'),
      PartItem('🐛', 'Насекомые'),
      PartItem('🍄', 'Грибы'),
    ],
    missingIndex: 2,
    options: [
      PartItem('🐛', 'Насекомые'),
      PartItem('🚗', 'Машина'),
      PartItem('🏢', 'Дом'),
    ],
    correctIndex: 0,
    explanation: 'В лесу всё связано: деревья 🌳, птицы 🐦, насекомые 🐛 и '
        'грибы 🍄 — это одна большая система.',
  ),
  const PartsLevel(
    title: 'Фонарик',
    wholeEmoji: '🔦',
    parts: [
      PartItem('🔋', 'Батарейка'),
      PartItem('💡', 'Лампочка'),
      PartItem('🔘', 'Кнопка'),
      PartItem('📦', 'Корпус'),
    ],
    missingIndex: 0,
    options: [
      PartItem('🔋', 'Батарейка'),
      PartItem('🍎', 'Яблоко'),
      PartItem('🎈', 'Шарик'),
    ],
    correctIndex: 0,
    explanation: 'Фонарик — это корпус 📦, батарейка 🔋, лампочка 💡 и '
        'кнопка 🔘. Без батарейки он не загорится.',
  ),
  const PartsLevel(
    title: 'Дом',
    wholeEmoji: '🏠',
    parts: [
      PartItem('🧱', 'Стены'),
      PartItem('🪟', 'Окно'),
      PartItem('🚪', 'Дверь'),
      PartItem('🏠', 'Крыша'),
    ],
    missingIndex: 3,
    options: [
      PartItem('🏠', 'Крыша'),
      PartItem('🚗', 'Машина'),
      PartItem('🌳', 'Дерево'),
    ],
    correctIndex: 0,
    explanation: 'Дом — это стены 🧱, окно 🪟, дверь 🚪 и крыша 🏠. '
        'Без крыши дождь попадёт внутрь.',
  ),
  const PartsLevel(
    title: 'Тело человека',
    wholeEmoji: '🧒',
    parts: [
      PartItem('❤️', 'Сердце'),
      PartItem('👀', 'Глаза'),
      PartItem('🧠', 'Мозг'),
      PartItem('🦴', 'Кости'),
    ],
    missingIndex: 1,
    options: [
      PartItem('👀', 'Глаза'),
      PartItem('🎩', 'Шляпа'),
      PartItem('👟', 'Кроссовки'),
    ],
    correctIndex: 0,
    explanation: 'Тело человека — система: сердце ❤️, глаза 👀, мозг 🧠 и '
        'кости 🦴. Все части работают вместе.',
  ),
  const PartsLevel(
    title: 'Велосипед',
    wholeEmoji: '🚲',
    parts: [
      PartItem('🛞', 'Колёса'),
      PartItem('🔗', 'Цепь'),
      PartItem('💺', 'Сиденье'),
      PartItem('🛑', 'Тормоз'),
    ],
    missingIndex: 3,
    options: [
      PartItem('🛑', 'Тормоз'),
      PartItem('☂️', 'Зонт'),
      PartItem('🧤', 'Перчатки'),
    ],
    correctIndex: 0,
    explanation: 'У велосипеда есть колёса 🛞, цепь 🔗, сиденье 💺 и '
        'тормоз 🛑. Без тормоза ехать опасно!',
  ),
  const PartsLevel(
    title: 'Аквариум',
    wholeEmoji: '🐠',
    parts: [
      PartItem('💧', 'Вода'),
      PartItem('🐟', 'Рыбки'),
      PartItem('🌿', 'Водоросли'),
      PartItem('🪨', 'Камни'),
    ],
    missingIndex: 0,
    options: [
      PartItem('💧', 'Вода'),
      PartItem('🔥', 'Огонь'),
      PartItem('🧊', 'Лёд'),
    ],
    correctIndex: 0,
    explanation: 'Аквариум — это вода 💧, рыбки 🐟, водоросли 🌿 и камни 🪨. '
        'Без воды рыбки не смогут жить.',
  ),
  const PartsLevel(
    title: 'Компьютер',
    wholeEmoji: '💻',
    parts: [
      PartItem('🖥️', 'Экран'),
      PartItem('⌨️', 'Клавиатура'),
      PartItem('🖱️', 'Мышка'),
      PartItem('🔌', 'Питание'),
    ],
    missingIndex: 0,
    options: [
      PartItem('🖥️', 'Экран'),
      PartItem('🍕', 'Пицца'),
      PartItem('🧦', 'Носок'),
    ],
    correctIndex: 0,
    explanation: 'Чтобы работать за компьютером, нужны экран 🖥️, '
        'клавиатура ⌨️, мышка 🖱️ и питание 🔌.',
  ),
  const PartsLevel(
    title: 'Муравейник',
    wholeEmoji: '🐜',
    parts: [
      PartItem('🐜', 'Муравьи'),
      PartItem('🥚', 'Яйца'),
      PartItem('🍃', 'Еда'),
      PartItem('🏰', 'Домик'),
    ],
    missingIndex: 0,
    options: [
      PartItem('🐜', 'Муравьи'),
      PartItem('🐘', 'Слон'),
      PartItem('🐬', 'Дельфин'),
    ],
    correctIndex: 0,
    explanation: 'Муравейник — это домик 🏰, еда 🍃, яйца 🥚 и, конечно, '
        'сами муравьи 🐜. Без них домик пустой.',
  ),
  const PartsLevel(
    title: 'Город',
    wholeEmoji: '🏙️',
    parts: [
      PartItem('🏠', 'Дома'),
      PartItem('🛣️', 'Дороги'),
      PartItem('🚦', 'Светофоры'),
      PartItem('🏫', 'Школы'),
      PartItem('🌳', 'Парки'),
      PartItem('🚰', 'Водопровод'),
    ],
    missingIndex: 5,
    options: [
      PartItem('🏠', 'Дома'),
      PartItem('🚌', 'Автобусы'),
      PartItem('🚰', 'Водопровод'),
      PartItem('🚦', 'Светофоры'),
    ],
    correctIndex: 2,
    explanation: 'Город — это большая система: дома 🏠, дороги 🛣️, светофоры 🚦, '
        'школы 🏫, парки 🌳 и водопровод 🚰. Без водопровода в домах не будет воды.',
  ),
  const PartsLevel(
    title: 'Оркестр',
    wholeEmoji: '🎵',
    parts: [
      PartItem('🎻', 'Скрипки'),
      PartItem('🎺', 'Трубы'),
      PartItem('🥁', 'Барабаны'),
      PartItem('🎹', 'Рояль'),
      PartItem('🎼', 'Дирижёр'),
    ],
    missingIndex: 4,
    options: [
      PartItem('🥁', 'Барабаны'),
      PartItem('🎼', 'Дирижёр'),
      PartItem('🎻', 'Скрипки'),
      PartItem('🎺', 'Трубы'),
    ],
    correctIndex: 1,
    explanation: 'В оркестре вместе играют скрипки 🎻, трубы 🎺, барабаны 🥁 и '
        'рояль 🎹, а дирижёр 🎼 показывает, когда вступать каждому.',
  ),
  const PartsLevel(
    title: 'Космический корабль',
    wholeEmoji: '🚀',
    parts: [
      PartItem('🚀', 'Корпус'),
      PartItem('⛽', 'Топливо'),
      PartItem('🛰️', 'Кабина'),
      PartItem('📡', 'Антенна'),
      PartItem('👨‍🚀', 'Космонавт'),
    ],
    missingIndex: 1,
    options: [
      PartItem('📡', 'Антенна'),
      PartItem('⛽', 'Топливо'),
      PartItem('🛰️', 'Кабина'),
      PartItem('👨‍🚀', 'Космонавт'),
    ],
    correctIndex: 1,
    explanation: 'Космический корабль — это корпус 🚀, топливо ⛽, кабина 🛰️, '
        'антенна 📡 и космонавт 👨‍🚀. Без топлива ракета не взлетит.',
  ),
  const PartsLevel(
    title: 'Рецепт блинов',
    wholeEmoji: '🥞',
    parts: [
      PartItem('🥚', 'Яйца'),
      PartItem('🥛', 'Молоко'),
      PartItem('🌾', 'Мука'),
      PartItem('🧈', 'Масло'),
      PartItem('🍯', 'Мёд'),
    ],
    missingIndex: 2,
    options: [
      PartItem('🥚', 'Яйца'),
      PartItem('🧈', 'Масло'),
      PartItem('🌾', 'Мука'),
      PartItem('🥛', 'Молоко'),
    ],
    correctIndex: 2,
    explanation: 'Для блинов нужны яйца 🥚, молоко 🥛, мука 🌾, масло 🧈 и мёд 🍯 '
        'для вкуса. Без муки тесто не получится.',
  ),
  const PartsLevel(
    title: 'Дерево',
    wholeEmoji: '🌳',
    parts: [
      PartItem('🌱', 'Корень'),
      PartItem('🪵', 'Ствол'),
      PartItem('🌿', 'Ветки'),
      PartItem('🍃', 'Листья'),
      PartItem('🌸', 'Цветы'),
      PartItem('🍎', 'Плоды'),
    ],
    missingIndex: 3,
    options: [
      PartItem('🪵', 'Ствол'),
      PartItem('🌸', 'Цветы'),
      PartItem('🍃', 'Листья'),
      PartItem('🌱', 'Корень'),
    ],
    correctIndex: 2,
    explanation: 'Дерево состоит из корня 🌱, ствола 🪵, веток 🌿, листьев 🍃, '
        'цветов 🌸 и плодов 🍎. Листья ловят свет — без них дерево ослабнет.',
  ),
  const PartsLevel(
    title: 'Часы',
    wholeEmoji: '🕰️',
    parts: [
      PartItem('⚙️', 'Механизм'),
      PartItem('🔋', 'Батарейка'),
      PartItem('🕓', 'Циферблат'),
      PartItem('🪟', 'Стекло'),
    ],
    missingIndex: 2,
    options: [
      PartItem('🕓', 'Циферблат'),
      PartItem('🍎', 'Яблоко'),
      PartItem('🚗', 'Машина'),
    ],
    correctIndex: 0,
    explanation: 'В часах есть механизм ⚙️, батарейка 🔋, циферблат 🕓 и '
        'стекло 🪟. На циферблате нарисованы цифры — без него время не увидеть.',
  ),
  const PartsLevel(
    title: 'Радио',
    wholeEmoji: '📻',
    parts: [
      PartItem('🔋', 'Батарейка'),
      PartItem('🔊', 'Динамик'),
      PartItem('📡', 'Антенна'),
      PartItem('🔘', 'Кнопка'),
    ],
    missingIndex: 1,
    options: [
      PartItem('🔊', 'Динамик'),
      PartItem('🎸', 'Гитара'),
      PartItem('🍞', 'Хлеб'),
    ],
    correctIndex: 0,
    explanation: 'Из радио слышны передачи — для звука нужен динамик 🔊. '
        'Батарейка 🔋 даёт энергию, антенна 📡 ловит сигнал, кнопка 🔘 включает.',
  ),
  const PartsLevel(
    title: 'Солнечная система',
    wholeEmoji: '🌍',
    parts: [
      PartItem('☀️', 'Солнце'),
      PartItem('🪐', 'Планеты'),
      PartItem('☄️', 'Кометы'),
      PartItem('🛰️', 'Спутники'),
    ],
    missingIndex: 1,
    options: [
      PartItem('🪐', 'Планеты'),
      PartItem('🌊', 'Волны'),
      PartItem('🏖️', 'Пляж'),
    ],
    correctIndex: 0,
    explanation: 'Вокруг Солнца ☀️ кружатся планеты 🪐, а ещё там летают '
        'кометы ☄️ и работают спутники 🛰️. Волны и пляж бывают только на планетах!',
  ),
  const PartsLevel(
    title: 'Суп',
    wholeEmoji: '🍲',
    parts: [
      PartItem('🥔', 'Картошка'),
      PartItem('🥕', 'Морковь'),
      PartItem('🧅', 'Лук'),
      PartItem('🍖', 'Мясо'),
    ],
    missingIndex: 1,
    options: [
      PartItem('🥕', 'Морковь'),
      PartItem('🍩', 'Пончик'),
      PartItem('🧁', 'Торт'),
    ],
    correctIndex: 0,
    explanation: 'В суп кладут картошку 🥔, морковь 🥕, лук 🧅 и мясо 🍖. '
        'Пончик и торт в суп не попадут — это десерты!',
  ),
  const PartsLevel(
    title: 'Печенье',
    wholeEmoji: '🍪',
    parts: [
      PartItem('🌾', 'Мука'),
      PartItem('🥚', 'Яйцо'),
      PartItem('🧈', 'Масло'),
      PartItem('🍬', 'Сахар'),
    ],
    missingIndex: 3,
    options: [
      PartItem('🍬', 'Сахар'),
      PartItem('🪨', 'Камень'),
      PartItem('🚲', 'Велосипед'),
    ],
    correctIndex: 0,
    explanation: 'Тесто на печенье замешивают из муки 🌾, яиц 🥚, масла 🧈 '
        'и сахара 🍬. Камень и велосипед в тесто не положат.',
  ),
  const PartsLevel(
    title: 'Мост',
    wholeEmoji: '🌉',
    parts: [
      PartItem('🪨', 'Опоры'),
      PartItem('🪵', 'Настил'),
      PartItem('🛡️', 'Перила'),
      PartItem('💡', 'Фонари'),
    ],
    missingIndex: 2,
    options: [
      PartItem('🛡️', 'Перила'),
      PartItem('🧦', 'Носки'),
      PartItem('🍰', 'Торт'),
    ],
    correctIndex: 0,
    explanation: 'Мост держится на опорах 🪨, по нему идут по настилу 🪵, '
        'а перила 🛡️ защищают, чтобы не упасть. Носки и торт мосту не нужны.',
  ),
  const PartsLevel(
    title: 'Библиотека',
    wholeEmoji: '🏛️',
    parts: [
      PartItem('📚', 'Книги'),
      PartItem('🪑', 'Столы'),
      PartItem('👩‍💼', 'Библиотекарь'),
      PartItem('💻', 'Компьютер'),
    ],
    missingIndex: 1,
    options: [
      PartItem('🪑', 'Столы'),
      PartItem('🍕', 'Пицца'),
      PartItem('🛵', 'Скутер'),
    ],
    correctIndex: 0,
    explanation: 'В библиотеке хранят книги 📚, читают за столами 🪑, '
        'а библиотекарь 👩‍💼 выдаёт книги. Пиццу и скутер там не найдёшь.',
  ),
  const PartsLevel(
    title: 'Телевизор',
    wholeEmoji: '📺',
    parts: [
      PartItem('🔌', 'Питание'),
      PartItem('🔊', 'Динамик'),
      PartItem('🔲', 'Экран'),
      PartItem('📡', 'Антенна'),
    ],
    missingIndex: 0,
    options: [
      PartItem('🔌', 'Питание'),
      PartItem('🎈', 'Шарик'),
      PartItem('🥕', 'Морковь'),
    ],
    correctIndex: 0,
    explanation: 'Чтобы телевизор включился, нужна электроэнергия 🔌. '
        'На экране 🔲 идут картинки, динамик 🔊 подаёт звук, антенна 📡 ловит каналы.',
  ),
  const PartsLevel(
    title: 'Вулкан',
    wholeEmoji: '🌋',
    parts: [
      PartItem('🔥', 'Лава'),
      PartItem('💨', 'Пепел'),
      PartItem('🏔️', 'Кратер'),
      PartItem('🪨', 'Камни'),
    ],
    missingIndex: 0,
    options: [
      PartItem('🔥', 'Лава'),
      PartItem('🍦', 'Мороженое'),
      PartItem('🛷', 'Санки'),
    ],
    correctIndex: 0,
    explanation: 'Из кратера 🏔️ вылетает пепел 💨 и вытекает раскалённая лава 🔥, '
        'а из остывшей лавы получаются камни 🪨. Мороженое в вулкане растает!',
  ),
  const PartsLevel(
    title: 'Огород',
    wholeEmoji: '🥕',
    parts: [
      PartItem('☀️', 'Солнце'),
      PartItem('💧', 'Вода'),
      PartItem('🪱', 'Червячки'),
      PartItem('🧑‍🌾', 'Огородник'),
    ],
    missingIndex: 2,
    options: [
      PartItem('🪱', 'Червячки'),
      PartItem('📖', 'Книга'),
      PartItem('🎸', 'Гитара'),
    ],
    correctIndex: 0,
    explanation: 'Морковке нужно солнце ☀️, вода 💧, забота огородника 🧑‍🌾 '
        'и червячки 🪱: они рыхлят землю, чтобы корням было легче расти.',
  ),
  const PartsLevel(
    title: 'Пианино',
    wholeEmoji: '🎹',
    parts: [
      PartItem('⚪', 'Клавиши'),
      PartItem('🧵', 'Струны'),
      PartItem('🔨', 'Молоточки'),
      PartItem('🪵', 'Корпус'),
    ],
    missingIndex: 1,
    options: [
      PartItem('🧵', 'Струны'),
      PartItem('🚪', 'Дверь'),
      PartItem('🧁', 'Торт'),
    ],
    correctIndex: 0,
    explanation: 'Когда нажимаешь клавиши ⚪, молоточки 🔨 ударяют по струнам 🧵, '
        'и звук разносится внутри корпуса 🪵. Дверь и торт тут ни при чём.',
  ),
  const PartsLevel(
    title: 'Космонавт',
    wholeEmoji: '🧑‍🚀',
    parts: [
      PartItem('🦺', 'Скафандр'),
      PartItem('🥽', 'Шлем'),
      PartItem('📡', 'Радио'),
      PartItem('🎒', 'Воздух и вода'),
    ],
    missingIndex: 0,
    options: [
      PartItem('🦺', 'Скафандр'),
      PartItem('🛴', 'Самокат'),
      PartItem('🍪', 'Печенье'),
    ],
    correctIndex: 0,
    explanation: 'В космосе холодно и нет воздуха, поэтому космонавту нужен '
        'скафандр 🦺. Шлем 🥽 защищает голову, радио 📡 связывает с Землёй, '
        'а в рюкзачке 🎒 воздух и вода.',
  ),
  const PartsLevel(
    title: 'Пожарная команда',
    wholeEmoji: '🚒',
    parts: [
      PartItem('🚒', 'Пожарная машина'),
      PartItem('🚿', 'Струя воды'),
      PartItem('🧯', 'Огнетушитель'),
      PartItem('🧑‍🚒', 'Пожарный'),
    ],
    missingIndex: 2,
    options: [
      PartItem('🧯', 'Огнетушитель'),
      PartItem('🎂', 'Торт'),
      PartItem('🛼', 'Ролики'),
    ],
    correctIndex: 0,
    explanation: 'Пожарные тушат огонь водой: струёй из шланга 🚿 на машине 🚒 '
        'и огнетушителем 🧯. Торт и ролики на пожаре не помогут.',
  ),
  const PartsLevel(
    title: 'Аэропорт',
    wholeEmoji: '✈️',
    parts: [
      PartItem('🛫', 'Самолёты'),
      PartItem('🛣️', 'Взлётная полоса'),
      PartItem('🗼', 'Диспетчерская'),
      PartItem('🎫', 'Стойка регистрации'),
    ],
    missingIndex: 1,
    options: [
      PartItem('🛣️', 'Взлётная полоса'),
      PartItem('🥗', 'Салат'),
      PartItem('🚲', 'Велосипед'),
    ],
    correctIndex: 0,
    explanation: 'Самолёты ✈️ взлетают и садятся на взлётную полосу 🛣️. '
        'Диспетчерская 🗼 следит за небом, а на стойке 🎫 выдают билеты. '
        'Салат и велосипед в аэропорте не летают.',
  ),
  const PartsLevel(
    title: 'Школа',
    wholeEmoji: '🏫',
    parts: [
      PartItem('👩‍🏫', 'Учитель'),
      PartItem('📚', 'Учебники'),
      PartItem('🧒', 'Ученики'),
      PartItem('🔔', 'Звонок'),
    ],
    missingIndex: 3,
    options: [
      PartItem('🔔', 'Звонок'),
      PartItem('🎪', 'Шатёр'),
      PartItem('🛸', 'Тарелка'),
    ],
    correctIndex: 0,
    explanation: 'В школе учитель 👩‍🏫 ведёт уроки, ученики 🧒 слушают и '
        'пишут в учебниках 📚, а звонок 🔔 сообщает, что урок окончен. '
        'Шатёр и тарелка в школу не прилетали.',
  ),
];

/// Уровни игры (открыты для автотестов).
List<PartsLevel> get partsLevels => _partsLevels;

/// Игра «Части и целое»: какая часть системы пропала.
class PartsGame extends StatefulWidget {
  const PartsGame({
    super.key,
    required this.levelIndex,
    required this.onFinished,
  });

  final int levelIndex;
  final void Function(int stars) onFinished;

  @override
  State<PartsGame> createState() => _PartsGameState();
}

class _PartsGameState extends State<PartsGame> {
  late PartsLevel _level;
  int _mistakes = 0;
  int? _wrongIndex;
  bool _won = false;
  String _message = 'Чего не хватает этой системе?';

  static const GameInfo _game = GameInfo(
    id: 'parts',
    title: 'Части и целое',
    subtitle: '',
    emoji: '🧩',
    levelCount: 30,
  );

  @override
  void initState() {
    super.initState();
    _level = _partsLevels[widget.levelIndex % _partsLevels.length];
  }

  void _restart() {
    setState(() {
      _mistakes = 0;
      _wrongIndex = null;
      _won = false;
      _message = 'Чего не хватает этой системе?';
    });
  }

  void _choose(int index) {
    if (_won) return;
    if (index == _level.correctIndex) {
      final stars = _mistakes == 0 ? 3 : (_mistakes == 1 ? 2 : 1);
      setState(() {
        _won = true;
        _message = _level.explanation;
      });
      widget.onFinished(stars);
    } else {
      setState(() {
        _mistakes++;
        _wrongIndex = index;
        _message = 'Хм, эта часть тут не подходит. Попробуй ещё 👀';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: gameAppBar(_game, widget.levelIndex),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: HintBar(text: _message, color: AppTheme.purple),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _systemHeader(),
                        const SizedBox(height: 16),
                        _partsRow(),
                        const SizedBox(height: 24),
                        const Text(
                          'Добавь пропавшую часть:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          alignment: WrapAlignment.center,
                          children: [
                            for (int i = 0; i < _level.options.length; i++)
                              _optionCard(i),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_won)
              WinOverlay(
                game: _game,
                stars: _mistakes == 0 ? 3 : (_mistakes == 1 ? 2 : 1),
                maxLevelIndex: _partsLevels.length - 1 - widget.levelIndex,
                onRetry: _restart,
              ),
          ],
        ),
      ),
    );
  }

  Widget _systemHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.purple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Text(_level.wholeEmoji, style: const TextStyle(fontSize: 46)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Система:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  _level.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _partsRow() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (int i = 0; i < _level.parts.length; i++)
          _partTile(_level.parts[i], i == _level.missingIndex),
      ],
    );
  }

  Widget _partTile(PartItem part, bool missing) {
    return Container(
      width: 92,
      height: 104,
      decoration: BoxDecoration(
        color: missing ? AppTheme.yellow.withValues(alpha: 0.25) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: missing ? AppTheme.orange : Colors.black.withValues(alpha: 0.06),
          width: 3,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            missing ? '❓' : part.emoji,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              missing ? '?' : part.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionCard(int index) {
    final isWrong = _wrongIndex == index;
    final isRight = index == _level.correctIndex && _won;
    return GestureDetector(
      onTap: () => _choose(index),
      child: Container(
        width: 104,
        height: 112,
        decoration: BoxDecoration(
          color: isWrong
              ? Colors.red.shade50
              : (isRight ? Colors.green.shade50 : Colors.white),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isWrong
                ? Colors.red
                : (isRight
                    ? Colors.green
                    : AppTheme.purple.withValues(alpha: 0.5)),
            width: 3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _level.options[index].emoji,
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                _level.options[index].label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
