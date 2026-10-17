/// Модель и уровни мини-игры «Собери робота из модулей».
///
/// Ребёнок собирает робота, раскладывая модули по слотам корпуса, а потом
/// проверяет, сможет ли робот выполнить задание. Учит системному мышлению:
/// «какие части нужны, чтобы система заработала?»
library;

/// Тип модуля робота. Каждый слот корпуса принимает свой тип.
enum RobotKind {
  /// Контроллер — «мозг» робота, он всё решает.
  controller,

  /// Батарея — источник энергии.
  battery,

  /// Мотор-колесо — движение.
  wheel,

  /// Датчик расстояния — «видит», насколько близко препятствие.
  distanceSensor,

  /// Датчик света — «чувствует», светло или темно.
  lightSensor,

  /// Манипулятор — «рука», чтобы что-то взять.
  arm,

  /// Динамик — голос робота, чтобы что-то сказать.
  speaker,
}

/// Эмодзи и подпись для каждого модуля.
extension RobotKindView on RobotKind {
  String get emoji => switch (this) {
        RobotKind.controller => '🧠',
        RobotKind.battery => '🔋',
        RobotKind.wheel => '🛞',
        RobotKind.distanceSensor => '📏',
        RobotKind.lightSensor => '🔆',
        RobotKind.arm => '🦾',
        RobotKind.speaker => '🔊',
      };

  String get label => switch (this) {
        RobotKind.controller => 'контроллер',
        RobotKind.battery => 'батарея',
        RobotKind.wheel => 'мотор-колесо',
        RobotKind.distanceSensor => 'датчик расстояния',
        RobotKind.lightSensor => 'датчик света',
        RobotKind.arm => 'манипулятор',
        RobotKind.speaker => 'динамик',
      };
}

/// Слот корпуса: место для одного модуля определённого типа.
class RobotSlot {
  const RobotSlot({
    required this.label,
    required this.accepts,
    required this.why,
  });

  /// Название слота: «мозг», «питание», «движение», «чувства» и т.п.
  final String label;

  /// Тип модуля, который тут должен стоять.
  final RobotKind accepts;

  /// Короткое пояснение для подсказки, зачем этот модуль нужен.
  final String why;
}

/// Один уровень игры: задание, набор модулей и слоты корпуса.
class RobotLevel {
  const RobotLevel({
    required this.task,
    required this.taskEmoji,
    required this.pool,
    required this.slots,
    required this.hint,
    required this.explanation,
  });

  /// Что робот должен сделать (текстом).
  final String task;

  /// Эмодзи задания (цель, к которой «едет» робот при проверке).
  final String taskEmoji;

  /// Доступные модули (среди них могут быть лишние — ловушки).
  final List<RobotKind> pool;

  /// Слоты корпуса: у каждого свой допустимый тип модуля.
  final List<RobotSlot> slots;

  /// Мягкая подсказка перед началом.
  final String hint;

  /// Объяснение после победы.
  final String explanation;

  /// Верна ли сборка: все слоты заняты и в каждом — нужный тип модуля.
  bool isSolved(Map<int, RobotKind> placed) {
    if (placed.length != slots.length) return false;
    for (var i = 0; i < slots.length; i++) {
      if (placed[i] != slots[i].accepts) return false;
    }
    return true;
  }
}

