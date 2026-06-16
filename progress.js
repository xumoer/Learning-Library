/*
 * Shared reading-progress tracker.
 * Include from each document page:  <script src="../../progress.js"></script>
 *
 * Records how far the reader has scrolled into the page (a monotonic 0–100 max)
 * in localStorage, keyed by the page's library-relative path. index.html reads
 * the same key to fill the progress bar on that document's card. Same-origin
 * only, no backend — works identically locally and on GitHub Pages. Progress is
 * per-browser/per-device (it's a personal "how far I've read" marker).
 */
(function () {
  var path = location.pathname;
  var i = path.indexOf('/library/');
  if (i < 0) return;                       // only track pages under library/
  var key = 'lib:progress:' + path.slice(i + 1);

  var doc = document.documentElement;
  var saved = parseInt(localStorage.getItem(key), 10);
  var max = isNaN(saved) ? 0 : saved;

  function update() {
    var span = doc.scrollHeight - doc.clientHeight;
    // page fits on screen with nothing to scroll → fully read
    var p = span > 0 ? Math.min(100, Math.round(window.scrollY / span * 100)) : 100;
    if (p > max) {
      max = p;
      try { localStorage.setItem(key, String(max)); } catch (e) {}
    }
  }

  window.addEventListener('scroll', update, { passive: true });
  window.addEventListener('resize', update);
  update();
})();
