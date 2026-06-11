export type Screen =
  | "splash"
  | "onboarding"
  | "auth"
  | "home"
  | "scanner"
  | "product"
  | "search"
  | "history"
  | "profile";

export interface Product {
  id: string;
  name: string;
  brand: string;
  category: string;
  score: number;
  image: string;
  scannedAt?: string;
  nova: number;
  nutriscore: string;
  servingSize: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber: number;
  sugar: number;
  salt: number;
  ingredients: Ingredient[];
  additives: Additive[];
  concerns: string[];
  positives: string[];
  alternatives: AlternativeProduct[];
  source?: string;
}

export interface Ingredient {
  name: string;
  status: "safe" | "moderate" | "concern" | "unknown";
  description?: string;
  pct?: number;
}

export interface Additive {
  code: string;
  name: string;
  risk: "low" | "moderate" | "high";
  description: string;
}

export interface AlternativeProduct {
  id: string;
  name: string;
  brand: string;
  score: number;
  image: string;
}

export const MOCK_PRODUCTS: Product[] = [
  {
    id: "1",
    name: "Греческий йогурт 2%",
    brand: "Олайс",
    category: "Молочные продукты",
    score: 87,
    image: "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400&h=400&fit=crop&auto=format",
    scannedAt: "Сегодня, 09:42",
    nova: 1,
    nutriscore: "A",
    servingSize: "150 г",
    calories: 97,
    protein: 9,
    carbs: 6,
    fat: 3.5,
    fiber: 0,
    sugar: 5.8,
    salt: 0.1,
    ingredients: [
      { name: "Молоко нормализованное", status: "safe", pct: 99, description: "Натуральный молочный продукт высшего качества" },
      { name: "Живые молочнокислые культуры", status: "safe", description: "L. acidophilus, Bifidobacterium — клинически доказанные пробиотики" },
    ],
    additives: [],
    concerns: [],
    positives: ["9 г белка на порцию", "Живые пробиотические культуры", "Без сахара и консервантов", "Низкий гликемический индекс"],
    alternatives: [
      { id: "a1", name: "Биойогурт Натуральный", brand: "Активиа", score: 79, image: "https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=200&h=200&fit=crop&auto=format" },
      { id: "a2", name: "Творог Зернёный 5%", brand: "Простоквашино", score: 83, image: "https://images.unsplash.com/photo-1559561853-08451507197b?w=200&h=200&fit=crop&auto=format" },
    ],
    source: "Open Food Facts · USDA FoodData Central",
  },
  {
    id: "2",
    name: "Шоколадная паста",
    brand: "Нутелла",
    category: "Сладости",
    score: 28,
    image: "https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=400&h=400&fit=crop&auto=format",
    scannedAt: "Вчера, 19:15",
    nova: 4,
    nutriscore: "E",
    servingSize: "15 г",
    calories: 539,
    protein: 6.3,
    carbs: 57.5,
    fat: 31.6,
    fiber: 3.4,
    sugar: 56.3,
    salt: 0.1,
    ingredients: [
      { name: "Сахар", status: "concern", pct: 56, description: "Первый ингредиент. Продукт на 56% состоит из сахара" },
      { name: "Пальмовое масло", status: "concern", pct: 20, description: "Насыщенные жиры связаны с риском сердечно-сосудистых заболеваний" },
      { name: "Обезжиренное какао", status: "safe", pct: 7.4 },
      { name: "Лесные орехи", status: "safe", pct: 13, description: "Источник полезных мононенасыщенных жиров" },
      { name: "Обезжиренное сухое молоко", status: "safe" },
      { name: "Ваниль", status: "safe" },
      { name: "Лецитин сои (Е322)", status: "moderate", description: "Эмульгатор растительного происхождения" },
    ],
    additives: [
      { code: "Е322", name: "Лецитин соевый", risk: "low", description: "Натуральный эмульгатор из соевых бобов или подсолнечника. Generally recognized as safe." },
    ],
    concerns: [
      "56% сахара — в 2.5 раза выше рекомендаций ВОЗ",
      "Пальмовое масло — насыщенные жиры",
      "NOVA 4 — ультра-переработанный продукт",
      "Калорийность 539 ккал / 100 г",
    ],
    positives: ["Содержит лесные орехи", "Источник кальция"],
    alternatives: [
      { id: "b1", name: "Паста из фундука", brand: "Семь орехов", score: 62, image: "https://images.unsplash.com/photo-1559622214-f8a9850965bb?w=200&h=200&fit=crop&auto=format" },
      { id: "b2", name: "Тёмный шоколад 85%", brand: "Lindt Excellence", score: 73, image: "https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=200&h=200&fit=crop&auto=format" },
    ],
    source: "Open Food Facts · Cocoa Barometer 2022",
  },
  {
    id: "3",
    name: "Кефир 3.2%",
    brand: "Простоквашино",
    category: "Молочные продукты",
    score: 81,
    image: "https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400&h=400&fit=crop&auto=format",
    scannedAt: "Вчера, 11:03",
    nova: 1,
    nutriscore: "B",
    servingSize: "200 мл",
    calories: 59,
    protein: 2.8,
    carbs: 4.1,
    fat: 3.2,
    fiber: 0,
    sugar: 4.1,
    salt: 0.12,
    ingredients: [
      { name: "Молоко цельное", status: "safe", pct: 99 },
      { name: "Кефирная закваска", status: "safe", description: "Пробиотические культуры, улучшающие микробиом кишечника" },
    ],
    additives: [],
    concerns: [],
    positives: ["Натуральный состав без добавок", "Пробиотики и кальций", "Низкая калорийность"],
    alternatives: [],
    source: "Open Food Facts",
  },
  {
    id: "4",
    name: "Чипсы Original",
    brand: "Pringles",
    category: "Снеки",
    score: 18,
    image: "https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400&h=400&fit=crop&auto=format",
    scannedAt: "3 дня назад",
    nova: 4,
    nutriscore: "E",
    servingSize: "30 г",
    calories: 536,
    protein: 4.2,
    carbs: 55.4,
    fat: 32.7,
    fiber: 3.4,
    sugar: 1.7,
    salt: 1.2,
    ingredients: [
      { name: "Обезвоженный картофель 40%", status: "safe", pct: 40 },
      { name: "Растительные масла", status: "moderate", pct: 25 },
      { name: "Пшеничный крахмал", status: "safe", pct: 15 },
      { name: "Мальтодекстрин", status: "concern", description: "Гликемический индекс выше, чем у чистого сахара (ГИ 95–136)" },
      { name: "Эмульгатор Е471", status: "moderate" },
      { name: "Глутамат натрия Е621", status: "concern", description: "Усилитель вкуса, формирует привыкание к солёной пище" },
    ],
    additives: [
      { code: "Е471", name: "Моно- и диглицериды жирных кислот", risk: "moderate", description: "Эмульгатор. Может содержать следы транс-жиров" },
      { code: "Е621", name: "Глутамат натрия", risk: "moderate", description: "Усилитель вкуса. Формирует зависимость от вкуса umami у детей" },
    ],
    concerns: [
      "NOVA 4 — максимальная степень обработки",
      "1.2 г соли — 60% суточной нормы на 30 г",
      "Мальтодекстрин с ГИ >100 повышает сахар",
      "Глутамат натрия формирует пищевую зависимость",
    ],
    positives: [],
    alternatives: [
      { id: "c1", name: "Рисовые хлебцы", brand: "Finn Crisp", score: 68, image: "https://images.unsplash.com/photo-1621447504864-d8686e12698c?w=200&h=200&fit=crop&auto=format" },
      { id: "c2", name: "Запечённые чипсы", brand: "Lay's Oven", score: 41, image: "https://images.unsplash.com/photo-1559622214-f8a9850965bb?w=200&h=200&fit=crop&auto=format" },
    ],
    source: "Open Food Facts · WHO/FAO JECFA",
  },
];

