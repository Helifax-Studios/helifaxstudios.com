(() => {
  const toggle = document.querySelector('.nav-toggle');
  const nav = document.querySelector('#site-nav');

  if (!toggle || !nav) return;

  const setExpanded = (isOpen) => {
    toggle.setAttribute('aria-expanded', String(isOpen));
    nav.classList.toggle('open', isOpen);
  };

  toggle.addEventListener('click', () => {
    const isOpen = nav.classList.contains('open');
    setExpanded(!isOpen);
  });

  // Close menu when clicking a link (mobile)
  nav.addEventListener('click', (e) => {
    const t = e.target;
    if (t && t.tagName === 'A' && nav.classList.contains('open')) {
      setExpanded(false);
    }
  });

  // Close menu on Escape
  window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') setExpanded(false);
  });
})();
