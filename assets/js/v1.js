// Вариант 1 «Apple-стиль» - анимации прокрутки, перенесены из макета Claude Design как есть.
//
// Первый экран: текст занимает ~66% высоты окна, снизу видна треть телефона.
// За первые полэкрана прокрутки телефон чуть поднимается и увеличивается,
// по бокам разъезжаются ещё два экрана. На ширине < 760 px телефон меньше (42% ширины),
// чтобы все три помещались; боковые разведены в тех же пропорциях, что на компьютере.
//
// Высоту окна берём одну и меняем только при смене ширины (поворот телефона):
// в Safari на iPhone она меняется, когда прячется панель адреса, и страница бы дёргалась.
//
// Блок функций: телефоны выезжают сбоку не дальше чем на 360 px (или из-за края
// экрана, если до него ближе), без прозрачности, и встают на место, когда видны полностью.
// Если браузер умеет анимацию по прокрутке (Safari 26+, Chrome 115+), выезд ведёт сам
// браузер (v1.css, @supports animation-timeline) - без отставания от пальца на iPhone;
// здесь тогда только считаем расстояние выезда (--v1-dx). Иначе двигаем сами.
//
// При «Уменьшении движения» ничего не двигаем: остаются конечные положения из v1.css.
//
// Отдельно (ниже первым): метки-кнопки режимов таймера переключают скриншот в своём блоке.

// --- Переключение скриншота по меткам режимов ---
(function () {
  var reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // Картинка загружена (или не загрузилась - тогда тоже идём дальше).
  // decode() не используем: в некоторых браузерах он зависает, если окно не на виду.
  function loaded(img) {
    return new Promise(function (resolve) {
      if (img.complete) { resolve(); return; }
      img.addEventListener("load", resolve, { once: true });
      img.addEventListener("error", resolve, { once: true });
    });
  }

  document.querySelectorAll(".v1-row").forEach(function (row) {
    var buttons = row.querySelectorAll("[data-v1-mode]");
    var stack = row.querySelector(".v1-phone-stack");
    var img = stack && stack.querySelector("img");
    if (!buttons.length || !img) return;

    // Заранее подгружаем остальные экраны, чтобы при нажатии не было пустой паузы.
    window.addEventListener("load", function () {
      buttons.forEach(function (b) { new Image().src = b.dataset.v1Mode; });
    });

    var pending = 0; // номер последнего нажатия: недоигранный поворот отменяется
    var OUT = "transform 0.22s cubic-bezier(0.55, 0, 1, 0.45)";   // разгон к ребру
    var IN = "transform 0.32s cubic-bezier(0.2, 0.9, 0.3, 1.1)";  // торможение с лёгкой отдачей

    // Поворот вокруг вертикальной оси: телефон уходит ребром, на ребре меняется экран,
    // и телефон доворачивается обратно уже с новым экраном. Направление - по порядку меток.
    function turn(angle, transition) {
      img.style.transition = transition;
      img.style.transform = angle ? "rotateY(" + angle + "deg)" : "";
    }

    buttons.forEach(function (button, index) {
      button.addEventListener("click", function () {
        if (button.getAttribute("aria-pressed") === "true") return;
        var from = Array.prototype.findIndex.call(buttons, function (b) { return b.getAttribute("aria-pressed") === "true"; });
        buttons.forEach(function (b) { b.setAttribute("aria-pressed", b === button ? "true" : "false"); });

        var src = button.dataset.v1Mode;
        var alt = button.dataset.v1ModeAlt;
        var id = ++pending;
        if (reduce) { img.src = src; img.alt = alt; return; }

        var dir = index > from ? 1 : -1;
        var next = new Image();
        next.src = src;

        turn(90 * dir, OUT);
        var swapped = false;
        var swap = function () {
          if (swapped || id !== pending) return;
          swapped = true;
          loaded(next).then(function () {
            if (id !== pending) return;
            img.src = src;
            img.alt = alt;
            loaded(img).then(function () {
              if (id !== pending) return;
              turn(-90 * dir, "none");           // с другой стороны ребра
              img.getBoundingClientRect();       // чтобы браузер применил без анимации
              turn(0, IN);
            });
          });
        };
        img.addEventListener("transitionend", swap, { once: true });
        setTimeout(swap, 260); // запасной путь, если событие конца перехода не придёт
      });
    });
  });
})();

