# Structured Data

Minimal JSON-LD starters for the fixes in `SKILL.md`. Describe visible content only; use the most specific type; validate rendered output with the Rich Results Test.

## Organization

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Example Store",
  "url": "https://example.com/",
  "logo": "https://example.com/logo.png"
}
</script>
```

## Article

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "How to maintain your widgets",
  "author": { "@type": "Person", "name": "A. Engineer" },
  "datePublished": "2024-01-15",
  "image": ["https://example.com/hero.jpg"]
}
</script>
```

## Product

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Product",
  "name": "Blue widget",
  "image": ["https://example.com/blue-widget.jpg"],
  "offers": {
    "@type": "Offer",
    "priceCurrency": "USD",
    "price": "49.00",
    "availability": "https://schema.org/InStock"
  },
  "aggregateRating": { "@type": "AggregateRating", "ratingValue": "4.9", "reviewCount": "10231" }
}
</script>
```

Only include `aggregateRating` when reviews are visible on the page.

## FAQ

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [{
    "@type": "Question",
    "name": "How long is shipping?",
    "acceptedAnswer": { "@type": "Answer", "text": "Orders ship in 2 business days." }
  }]
}
</script>
```

## Breadcrumb

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    { "@type": "ListItem", "position": 1, "name": "Products", "item": "https://example.com/products" },
    { "@type": "ListItem", "position": 2, "name": "Blue widget", "item": "https://example.com/products/blue-widget" }
  ]
}
</script>
```

Validation: Rich Results Test for eligibility signals, Schema.org validator for syntax. Passing either never promises display.
