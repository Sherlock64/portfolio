/* Small progressive enhancements: theme toggle, mobile nav drawer, search,
   copy buttons on code blocks, and highlighting the current TOC entry. */
(function () {
  "use strict";

  var root = document.documentElement;
  var COPY_ICON = '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>';
  var CHECK_ICON = '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="20 6 9 17 4 12"/></svg>';

  /* ---------- Theme toggle ---------- */
  var themeBtn = document.querySelector("[data-theme-toggle]");
  function labelTheme() {
    if (!themeBtn) return;
    var dark = root.getAttribute("data-theme") !== "light";
    themeBtn.setAttribute("aria-label", dark ? "Switch to light mode" : "Switch to dark mode");
  }
  if (themeBtn) {
    labelTheme();
    themeBtn.addEventListener("click", function () {
      var next = root.getAttribute("data-theme") === "light" ? "dark" : "light";
      root.setAttribute("data-theme", next);
      try { localStorage.setItem("theme", next); } catch (e) {}
      labelTheme();
    });
  }

  /* ---------- Mobile nav drawer ---------- */
  var navBtn = document.querySelector("[data-nav-toggle]");
  var nav = document.getElementById("site-nav");
  function setNav(open) {
    root.classList.toggle("nav-open", open);
    if (navBtn) {
      navBtn.setAttribute("aria-expanded", String(open));
      navBtn.setAttribute("aria-label", open ? "Close navigation" : "Open navigation");
    }
    if (open && nav) {
      var first = nav.querySelector("a");
      if (first) first.focus();
    }
  }
  if (navBtn && nav) {
    navBtn.addEventListener("click", function () { setNav(!root.classList.contains("nav-open")); });
    document.querySelectorAll("[data-nav-close]").forEach(function (el) {
      el.addEventListener("click", function () { setNav(false); });
    });
    nav.addEventListener("click", function (e) {
      if (e.target.closest("a")) setNav(false);
    });
  }

  /* ---------- Search ---------- */
  var input = document.getElementById("search-input");
  var panel = document.getElementById("search-results");
  var list = panel && panel.querySelector("ul");
  var status = document.getElementById("search-status");
  var index = null;
  var loading = null;

  function loadIndex() {
    if (index) return Promise.resolve(index);
    if (!loading) {
      loading = fetch(input.getAttribute("data-index"))
        .then(function (r) { return r.json(); })
        .then(function (d) { index = d; return d; })
        .catch(function () { index = []; return index; });
    }
    return loading;
  }

  function snippet(body, term) {
    if (!body) return "";
    var i = body.toLowerCase().indexOf(term);
    if (i < 0) return body.slice(0, 120) + (body.length > 120 ? "…" : "");
    var start = Math.max(0, i - 40);
    return (start > 0 ? "…" : "") + body.slice(start, start + 140) + (start + 140 < body.length ? "…" : "");
  }

  function search(q) {
    var terms = q.toLowerCase().split(/\s+/).filter(Boolean);
    var hits = [];
    index.forEach(function (doc) {
      var title = (doc.title || "").toLowerCase();
      var tags = (doc.tags || "").toLowerCase();
      var body = (doc.body || "").toLowerCase();
      var score = 0;
      for (var i = 0; i < terms.length; i++) {
        var t = terms[i], s = 0;
        if (title.indexOf(t) >= 0) s += 10;
        if (tags.indexOf(t) >= 0) s += 5;
        if (body.indexOf(t) >= 0) s += 1;
        if (!s) return;
        score += s;
      }
      hits.push({ doc: doc, score: score });
    });
    hits.sort(function (a, b) { return b.score - a.score; });
    return { hits: hits.slice(0, 8), first: terms[0] };
  }

  function render(q) {
    list.textContent = "";
    var old = panel.querySelector(".md-search__empty");
    if (old) old.remove();
    if (!q) { panel.hidden = true; status.textContent = ""; return; }
    var res = search(q);
    if (!res.hits.length) {
      var p = document.createElement("p");
      p.className = "md-search__empty";
      p.textContent = "No results for “" + q + "”";
      panel.appendChild(p);
    }
    res.hits.forEach(function (h) {
      var li = document.createElement("li");
      var a = document.createElement("a");
      a.href = h.doc.url;
      var sec = document.createElement("span");
      sec.className = "md-search__hit-section";
      sec.textContent = h.doc.section;
      var title = document.createElement("span");
      title.className = "md-search__hit-title";
      title.textContent = h.doc.title;
      var text = document.createElement("span");
      text.className = "md-search__hit-text";
      text.textContent = snippet(h.doc.body, res.first);
      a.appendChild(sec); a.appendChild(title); a.appendChild(text);
      li.appendChild(a);
      list.appendChild(li);
    });
    panel.hidden = false;
    status.textContent = res.hits.length + (res.hits.length === 1 ? " result" : " results");
  }

  function closeSearch() { panel.hidden = true; }

  if (input && panel) {
    input.addEventListener("focus", function () {
      loadIndex().then(function () { if (input.value.trim()) render(input.value.trim()); });
    });
    input.addEventListener("input", function () {
      var q = input.value.trim();
      loadIndex().then(function () { render(q); });
    });
    input.addEventListener("keydown", function (e) {
      if (e.key === "ArrowDown") {
        var first = list.querySelector("a");
        if (first) { e.preventDefault(); first.focus(); }
      } else if (e.key === "Enter") {
        var top = list.querySelector("a");
        if (top) { e.preventDefault(); window.location.href = top.href; }
      }
    });
    list.addEventListener("keydown", function (e) {
      var links = Array.prototype.slice.call(list.querySelectorAll("a"));
      var i = links.indexOf(document.activeElement);
      if (e.key === "ArrowDown" && i < links.length - 1) { e.preventDefault(); links[i + 1].focus(); }
      if (e.key === "ArrowUp") { e.preventDefault(); (i > 0 ? links[i - 1] : input).focus(); }
    });
    list.addEventListener("click", function () { closeSearch(); input.blur(); });
    document.addEventListener("click", function (e) {
      if (!e.target.closest(".md-search")) closeSearch();
    });
  }

  document.addEventListener("keydown", function (e) {
    var typing = /^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName);
    if (input && ((e.key === "k" && (e.ctrlKey || e.metaKey)) || (e.key === "/" && !typing))) {
      e.preventDefault();
      input.focus();
      input.select();
    } else if (e.key === "Escape") {
      if (root.classList.contains("nav-open")) { setNav(false); if (navBtn) navBtn.focus(); }
      if (panel && !panel.hidden) { closeSearch(); input.focus(); }
      else if (document.activeElement === input) { input.value = ""; input.blur(); }
    }
  });

  /* ---------- Copy buttons on code blocks ---------- */
  document.querySelectorAll("div.highlighter-rouge").forEach(function (block) {
    var pre = block.querySelector("pre");
    if (!pre || !navigator.clipboard) return;
    var btn = document.createElement("button");
    btn.type = "button";
    btn.className = "copy-btn";
    btn.setAttribute("aria-label", "Copy code to clipboard");
    btn.innerHTML = COPY_ICON;
    btn.addEventListener("click", function () {
      navigator.clipboard.writeText(pre.innerText.replace(/\n$/, "")).then(function () {
        btn.classList.add("is-copied");
        btn.innerHTML = CHECK_ICON;
        if (status) status.textContent = "Copied to clipboard";
        setTimeout(function () {
          btn.classList.remove("is-copied");
          btn.innerHTML = COPY_ICON;
        }, 1500);
      });
    });
    block.appendChild(btn);
  });

  /* ---------- Highlight the current section in "On this page" ---------- */
  var tocLinks = document.querySelectorAll(".md-toc__link");
  if (tocLinks.length) {
    var byId = {};
    var headings = [];
    tocLinks.forEach(function (a) {
      var id = decodeURIComponent(a.getAttribute("href").slice(1));
      var h = document.getElementById(id);
      if (h) { byId[id] = a; headings.push(h); }
    });
    var ticking = false;
    var update = function () {
      ticking = false;
      var current = headings[0];
      headings.forEach(function (h) {
        if (h.getBoundingClientRect().top < 120) current = h;
      });
      // At the very bottom, the last heading may never reach the top.
      if (window.innerHeight + window.scrollY >= document.body.scrollHeight - 2) {
        current = headings[headings.length - 1];
      }
      tocLinks.forEach(function (a) { a.classList.remove("is-active"); });
      if (current && byId[current.id]) byId[current.id].classList.add("is-active");
    };
    window.addEventListener("scroll", function () {
      if (!ticking) { ticking = true; requestAnimationFrame(update); }
    }, { passive: true });
    update();
  }
})();