// --- Анимации прокрутки ---
(function () {
  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  var hero = document.querySelector("[data-v1-hero]");
  if (!hero) return;
  var copy = hero.querySelector(".v1-hero-copy");
  var phones = hero.querySelector(".v1-hero-phones");
  var main = hero.querySelector(".v1-hero-main");
  var sideL = hero.querySelector(".v1-side-l");
  var sideR = hero.querySelector(".v1-side-r");
  var slides = Array.prototype.slice.call(document.querySelectorAll("[data-v1-slide]"));

  function clamp(v) { return Math.max(0, Math.min(1, v)); }
  function easeOutCubic(p) { return 1 - Math.pow(1 - p, 3); }
  function easeOutQuad(p) { return 1 - (1 - p) * (1 - p); }

  var ticking = false;
  // Ширина видимой области без полосы прокрутки (на телефоне innerWidth бывает шире экрана).
  var vw = document.documentElement.clientWidth;
  var vh = window.innerHeight;
  var touch = window.matchMedia("(pointer: coarse)").matches; // телефон / планшет

  var cssSlides = !!(window.CSS && CSS.supports && CSS.supports("animation-timeline: view()"));
  var dists = [];       // на сколько px сдвинут каждый телефон в начале выезда
  var measuredW = -1;   // при какой ширине окна посчитаны dists

  function measure() {
    measuredW = vw;
    dists = slides.map(function (el, i) {
      var w = el.offsetWidth;
      var pr = el.parentElement.getBoundingClientRect();
      var restLeft = pr.left + (pr.width - w) / 2;
      var edge = i % 2 ? restLeft + w + 24 : vw - restLeft + 24;
      return Math.min(edge, 360) * (i % 2 ? -1 : 1);
    });
    if (cssSlides) slides.forEach(function (el, i) { el.style.setProperty("--v1-dx", dists[i] + "px"); });
  }

  function update() {
    ticking = false;
    var w = document.documentElement.clientWidth;
    if (!touch || w !== vw) { vw = w; vh = window.innerHeight; }
    var canScroll = document.documentElement.scrollHeight > vh + 40;

    // --- Первый экран ---
    var he = easeOutCubic(canScroll ? clamp(window.scrollY / (vh * 0.5)) : 1);
    var narrow = vw < 760;
    var phoneW;

    copy.style.setProperty("--hero-min", canScroll ? Math.round(vh * 0.66 - 60) + "px" : "auto");
    if (narrow) phoneW = Math.round(vw * 0.42);
    else if (canScroll) phoneW = Math.round(Math.min(vw * 0.74, Math.max(300, Math.min(560, vh * 0.5))));
    else phoneW = Math.round(Math.min(390, vw * 0.74));
    var spread = narrow ? Math.round(phoneW * 0.56) : 250;
    phones.style.setProperty("--phone-w", phoneW + "px");

    var heroY = canScroll ? Math.round((1 - he) * vh * 0.03) : 0;
    main.style.transform = "translateY(" + heroY + "px) scale(" + (0.9 + 0.1 * he).toFixed(3) + ")";

    var sideOp = (0.15 + 0.85 * he).toFixed(2);
    sideL.style.transform = "translateX(" + Math.round(-spread * he) + "px) scale(0.8) rotate(" + (-7 * he).toFixed(2) + "deg)";
    sideR.style.transform = "translateX(" + Math.round(spread * he) + "px) scale(0.8) rotate(" + (7 * he).toFixed(2) + "deg)";
    sideL.style.opacity = sideOp;
    sideR.style.opacity = sideOp;

    // --- Телефоны в блоке функций: чётные выезжают справа, нечётные слева ---
    if (vw !== measuredW) measure();
    if (cssSlides) return;

    // Сначала все замеры, потом все сдвиги: иначе браузер пересчитывает раскладку
    // на каждом телефоне. Сдвиг идёт только по X, поэтому вертикаль от него не зависит.
    var rects = slides.map(function (el) { return el.getBoundingClientRect(); });
    slides.forEach(function (el, i) {
      var r = 1;
      if (canScroll) {
        var ph = rects[i].height || 600;
        r = clamp((vh - rects[i].top - ph * 0.05) / ph);
      }
      // Без округления до целого пикселя: на экранах iPhone так движение без ступенек.
      var dx = (1 - easeOutQuad(r)) * dists[i];
      el.style.transform = "translate3d(" + dx.toFixed(1) + "px, 0, 0)";
    });
  }

  function onScroll() {
    if (!ticking) {
      ticking = true;
      requestAnimationFrame(update);
    }
  }

  window.addEventListener("scroll", onScroll, { passive: true });
  // После загрузки картинок и при смене размера окна раскладка могла измениться - пересчитать.
  window.addEventListener("resize", function () { measuredW = -1; onScroll(); });
  window.addEventListener("load", function () { measuredW = -1; onScroll(); });
  update();
})();
