# A11y Patterns

Copy-paste markup for the fixes in `SKILL.md` §2. Each section is self-contained.

## Text alternatives

```html
<!-- Descriptive alt -->
<img src="chart.png" alt="Bar chart showing 40% increase in Q3 sales" />

<!-- Decorative: empty alt, hidden from AT -->
<img src="decorative-border.png" alt="" role="presentation" />

<!-- Icon button: label on the button, hide the icon -->
<button aria-label="Open menu">
  <svg aria-hidden="true"><!-- menu icon --></svg>
</button>

<!-- Alternative: visually-hidden text -->
<button>
  <svg aria-hidden="true"><!-- menu icon --></svg>
  <span class="visually-hidden">Open menu</span>
</button>
```

```css
.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
  border: 0;
}
```

## Contrast and focus

```css
/* Keyboard-only focus, currentColor inherits already-checked text contrast */
:focus-visible {
  outline: 2px solid currentColor;
  outline-offset: 2px;
}

/* Keep focused elements clear of sticky bars */
:focus {
  scroll-margin-top: 80px;
  scroll-margin-bottom: 60px;
}

/* Reduced motion */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

Rules: 4.5:1 normal text, 3:1 large text and UI components, 3:1 focus indicators. Never signal state by color alone — pair color with icon plus text and set `aria-invalid` where applicable.

## Keyboard and focus

Prefer native elements. Only wire manual activation for non-native controls:

```html
<!-- Best: native button, no JS keyboard handling needed -->
<button type="button">Open</button>
```

```javascript
// Fallback: non-native control must be focusable AND keyboard-activatable.
// Never add this to a native <button> (Enter/Space already fire click).
el.setAttribute('role', 'button');
el.setAttribute('tabindex', '0');
el.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' || e.key === ' ') {
    e.preventDefault();
    handleAction();
  }
});
```

Dialogs: prefer native `<dialog>` (focus trap built in). Custom modals must trap Tab inside, return focus on close, and close on Escape.

## Skip link

```html
<a class="skip-link" href="#main">Skip to main content</a>
<main id="main" tabindex="-1"><!-- page content --></main>
```

```css
.skip-link {
  position: absolute;
  left: -9999px;
}
.skip-link:focus-visible {
  left: 8px;
  top: 8px;
  z-index: 100;
  background: #fff;
  padding: 8px 12px;
}
```

## Forms and errors

```html
<!-- Explicit labels -->
<label for="email">Email address</label>
<input id="email" name="email" type="email" autocomplete="email" required />

<!-- Error: describedby + invalid + alert -->
<label for="email2">Email address</label>
<input id="email2" aria-invalid="true" aria-describedby="email2-error" />
<p id="email2-error" role="alert">Enter an address like name@example.com.</p>
```

On submit: focus the first invalid field. Allow paste in password fields (`autocomplete="current-password"`); offer passkey or email-link alternatives.

## Aria and live regions

```html
<!-- Tabs: roles must match behavior, arrow keys move between tabs -->
<div role="tablist" aria-label="Settings">
  <button role="tab" aria-selected="true" aria-controls="panel-1" id="tab-1">General</button>
  <button role="tab" aria-selected="false" aria-controls="panel-2" id="tab-2" tabindex="-1">Billing</button>
</div>
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1">…</div>
```

```html
<!-- Polite announcement, focus stays put -->
<div aria-live="polite" id="status"></div>
```

```javascript
function showNotification(message) {
  const region = document.getElementById('status');
  region.textContent = '';
  requestAnimationFrame(() => {
    region.textContent = message;
  });
}
```
