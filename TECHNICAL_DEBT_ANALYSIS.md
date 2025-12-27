# 🔴 Аналіз технічного боргу: international-cunnibal

## Резюме проблем

**Статус CI:** ❌ Червоний (тести не можуть пройти)  
**Кореневі причини:** 2 критичні проблеми зі структурою проєкту

---

## 🚨 КРИТИЧНІ ПРОБЛЕМИ (Блокуючі)

### Проблема 1: Неправильні шляхи імпортів для `cv_engine.dart`

**Файли з проблемою:**
- `test/cv_engine_test.dart`
- `test/demo_cv_engine_test.dart`

**Поточний імпорт (неправильний):**
```dart
import 'package:international_cunnibal/services/cv_engine.dart';
```

**Реальне розташування файлу:**
```
lib/services/ui/cv_engine.dart
```

**Рішення:** Створити barrel-файл (реекспорт) або оновити імпорти

---

### Проблема 2: Неправильні шляхи імпортів для `github_export_service.dart`

**Файл з проблемою:**
- `test/github_export_service_test.dart`

**Поточний імпорт (неправильний):**
```dart
import 'package:international_cunnibal/services/github_export_service.dart';
```

**Реальне розташування файлу:**
```
lib/services/ui/github_export_service.dart
```

**Рішення:** Створити barrel-файл (реекспорт) або оновити імпорти

---

## 📁 Аналіз структури

### Поточна структура lib/services/:
```
lib/services/
├── endurance_engine.dart
├── endurance_game_logic_service.dart
├── endurance_session_service.dart
├── game_logic_service.dart
├── neural_engine.dart
├── symbol_dictation_service.dart
└── ui/
    ├── bio_tracking_service.dart
    ├── cv_engine.dart          ← Тести шукають в services/
    └── github_export_service.dart  ← Тести шукають в services/
```

### Імпорти в тестах:
| Тест | Імпорт | Статус |
|------|--------|--------|
| cv_engine_test.dart | services/cv_engine.dart | ❌ MISSING |
| demo_cv_engine_test.dart | services/cv_engine.dart | ❌ MISSING |
| github_export_service_test.dart | services/github_export_service.dart | ❌ MISSING |
| endurance_metrics_test.dart | core/endurance_metrics.dart | ✅ OK |
| game_logic_service_test.dart | services/game_logic_service.dart | ✅ OK |
| landmark_privacy_test.dart | utils/landmark_privacy.dart | ✅ OK |
| models_test.dart | models/*.dart | ✅ OK |
| motion_metrics_test.dart | core/motion_metrics.dart | ✅ OK |
| neural_engine_test.dart | services/neural_engine.dart | ✅ OK |
| symbol_dictation_test.dart | services/symbol_dictation_service.dart | ✅ OK |
| tracking_screen_logic_test.dart | screens/tracking_screen.dart | ✅ OK |

---

## ✅ ПЛАН ВИПРАВЛЕННЯ

### Варіант A: Barrel-файли (Рекомендовано - мінімальні зміни)

Створити файли реекспорту в `lib/services/`:

**Файл: `lib/services/cv_engine.dart`**
```dart
export 'ui/cv_engine.dart';
```

**Файл: `lib/services/github_export_service.dart`**
```dart
export 'ui/github_export_service.dart';
```

**Переваги:**
- Жодних змін в тестах
- Зберігає поточну структуру
- Backward-compatible

---

### Варіант B: Оновити імпорти в тестах

Змінити імпорти:

```dart
// Було:
import 'package:international_cunnibal/services/cv_engine.dart';
// Стане:
import 'package:international_cunnibal/services/ui/cv_engine.dart';

// Було:
import 'package:international_cunnibal/services/github_export_service.dart';
// Стане:
import 'package:international_cunnibal/services/ui/github_export_service.dart';
```

**Переваги:**
- Точніше відображає структуру
- Немає додаткових файлів

---

## 📋 Чеклист для виправлення

- [ ] Створити `lib/services/cv_engine.dart` (barrel)
- [ ] Створити `lib/services/github_export_service.dart` (barrel)
- [ ] Запустити `flutter test` локально
- [ ] Перевірити CI checks
- [ ] Оновити документацію (якщо потрібно)

---

## 🔍 Додаткові спостереження

### CI Pipeline перевірки:
1. `flutter format` - OK (формат коду)
2. `flutter analyze` - Потребує перевірки
3. `flutter test` - ❌ Падає через імпорти
4. `check_coverage.py` - Потребує 80%+ покриття
5. `check_architecture_boundaries.py` - Перевіряє залежності
6. `check_privacy_guards.py` - Перевіряє LandmarkPrivacyFilter
7. `check_doc_updates.py` - Перевіряє документацію

### Потенційні ризики:
- `check_architecture_boundaries.py` забороняє UI імпорти в domain layer
- Barrel-файли можуть порушити це правило якщо services/ вважається domain

---

## 🎯 Рекомендації

1. **Термінова дія:** Створити barrel-файли (Варіант A)
2. **Довгострокова:** Розглянути реструктуризацію services/ для кращого separation of concerns
3. **Документація:** Додати README в services/ui/ з поясненням призначення

---

*Звіт згенеровано: 2025-12-27*
