This IG has a template of its own, in `custom-template/`. It builds on the standard template and only adds to it. This page shows what it adds and where to change it; `custom-template/README.md` has the details.

To remove the page, delete `input/pagecontent/custom-template.md` and its entry under `menu:` in `sushi-config.yaml`.

### Logo

The logo at the top left comes from `custom-template/package/includes/fragment-header.html`. The image is `custom-template/package/content/assets/images/gefyra-logo.png`. To use another logo, put the file next to it and change `src`, `alt` and the link in the include.

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

### Footer

The link to gefyra.info at the end of the footer comes from `custom-template/package/includes/_append.fragment-footer.html`. Its name starts with `_append.`, so it is added to the standard template's footer instead of replacing it.

### Going further

Any file of the standard template can be overridden by putting a file of the same name into the same place under `custom-template/package/`. After a build, `template/` shows the merged result — the place to look for what there is to override.