final List<RobotLevel> _robotLevels = [
  // 1. Два слота: мозг и питание. Робот просто включается.
  const RobotLevel(
    task: 'Проснуться и зажечь лампочку',
    taskEmoji: '💡',
    pool: [RobotKind.controller, RobotKind.battery],
    slots: [
      RobotSlot(
        label: 'мозг',
        accepts: RobotKind.controller,
        why: 'контроллер решает, что роботу делать.',
      ),
      RobotSlot(
        label: 'питание',
        accepts: RobotKind.battery,
        why: 'батарея даёт роботу энергию.',
      ),
    ],
    hint: 'Сначала поставь «мозг», который всё решает, а потом — энергию.',
    explanation: 'Контроллер 🧠 решает, а батарея 🔋 даёт энергию. Вместе они '
        'включают робота — и лампочка загорается!',
  ),
  // 2. Три слота: чтобы поехать, нужно движение.
  const RobotLevel(
    task: 'Поехать вперёд к флажку',
    taskEmoji: '🚩',
    pool: [RobotKind.controller, RobotKind.battery, RobotKind.wheel],
    slots: [
      RobotSlot(
        label: 'мозг',
        accepts: RobotKind.controller,
        why: 'контроллер решает, куда ехать.',
      ),
      RobotSlot(
        label: 'питание',
        accepts: RobotKind.battery,
        why: 'без батареи робот не поедет.',
      ),
      RobotSlot(
        label: 'движение',
        accepts: RobotKind.wheel,
        why: 'мотор-колесо двигает робота вперёд.',
      ),
    ],
    hint: 'Чтобы робот поехал, кроме мозга и энергии нужно движение.',
    explanation: 'Контроллер 🧠 командует, батарея 🔋 даёт силу, а '
        'мотор-колесо 🛞 везёт робота к флажку 🚩.',
  ),
  // 3. Три слота: робот здоровается — нужен голос.
  const RobotLevel(
    task: 'Поздороваться: «Привет!»',
    taskEmoji: '💬',
    pool: [RobotKind.controller, RobotKind.battery, RobotKind.speaker],
    slots: [
      RobotSlot(
        label: 'мозг',
        accepts: RobotKind.controller,
        why: 'контроллер решает, что сказать.',
      ),
      RobotSlot(
        label: 'питание',
        accepts: RobotKind.battery,
        why: 'без батареи робот не заговорит.',
      ),
      RobotSlot(
        label: 'голос',
        accepts: RobotKind.speaker,
        why: 'динамик произносит слова робота.',
      ),
    ],
    hint: 'Робот хочет говорить. Какой модуль умеет издавать звук?',
    explanation: 'Контроллер 🧠 придумывает слова, батарея 🔋 даёт энергию, '
        'а динамик 🔊 их произносит. Робот говорит: «Привет!»',
  ),
  // 4. Четыре слота: появляется датчик расстояния — объехать стену.
  const RobotLevel(
    task: 'Объехать стену',
    taskEmoji: '🧱',
    pool: [
      RobotKind.controller,
      RobotKind.battery,
      RobotKind.wheel,
      RobotKind.distanceSensor,
    ],
    slots: [
      RobotSlot(
        label: 'мозг',
        accepts: RobotKind.controller,
        why: 'контроллер решает, куда свернуть.',
      ),
      RobotSlot(
        label: 'питание',
        accepts: RobotKind.battery,
        why: 'без батареи робот не поедет.',
      ),
      RobotSlot(
        label: 'движение',
        accepts: RobotKind.wheel,
        why: 'мотор-колесо везёт робота.',
      ),
      RobotSlot(
        label: 'чувства',
        accepts: RobotKind.distanceSensor,
        why: 'датчик расстояния замечает препятствие.',
      ),
    ],
    hint: 'Чтобы вовремя заметить стену, роботу нужны «чувства» — датчик.',
    explanation: 'Датчик расстояния 📏 замечает стену 🧱 заранее, контроллер 🧠 '
        'решает повернуть, а мотор-колесо 🛞 объезжает препятствие.',
  ),
  // 5. Четыре слота + ловушка: датчик света не поможет увидеть стену.
  const RobotLevel(
    task: 'Доехать до флажка и не врезаться',
    taskEmoji: '🚩',
    pool: [
      RobotKind.controller,
      RobotKind.battery,
      RobotKind.wheel,
      RobotKind.distanceSensor,
      RobotKind.lightSensor,
    ],
    slots: [
      RobotSlot(
        label: 'мозг',
        accepts: RobotKind.controller,
        why: 'контроллер управляет роботом.',
      ),
      RobotSlot(
        label: 'питание',
        accepts: RobotKind.battery,
        why: 'батарея даёт энергию.',
      ),
      RobotSlot(
        label: 'движение',
        accepts: RobotKind.wheel,
        why: 'мотор-колесо двигает робота.',
      ),
      RobotSlot(
        label: 'чувства',
        accepts: RobotKind.distanceSensor,
        why: 'датчик расстояния чувствует преграду.',
      ),
    ],
    hint: 'Из двух датчиков для объезда стены нужен тот, что измеряет '
        'расстояние.',
    explanation: 'Стену чувствует датчик расстояния 📏, а не датчик света 🔆. '
        'Он вовремя подсказывает путь, и робот доезжает до флажка 🚩.',
  ),
  // 6. Три слота: темнота — нужен датчик света.
  const RobotLevel(
    task: 'В темноте понять, что пора включить лампу',
    taskEmoji: '🌙',
    pool: [
      RobotKind.controller,
      RobotKind.battery,
      RobotKind.lightSensor,
      RobotKind.distanceSensor,
    ],
    slots: [
      RobotSlot(
        label: 'мозг',
        accepts: RobotKind.controller,
        why: 'контроллер решает включить лампу.',
      ),
      RobotSlot(
        label: 'питание',
        accepts: RobotKind.battery,
        why: 'батарея питает лампу.',
      ),
      RobotSlot(
        label: 'чувства',
        accepts: RobotKind.lightSensor,
        why: 'датчик света замечает темноту.',
      ),
    ],
    hint: 'Чтобы понять, что стало темно, нужен датчик СВЕТА, а не расстояния.',
    explanation: 'Датчик света 🔆 замечает, что стало темно 🌙, контроллер 🧠 '
        'включает лампу, а батарея 🔋 даёт энергию.',
  ),
  // 7. Четыре слота: появился манипулятор — взять предмет.
  const RobotLevel(
    task: 'Взять кубик и положить его в коробку',
    taskEmoji: '📦',
    pool: [
      RobotKind.controller,
      RobotKind.battery,
      RobotKind.wheel,
      RobotKind.arm,
    ],
    slots: [
      RobotSlot(
        label: 'мозг',
        accepts: RobotKind.controller,
        why: 'контроллер решает, когда схватить.',
      ),
      RobotSlot(
        label: 'питание',
        accepts: RobotKind.battery,
        why: 'без батареи робот не сдвинется.',
      ),
      RobotSlot(
        label: 'движение',
        accepts: RobotKind.wheel,
        why: 'мотор-колесо подвозит робота к кубику.',
      ),
      RobotSlot(
        label: 'действие',
        accepts: RobotKind.arm,
        why: 'манипулятор берёт предмет.',
      ),
    ],
    hint: 'Чтобы что-то взять, роботу нужна «рука» — манипулятор.',
    explanation: 'Робот подъезжает на мотор-колёсах 🛞 к кубику, а манипулятор '
        '🦾 берёт его и кладёт в коробку 📦.',
  ),
  // 8. Пять слотов: движение + действие + чувства.
  const RobotLevel(
    task: 'Принести яблоко в корзину',
    taskEmoji: '🍎',
    pool: [
      RobotKind.controller,
      RobotKind.battery,
      RobotKind.wheel,
      RobotKind.arm,
      RobotKind.distanceSensor,
    ],
    slots: [
      RobotSlot(
        label: 'мозг',
        accepts: RobotKind.controller,
        why: 'контроллер всё планирует.',
      ),
      RobotSlot(
        label: 'питание',
        accepts: RobotKind.battery,
        why: 'батарея даёт энергию.',
      ),
      RobotSlot(
        label: 'движение',
        accepts: RobotKind.wheel,
        why: 'мотор-колесо везёт робота.',
      ),
      RobotSlot(
        label: 'чувства',
        accepts: RobotKind.distanceSensor,
        why: 'датчик расстояния объезжает препятствия.',
      ),
      RobotSlot(
        label: 'действие',
        accepts: RobotKind.arm,
        why: 'манипулятор берёт яблоко.',
      ),
    ],
    hint: 'Робот должен доехать, объехать препятствия и взять яблоко.',
    explanation: 'Датчик расстояния 📏 помогает объезжать мебель, '
        'мотор-колесо 🛞 везёт робота, а манипулятор 🦾 кладёт яблоко 🍎 '
        'в корзину.',
  ),
  // 9. Четыре слота: датчик + голос (без движения — робот стоит и сигналит).
  const RobotLevel(
    task: 'Заметить стену и посигналить',
    taskEmoji: '🧱',
    pool: [
      RobotKind.controller,
      RobotKind.battery,
      RobotKind.distanceSensor,
      RobotKind.speaker,
      RobotKind.lightSensor,
    ],
    slots: [
      RobotSlot(
        label: 'мозг',
        accepts: RobotKind.controller,
        why: 'контроллер решает сигналить.',
      ),
      RobotSlot(
        label: 'питание',
        accepts: RobotKind.battery,
        why: 'батарея даёт энергию.',
      ),
      RobotSlot(
        label: 'чувства',
        accepts: RobotKind.distanceSensor,
        why: 'датчик расстояния замечает стену.',
      ),
      RobotSlot(
        label: 'голос',
        accepts: RobotKind.speaker,
        why: 'динамик издаёт сигнал.',
      ),
    ],
    hint: 'Стену «чувствует» датчик расстояния, а сигналит динамик.',
    explanation: 'Датчик расстояния 📏 замечает стену 🧱, контроллер 🧠 велит '
        'подать сигнал, и динамик 🔊 пищит: «Бип-бип!»',
  ),
  // 10. Пять слотов: проехать, объехать и сообщить.
  const RobotLevel(
    task: 'Объехать препятствие и сообщить об этом',
    taskEmoji: '🧱',
    pool: [
      RobotKind.controller,
      RobotKind.battery,
      RobotKind.wheel,
      RobotKind.distanceSensor,
      RobotKind.speaker,
    ],
    slots: [
      RobotSlot(
        label: 'мозг',
        accepts: RobotKind.controller,
        why: 'контроллер принимает решения.',
      ),
      RobotSlot(
        label: 'питание',
        accepts: RobotKind.battery,
        why: 'батарея даёт энергию.',
      ),
      RobotSlot(
        label: 'движение',
        accepts: RobotKind.wheel,
        why: 'мотор-колесо везёт робота.',
      ),
      RobotSlot(
        label: 'чувства',
        accepts: RobotKind.distanceSensor,
        why: 'датчик расстояния видит преграду.',
      ),
      RobotSlot(
        label: 'голос',
        accepts: RobotKind.speaker,
        why: 'динамик сообщает о манёвре.',
      ),
    ],
    hint: 'Тут нужно и объехать (движение + датчик), и сказать (голос).',
    explanation: 'Датчик расстояния 📏 находит препятствие, мотор-колесо 🛞 '
        'объезжает его, а динамик 🔊 сообщает: «Препятствие обойдено!»',
  ),
  // 11. Четыре слота + ловушка: ночью нужен датчик света.
  const RobotLevel(
    task: 'Ночью увидеть свет маяка и подъехать',
    taskEmoji: '🔦',
    pool: [
      RobotKind.controller,
      RobotKind.battery,
      RobotKind.wheel,
      RobotKind.lightSensor,
      RobotKind.distanceSensor,
    ],
    slots: [
      RobotSlot(
        label: 'мозг',
        accepts: RobotKind.controller,
        why: 'контроллер ведёт робота на свет.',
      ),
      RobotSlot(
        label: 'питание',
        accepts: RobotKind.battery,
        why: 'батарея даёт энергию.',
      ),
      RobotSlot(
        label: 'движение',
        accepts: RobotKind.wheel,
        why: 'мотор-колесо везёт робота.',
      ),
      RobotSlot(
        label: 'чувства',
        accepts: RobotKind.lightSensor,
        why: 'датчик света ищет огонёк маяка.',
      ),
    ],
    hint: 'Идти на огонёк помогает датчик СВЕТА, а не расстояния.',
    explanation: 'Датчик света 🔆 замечает маяк 🔦 в темноте, мотор-колесо 🛞 '
        'везёт робота, и он подъезжает к свету.',
  ),
  // 12. Четыре слота + ловушка: взять и сказать (без движения).
  const RobotLevel(
    task: 'Взять предмет и сказать: «Взял!»',
    taskEmoji: '✋',
    pool: [
      RobotKind.controller,
      RobotKind.battery,
      RobotKind.arm,
      RobotKind.speaker,
      RobotKind.distanceSensor,
    ],
    slots: [
      RobotSlot(
        label: 'мозг',
        accepts: RobotKind.controller,
        why: 'контроллер решает, что делать.',
      ),
      RobotSlot(
        label: 'питание',
        accepts: RobotKind.battery,
        why: 'батарея даёт энергию.',
      ),
      RobotSlot(
        label: 'действие',
        accepts: RobotKind.arm,
        why: 'манипулятор берёт предмет.',
      ),
      RobotSlot(
        label: 'голос',
        accepts: RobotKind.speaker,
        why: 'динамик сообщает о результате.',
      ),
    ],
    hint: 'Робот стоит на месте: нужно «взять» и «сказать», без движения.',
    explanation: 'Манипулятор 🦾 хватает предмет ✋, а динамик 🔊 говорит: '
        '«Взял!». Датчик расстояния тут не пригодится.',
  ),
  // 13. Пять слотов + ловушка: движение, свет, рука.
  const RobotLevel(
    task: 'Подъехать к свету и помахать рукой',
    taskEmoji: '🔆',
    pool: [
      RobotKind.controller,
      RobotKind.battery,
      RobotKind.wheel,
      RobotKind.lightSensor,
      RobotKind.arm,
      RobotKind.distanceSensor,
    ],
    slots: [
      RobotSlot(
        label: 'мозг',
        accepts: RobotKind.controller,
        why: 'контроллер управляет.',
      ),
      RobotSlot(
        label: 'питание',
        accepts: RobotKind.battery,
        why: 'батарея даёт энергию.',
      ),
      RobotSlot(
        label: 'движение',
        accepts: RobotKind.wheel,
        why: 'мотор-колесо везёт робота.',
      ),
      RobotSlot(
        label: 'чувства',
        accepts: RobotKind.lightSensor,
        why: 'датчик света находит источник света.',
      ),
      RobotSlot(
        label: 'действие',
        accepts: RobotKind.arm,
        why: 'манипулятор машет рукой.',
      ),
    ],
    hint: 'Свет ищет датчик света, а машет рукой манипулятор.',
    explanation: 'Датчик света 🔆 ведёт робота к источнику, мотор-колесо 🛞 '
        'подвозит его, и манипулятор 🦾 машет рукой.',
  ),
  // 14. Пять слотов + две ловушки.
  const RobotLevel(
    task: 'Доехать, объехать стену и взять кубик',
    taskEmoji: '🧱',
    pool: [
      RobotKind.controller,
      RobotKind.battery,
      RobotKind.wheel,
      RobotKind.distanceSensor,
      RobotKind.arm,
      RobotKind.lightSensor,
      RobotKind.speaker,
    ],
    slots: [
      RobotSlot(
        label: 'мозг',
        accepts: RobotKind.controller,
        why: 'контроллер планирует путь.',
      ),
      RobotSlot(
        label: 'питание',
        accepts: RobotKind.battery,
        why: 'батарея даёт энергию.',
      ),
      RobotSlot(
        label: 'движение',
        accepts: RobotKind.wheel,
        why: 'мотор-колесо везёт робота.',
      ),
      RobotSlot(
        label: 'чувства',
        accepts: RobotKind.distanceSensor,
        why: 'датчик расстояния видит стену.',
      ),
      RobotSlot(
        label: 'действие',
        accepts: RobotKind.arm,
        why: 'манипулятор берёт кубик.',
      ),
    ],
    hint: 'Среди модулей есть лишние: для стены нужен датчик расстояния.',
    explanation: 'Датчик расстояния 📏 помогает объехать стену 🧱, мотор-колесо '
        '🛞 везёт робота, манипулятор 🦾 берёт кубик. Датчик света 🔆 и '
        'динамик 🔊 здесь лишние.',
  ),
  // 15. Финал: пять слотов и три ловушки.
  const RobotLevel(
    task: 'Найти маяк в темноте, доехать и сообщить, что нашёл',
    taskEmoji: '🌟',
    pool: [
      RobotKind.controller,
      RobotKind.battery,
      RobotKind.wheel,
      RobotKind.lightSensor,
      RobotKind.speaker,
      RobotKind.distanceSensor,
      RobotKind.arm,
    ],
    slots: [
      RobotSlot(
        label: 'мозг',
        accepts: RobotKind.controller,
        why: 'контроллер ведёт робота к цели.',
      ),
      RobotSlot(
        label: 'питание',
        accepts: RobotKind.battery,
        why: 'батарея даёт энергию.',
      ),
      RobotSlot(
        label: 'движение',
        accepts: RobotKind.wheel,
        why: 'мотор-колесо везёт робота.',
      ),
      RobotSlot(
        label: 'чувства',
        accepts: RobotKind.lightSensor,
        why: 'датчик света ищет маяк в темноте.',
      ),
      RobotSlot(
        label: 'голос',
        accepts: RobotKind.speaker,
        why: 'динамик сообщает, что маяк найден.',
      ),
    ],
    hint: 'Маяк светится в темноте — значит, нужен датчик света. А сообщить '
        'поможет голос.',
    explanation: 'Датчик света 🔆 находит маяк 🌟 в темноте, мотор-колесо 🛞 '
        'везёт робота, а динамик 🔊 сообщает: «Маяк найден!». Датчик '
        'расстояния 📏 и манипулятор 🦾 на этом задании не нужны.',
  ),
];

/// Уровни игры (открыты для автотестов, проверяющих решаемость).
List<RobotLevel> get robotLevels => _robotLevels;