export const CATEGORIES = [
  { id: "all", label: "Все", emoji: "🌿" },
  { id: "dairy", label: "Молочные", emoji: "🥛" },
  { id: "snacks", label: "Снеки", emoji: "🍟" },
  { id: "sweets", label: "Сладости", emoji: "🍫" },
  { id: "drinks", label: "Напитки", emoji: "🧃" },
  { id: "cereal", label: "Злаки", emoji: "🌾" },
  { id: "meat", label: "Мясное", emoji: "🥩" },
  { id: "produce", label: "Овощи", emoji: "🥦" },
];

export function getScoreColor(score: number): string {
  if (score >= 75) return "var(--score-excellent)";
  if (score >= 55) return "var(--score-good)";
  if (score >= 35) return "var(--score-moderate)";
  return "var(--score-poor)";
}

export function getScoreBg(score: number): string {
  if (score >= 75) return "var(--score-bg-excellent)";
  if (score >= 55) return "var(--score-bg-good)";
  if (score >= 35) return "var(--score-bg-moderate)";
  return "var(--score-bg-poor)";
}

export function getScoreLabel(score: number): string {
  if (score >= 75) return "Отлично";
  if (score >= 55) return "Хорошо";
  if (score >= 35) return "Умеренно";
  return "Плохо";
}

export function getNovaLabel(nova: number): string {
  return ["", "Необработанный", "Кулинарный", "Обработанный", "Ультра-обработанный"][nova] ?? "";
}

export function getNovaColor(nova: number): string {
  return ["", "#1E6B28", "#4A9152", "#B87D28", "#C03B32"][nova] ?? "#6B7866";
}
