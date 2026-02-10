# Tailwind CSS Stack Module

> Framework-specific knowledge for Tailwind CSS v3/v4. Add to your project's `debugging.md` or `tech-stack.md`.

## Configuration

### Basic Config (Tailwind v3)

```javascript
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
          900: '#0c4a6e',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
        '128': '32rem',
      },
      borderRadius: {
        '4xl': '2rem',
      },
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
  ],
}
```

### Tailwind v4 (CSS-based config)

Tailwind v4 moves configuration into CSS:

```css
/* app/globals.css */
@import "tailwindcss";

@theme {
  --color-brand-500: #0ea5e9;
  --color-brand-600: #0284c7;
  --font-sans: "Inter", system-ui, sans-serif;
  --breakpoint-3xl: 1920px;
}
```

## Dark Mode

### Class Strategy (Recommended)

```javascript
// tailwind.config.js (v3)
module.exports = {
  darkMode: 'class', // or 'media' for OS preference only
}
```

```tsx
// Usage
<div className="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
  <h1 className="text-black dark:text-white">Title</h1>
  <p className="text-gray-600 dark:text-gray-400">Body text</p>
</div>
```

### Theme Toggle Implementation

```typescript
// Simple toggle (class strategy)
function toggleDark() {
  document.documentElement.classList.toggle('dark')
  localStorage.setItem('theme',
    document.documentElement.classList.contains('dark') ? 'dark' : 'light'
  )
}

// Respect OS preference + user override
function initTheme() {
  const stored = localStorage.getItem('theme')
  if (stored === 'dark' || (!stored && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    document.documentElement.classList.add('dark')
  }
}
```

**Gotcha:** When using `class` strategy with SSR (Next.js), you may get a flash of wrong theme. Fix: Add the theme initialization script to `<head>` as a blocking script.

## Responsive Breakpoints

| Prefix | Min Width | CSS |
|--------|-----------|-----|
| `sm:` | 640px | `@media (min-width: 640px)` |
| `md:` | 768px | `@media (min-width: 768px)` |
| `lg:` | 1024px | `@media (min-width: 1024px)` |
| `xl:` | 1280px | `@media (min-width: 1280px)` |
| `2xl:` | 1536px | `@media (min-width: 1536px)` |

**Tailwind is mobile-first.** Unprefixed classes apply to all sizes. Prefixed classes apply at that breakpoint and up.

```tsx
// Mobile: stack, Tablet: 2 columns, Desktop: 3 columns
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  {items.map(item => <Card key={item.id} />)}
</div>

// Mobile: full width, Desktop: sidebar layout
<div className="flex flex-col lg:flex-row">
  <aside className="w-full lg:w-64 lg:shrink-0">Sidebar</aside>
  <main className="flex-1">Content</main>
</div>
```

## Component Patterns

### Card

```tsx
<div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-700 dark:bg-gray-800">
  <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Title</h3>
  <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">Description</p>
</div>
```

### Button Variants

```tsx
// Primary
<button className="rounded-lg bg-brand-600 px-4 py-2 text-sm font-medium text-white hover:bg-brand-700 focus:outline-none focus:ring-2 focus:ring-brand-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors">
  Primary
</button>

// Secondary
<button className="rounded-lg border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-brand-500 focus:ring-offset-2 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700 transition-colors">
  Secondary
</button>

// Ghost
<button className="rounded-lg px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-800 transition-colors">
  Ghost
</button>
```

### Input

```tsx
<input
  type="text"
  className="block w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 placeholder-gray-500 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 dark:border-gray-600 dark:bg-gray-800 dark:text-white dark:placeholder-gray-400"
  placeholder="Enter text..."
/>
```

### Badge

```tsx
<span className="inline-flex items-center rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-800 dark:bg-green-900 dark:text-green-300">
  Active
</span>
```

## @apply vs Utility Classes

### When to Use @apply

**Rarely.** The whole point of Tailwind is utility-first. Use `@apply` only when:
1. You're styling elements you can't add classes to (e.g., CMS content, markdown output)
2. You have a truly reusable pattern that appears 10+ times with identical classes

```css
/* Acceptable: Styling rendered markdown */
.prose h1 {
  @apply text-3xl font-bold text-gray-900 dark:text-white mb-4;
}

/* Acceptable: Repeated utility pattern */
.btn-primary {
  @apply rounded-lg bg-brand-600 px-4 py-2 text-sm font-medium text-white hover:bg-brand-700 focus:outline-none focus:ring-2 focus:ring-brand-500 focus:ring-offset-2 transition-colors;
}
```

### When NOT to Use @apply

```css
/* BAD: Just use the utilities inline — this gains nothing */
.my-card {
  @apply rounded-lg p-6 shadow-sm;
}
```

**Better approach:** Create a React/Vue/Svelte component instead of an `@apply` class:

```tsx
function Card({ children, className }: { children: React.ReactNode; className?: string }) {
  return (
    <div className={`rounded-lg border border-gray-200 bg-white p-6 shadow-sm ${className ?? ''}`}>
      {children}
    </div>
  )
}
```

