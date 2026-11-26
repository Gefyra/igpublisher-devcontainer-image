This IG has a template of its own, in `custom-template/`. It builds on the standard template and only adds to it. This page shows what it adds and where to change it; `custom-template/README.md` has the details.

To remove the page, delete `input/pagecontent/custom-template.md` and its entry under `menu:` in `sushi-config.yaml`.

### Logo

The logo at the top left comes from `custom-template/package/includes/fragment-header.html`. The image is `custom-template/package/content/assets/images/gefyra-logo.png`. To use another logo, put the file next to it and change `src`, `alt` and the link in the include.

Next to the logo, badges show the IG's `status` and, if it is set, `experimental` from `sushi-config.yaml`. They come from the same include and update with every build.

### Links in the header

The template has an empty include `header-links.html` next to the logo. An IG fills it with its own `input/includes/header-links.html`: an IG's includes win over the template's. That way several IGs can share one template and still differ in small things. Try it with a file like this:

```
<span class="header-links-label">Builds on:</span> <a href="https://example.org/fhir/base-ig">Base IG</a>
```

### Draft banner

As long as `releaseLabel` in `sushi-config.yaml` is `ci-build` or `status` is `draft`, a bar under the menu says that this is a draft, on every page, including the generated ones. The text is set per language in `custom-template/package/includes/fragment-css.html`, the look in `custom.css` (`#segment-breadcrumb::before`). It is left out when printing.

### Colors

The colors are CSS variables at the top of `custom-template/package/content/assets/css/custom.css`. The standard template styles everything through such variables, so changing a value there restyles the whole IG.

<table class="grid">
  <tr><th>Variable</th><th>Used for</th><th>Color</th></tr>
  <tr><td><code>--brand-color</code></td><td>Links, menu hover, the line under the header</td><td style="background-color: var(--brand-color)"> </td></tr>
  <tr><td><code>--brand-color-dark</code></td><td>Link hover, the active menu item</td><td style="background-color: var(--brand-color-dark)"> </td></tr>
  <tr><td><code>--brand-text-color</code></td><td>Menu bar, title and status in the header, footer</td><td style="background-color: var(--brand-text-color)"> </td></tr>
</table>

### Note boxes

`custom-template/package/includes/custom-note.html` is an include of the template's own. Any page can use it:

```
{% raw %}{% include custom-note.html title="Note" text="Only for **German** systems." %}{% endraw %}
```

{% include custom-note.html title="Note" text="Only for **German** systems." %}

Without a title:

{% include custom-note.html text="The text is Markdown, so **bold**, `code` and [links](index.html) work." %}

### Open items

`custom-template/package/includes/open-item.html` marks what is still open or only assumed. Each box gets an anchor, so other pages and issues can link to it:

```
{% raw %}{% include open-item.html title="Paging" text="Whether servers **SHALL** support `_count` is still open." %}
{% include open-item.html kind="assumption" text="Clients send `Accept: application/fhir+json`." %}{% endraw %}
```

{% include open-item.html title="Paging" text="Whether servers **SHALL** support `_count` is still open." %}

{% include open-item.html kind="assumption" text="Clients send `Accept: application/fhir+json`." %}

A link to the first box: [Paging](#oi-paging). Longer text goes into a `capture` block first, see the comment at the top of the include.

### Tables

Tables written in Markdown get borders and striped rows from `custom.css`. The tables the publisher generates keep their own look.

| Element | Must Support | Note |
|---|---|---|
| `identifier` | yes | at least one |
| `name` | yes | |
| `telecom` | no | |

### Footer

The link to gefyra.info at the end of the footer comes from `custom-template/package/includes/_append.fragment-footer.html`. Its name starts with `_append.`, so it is added to the standard template's footer instead of replacing it.

Two more links appear on their own: *Privacy* once the IG has a page `privacy.html` (add `input/pagecontent/privacy.md` and list it in the menu), and *Source* when the IG is built from a git repository with a remote.

### Head of the page

`fragment-css.html` is the one place in the HTML `<head>` that a child template can add to. Besides loading `custom.css`, it sets the page description for search engines (from the IG's `description`) and the color of the browser bar on phones. For your own favicon, put a PNG named `favicon.png` into `custom-template/package/content/assets/ico/`; the base template already links it.

### Going further

Any file of the standard template can be overridden by putting a file of the same name into the same place under `custom-template/package/`. After a build, `template/` shows the merged result — the place to look for what there is to override.
