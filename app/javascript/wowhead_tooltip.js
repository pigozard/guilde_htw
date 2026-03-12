const tooltip = document.createElement('div');
tooltip.id = 'wh-custom-tooltip';
tooltip.style.cssText = `
  position: fixed;
  background: #1a1a2e;
  border: 1px solid #c8a84b;
  border-radius: 4px;
  padding: 10px 14px;
  color: #fff;
  font-size: 13px;
  max-width: 280px;
  pointer-events: none;
  display: none;
  z-index: 9999;
  box-shadow: 0 4px 16px rgba(0,0,0,0.6);
`;
document.body.appendChild(tooltip);

document.addEventListener('mouseover', async (e) => {
  const el = e.target.closest('[data-wowhead]');
  if (!el) return;

  const match = el.dataset.wowhead.match(/item=(\d+)/);
  if (!match) return;
  const itemId = match[1];

  tooltip.innerHTML = '<em style="color:#aaa">Chargement...</em>';
  tooltip.style.display = 'block';

  try {
    const res = await fetch(`https://nether.wowhead.com/tooltip/item/${itemId}?dataEnv=1&locale=frFR`);
    const data = await res.json();
    tooltip.innerHTML = `
      <div style="color:#c8a84b; font-weight:bold; margin-bottom:6px">${data.name}</div>
      <div style="color:#ccc; font-size:12px">${data.tooltip}</div>
    `;
  } catch {
    tooltip.innerHTML = '<em style="color:#f88">Erreur de chargement</em>';
  }
});

document.addEventListener('mousemove', (e) => {
  const el = e.target.closest('[data-wowhead]');
  if (!el) {
    tooltip.style.display = 'none';
    return;
  }
  tooltip.style.left = (e.clientX + 16) + 'px';
  tooltip.style.top  = (e.clientY + 8) + 'px';
});

document.addEventListener('mouseout', (e) => {
  if (!e.target.closest('[data-wowhead]')) {
    tooltip.style.display = 'none';
  }
});
