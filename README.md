# css-inline

Crystal bindings for [css-inline](https://github.com/Stranger6667/css-inline) — a high-performance library for inlining CSS into HTML. Perfect for preparing HTML emails or embedding HTML into third-party web pages.

## Prerequisites

- [Rust toolchain](https://rustup.rs/) (the C library is compiled from source during installation)

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  css-inline:
    github: osbre/css-inline
```

Run `shards install` — this will automatically build the native library.

## Usage

```crystal
require "css-inline"

# Inline CSS from <style> tags
html = "<html><head><style>h1 { color: blue; }</style></head><body><h1>Hello</h1></body></html>"
result = CssInline.inline(html)
# => <html><head></head><body><h1 style="color: blue;">Hello</h1></body></html>

# Inline a CSS fragment
result = CssInline.inline_fragment("<h1>Hello</h1>", "h1 { color: blue; }")
# => <h1 style="color: blue;">Hello</h1>
```

### Options

```crystal
inliner = CssInline::CSSInliner.new(
  keep_style_tags: true,
  extra_css: "h1 { font-size: 2em; }",
  minify_css: true,
)

result = inliner.inline(html)
```

All available options:

| Option | Default | Description |
|--------|---------|-------------|
| `inline_style_tags` | `true` | Inline CSS from `<style>` tags |
| `keep_style_tags` | `false` | Keep `<style>` tags after inlining |
| `keep_link_tags` | `false` | Keep `<link>` tags after inlining |
| `keep_at_rules` | `false` | Keep `@media` and other at-rules |
| `load_remote_stylesheets` | `true` | Fetch and inline remote stylesheets |
| `minify_css` | `false` | Minify the inlined CSS |
| `remove_inlined_selectors` | `false` | Remove selectors that were inlined |
| `apply_width_attributes` | `false` | Set `width` HTML attributes from CSS |
| `apply_height_attributes` | `false` | Set `height` HTML attributes from CSS |
| `base_url` | `nil` | Base URL for resolving relative URLs |
| `extra_css` | `nil` | Additional CSS to inline |
| `cache` | `nil` | Stylesheet cache (see below) |

### Stylesheet Cache

Reuse parsed stylesheets across multiple calls:

```crystal
cache = CssInline::StylesheetCache.new(size: 64)
inliner = CssInline::CSSInliner.new(cache: cache)

inliner.inline(html1)
inliner.inline(html2) # reuses cached stylesheets
```

## Contributing

1. Fork it (<https://github.com/osbre/css-inline/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Ostap Brehin](https://github.com/osbre) - creator and maintainer
