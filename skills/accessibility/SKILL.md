---
name: accessibility
description: Audits and fixes web accessibility against WCAG 2.2 (alt text, contrast, keyboard, focus, forms, ARIA). Use when accessibility, a11y, WCAG, screen reader, or keyboard navigation is requested, or a Lighthouse accessibility score needs improvement.
---

# Accessibility

Make web content usable by everyone, including assistive-technology users. Automated checks catch only a subset of barriers: a Lighthouse 100 is not WCAG conformance. Fix measured failures with issue-level evidence, then complete the manual checks.

Source: adapted from `addyosmani/web-quality-skills` (`accessibility`, MIT). Condensed here; full WCAG wording wins on conflict.

## When to Use

- Accessibility or a11y audit requested, WCAG compliance question
- Screen-reader, keyboard, focus, contrast, or form-label defects reported
- Lighthouse accessibility score below target
- New page or component about to ship to public users

**NOT for:**

- Design taste or layout polish with no a11y signal — do the work without this skill
- Performance or SEO findings from the same audit — see `performance`, `seo`, or the `web-quality-audit` orchestrator
- Native mobile a11y APIs — platform docs win; use this skill only for web surfaces

## Process

```
1. EVIDENCE → Live audit when the page runs, else static inspection (hypotheses only)
2. LOCALIZE → Failing nodes point at the component or template
3. FIX      → The specific barrier, nothing else
4. VERIFY   → Re-run the same audit plus the affected manual flow
```

### 1. Evidence

When a rendered page is available, prefer a live audit:

- Lighthouse accessibility category (mobile navigation mode for public pages; snapshot mode when reload would lose auth or user-created state).
- Rendered accessibility-tree snapshot for names, roles, states, landmarks, heading structure; exercise the affected flow by keyboard only.
- Fallback without live-browser tooling: `npx lighthouse <url> --only-categories=accessibility`, plus `axe` for component-level coverage.

When only source exists, label findings **hypotheses** and name the browser workflow that would confirm each high-impact one. Never claim WCAG failure from code alone.

### 2. Fix the barrier

Summaries below; copy-paste markup lives in [references/a11y-patterns.md](references/a11y-patterns.md). Open the section you need when you reach that code, not before.

**Perceivable**

- **Text alternatives.** Every `img` has meaningful `alt`; decorative images use `alt=""`. Icon-only buttons get `aria-label` or visually-hidden text, never a bare SVG. One good `alt` also serves `seo` discoverability — never keyword-stuff. [Pattern](references/a11y-patterns.md#text-alternatives)
- **Contrast.** AA minimums: 4.5:1 normal text, 3:1 large text and UI components. `:focus-visible` indicators need 3:1 against the background too. Never convey state by color alone — add icon plus text. [Pattern](references/a11y-patterns.md#contrast-and-focus)
- **Media.** Video ships captions (`<track kind="captions">`); audio ships a transcript. No autoplay without user control.

**Operable**

- **Keyboard.** Prefer native `<button>`, `<a href>`, form controls — they handle focus, Enter/Space, and semantics for free. Custom controls must be focusable and handle `Enter`/`Space` without double-triggering native behavior. No keyboard traps. [Pattern](references/a11y-patterns.md#keyboard-and-focus)
- **Focus.** Never remove outlines globally. Use `:focus-visible` for keyboard-only indicators; keep focused elements clear of sticky headers via `scroll-margin`. [Pattern](references/a11y-patterns.md#contrast-and-focus)
- **Skip link.** One "Skip to main content" link bypassing repetitive navigation. [Pattern](references/a11y-patterns.md#skip-link)
- **Target size.** Minimum 24×24 CSS px (AA); 44×44 recommended for touch. Inline text links are exempt.
- **Motion and timing.** Honor `prefers-reduced-motion`; let users extend time limits; no content that flashes more than 3 times per second.

**Understandable**

- **Language and structure.** `<html lang>` set; headings form a logical hierarchy; navigation and help appear in consistent order.
- **Forms.** Every input has a programmatically associated label; errors use `aria-invalid`, `aria-describedby`, and focus the first error on submit. [Pattern](references/a11y-patterns.md#forms-and-errors)
- **Auth.** Never require puzzle-solving or memorization alone — allow paste/autofill and offer passkey, SSO, or email-link alternatives.

**Robust**

- **ARIA.** Native elements first. When ARIA is needed, roles and states must match behavior (`tablist` wiring, `aria-checked`, `aria-expanded`). [Pattern](references/a11y-patterns.md#aria-and-live-regions)
- **Live regions.** Announce dynamic results with `aria-live` or `role="alert"` without moving focus. [Pattern](references/a11y-patterns.md#aria-and-live-regions)

### 3. Verify

- Re-run the same audit under the same conditions; failing nodes must clear.
- Keyboard-walk the affected flow: Tab reaches everything in visual order, Enter/Space activates, focus is always visible, Escape closes dialogs and Tab cycles inside modal dialogs (focus trap).
- Spot-check at 200% zoom and with `prefers-reduced-motion` enabled.
- Screen-reader pass for high-stakes flows (VoiceOver, NVDA, or TalkBack) — report which one was used; an untested flow stays `needs-validation`.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Lighthouse is 100, so we're compliant" | Automated tools detect a subset. Manual keyboard and screen-reader checks still apply. |
| "It's just a div with onClick" | A div has no role, name, or keyboard activation. Use a button. |
| "Outline removal looks cleaner" | Removing focus hides keyboard users. Style `:focus-visible` instead. |
| "Gray text is a design choice" | Below 4.5:1 it excludes low-vision users. Darken the text or the background. |
| "ARIA fixes everything" | Wrong ARIA is worse than none. Native elements first. |

## Red Flags

- Images without `alt`, icon buttons without accessible names
- `*:focus { outline: none }` with no `:focus-visible` replacement
- Color-only error or status indicators
- Custom dropdown, tab, or dialog built from divs without roles and keyboard handling
- Form inputs without associated labels
- Keyboard trap: Tab enters a component and cannot leave
- Focus hidden behind a sticky header or modal
- Autoplaying media, aggressive time limits, flashing content
- Login that blocks paste or offers no alternative to memorization

## Verification

- [ ] Same audit re-run; previously failing nodes clear
- [ ] Keyboard-only pass of the affected flow, focus always visible
- [ ] Contrast meets AA for text and focus indicators
- [ ] Forms label every input; errors announced and focused
- [ ] No new axe or Lighthouse accessibility failures
- [ ] Screen-reader or `needs-validation` explicitly recorded