## Common Issues

### Classes Not Applying (Content Purging)

**Symptom:** Classes work in dev but disappear in production build.

**Cause:** Tailwind scans your `content` paths at build time to determine which classes to include. If a file isn't in the content array, its classes are purged.

**Fix:** Ensure ALL files with Tailwind classes are covered:
```javascript
content: [
  './app/**/*.{js,ts,jsx,tsx}',
  './components/**/*.{js,ts,jsx,tsx}',
  './lib/**/*.{js,ts,jsx,tsx}',       // Don't forget utility files
  './node_modules/@mylib/**/*.{js,ts,jsx,tsx}', // Include component libraries
],
```

### Dynamic Classes Not Working

**This is the #1 Tailwind gotcha.**

Tailwind extracts class names at build time using static analysis. It does NOT evaluate JavaScript. Dynamic class construction fails:

```tsx
// BAD: Tailwind cannot detect these classes
const color = 'red'
<div className={`bg-${color}-500`} />        // Purged in production
<div className={`text-${props.size}`} />      // Purged in production
<div className={isActive ? 'bg-green' : 'bg-red'} + '-500'} />  // Purged

// GOOD: Use complete class names
<div className={color === 'red' ? 'bg-red-500' : 'bg-blue-500'} />

// GOOD: Map to complete strings
const colorMap = {
  red: 'bg-red-500 text-red-900',
  blue: 'bg-blue-500 text-blue-900',
  green: 'bg-green-500 text-green-900',
}
<div className={colorMap[color]} />

// GOOD: Safelist if you truly need dynamic classes
// tailwind.config.js
module.exports = {
  safelist: [
    { pattern: /bg-(red|blue|green)-(100|500|900)/ },
  ],
}
```

### Specificity Conflicts

**Symptom:** Your Tailwind class is being overridden by another CSS rule.

**Causes:**
1. Global CSS with higher specificity (`#id` selectors, `!important`)
2. Third-party component library styles
3. CSS Modules with conflicting class names

**Fixes:**
```tsx
// Use ! prefix for important (last resort)
<div className="!bg-white" />

// Better: Increase specificity in your global CSS to not conflict
// Even better: Remove conflicting global styles
```

### Hover/Focus Not Working on Mobile

`hover:` states don't apply on touch devices in the expected way. For touch-friendly interactions:

```tsx
// Use active: for tap feedback on mobile
<button className="bg-brand-600 hover:bg-brand-700 active:bg-brand-800">
  Tap me
</button>

// Group hover for parent-child interactions
<div className="group">
  <span className="text-gray-500 group-hover:text-brand-600">
    Highlights when parent is hovered
  </span>
</div>
```

### Transition Jank

```tsx
// BAD: Transitioning all properties (includes layout props, causes jank)
<div className="transition-all duration-300" />

// GOOD: Be specific about what transitions
<div className="transition-colors duration-200" />
<div className="transition-opacity duration-300" />
<div className="transition-transform duration-200" />
```

## Useful Utilities Often Missed

```tsx
// Truncate text with ellipsis
<p className="truncate">Very long text...</p>

// Multi-line truncation (line-clamp)
<p className="line-clamp-3">Truncates after 3 lines...</p>

// Scroll snap
<div className="snap-x snap-mandatory overflow-x-auto flex">
  <div className="snap-center shrink-0 w-80">Slide 1</div>
  <div className="snap-center shrink-0 w-80">Slide 2</div>
</div>

// Aspect ratio
<div className="aspect-video">16:9 container</div>
<div className="aspect-square">1:1 container</div>

// Container queries (v3.2+)
<div className="@container">
  <div className="@lg:grid-cols-2 @sm:grid-cols-1 grid">
    Responds to container size, not viewport
  </div>
</div>

// Ring for focus styles (better than outline)
<button className="focus:ring-2 focus:ring-brand-500 focus:ring-offset-2">
  Accessible focus
</button>

// Divide for borders between children
<ul className="divide-y divide-gray-200 dark:divide-gray-700">
  <li className="py-3">Item 1</li>
  <li className="py-3">Item 2</li>
</ul>

// Space between children (alternative to gap)
<div className="space-y-4">
  <div>Item 1</div>
  <div>Item 2</div>
</div>

// Prose (typography plugin) for rendered content
<article className="prose dark:prose-invert lg:prose-lg max-w-none">
  {renderedMarkdown}
</article>
```

## Class Merging with clsx/tailwind-merge

When building components that accept custom classNames, use `tailwind-merge` to handle conflicts:

```bash
npm install tailwind-merge clsx
```

```typescript
// lib/utils.ts
import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

```tsx
// Component usage
function Button({ className, ...props }: ButtonProps) {
  return (
    <button
      className={cn(
        'rounded-lg bg-brand-600 px-4 py-2 text-white', // Base styles
        className // User overrides win
      )}
      {...props}
    />
  )
}

// cn('bg-red-500', 'bg-blue-500') => 'bg-blue-500' (last wins, no conflict)
// Without twMerge: 'bg-red-500 bg-blue-500' (both applied, unpredictable)
```
