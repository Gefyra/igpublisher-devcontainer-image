# Custom template

This IG is built with this folder as its template (`template = #custom-template` in `ig.ini`). It doesn't replace the base template, it builds on it: `package/package.json` names the base (`"base"` and `"dependencies"`), and every file here either overrides the base template's file of the same name or adds a new one.

## What is in here

| File | What it does |
|---|---|
| `package/package.json` | Names the base template. `current` follows its newest build; pin a version to keep the look stable |
| `package/includes/fragment-header.html` | Logo in the page header, linked to the publisher's site |
| `package/includes/fragment-css.html` | Loads `custom.css` on every page |
| `package/includes/_append.fragment-footer.html` | Adds a link to the footer |
| `package/includes/custom-note.html` | An include of your own: a note box for pages |
| `package/content/assets/css/custom.css` | Colors and styles |
| `package/content/assets/images/gefyra-logo.png` | The logo |

## Things to try

**Change the colors.** Edit the variables in `:root` in `custom.css`. The base template's `assets/css/project.css` lists all of them with a comment each; after a build it is in `template/content/assets/css/project.css`.

**Use your own logo.** Put it into `package/content/assets/images/` and change `src`, `alt` and the link in `fragment-header.html`.

**Add a note box to a page.** In any page in `input/pagecontent/`:

```liquid
{% include custom-note.html title="Note" text="Only for **German** systems." %}
```

**Extend instead of replace.** A file named `_append.<name>` is appended to the base template's `<name>` rather than replacing it, as `_append.fragment-footer.html` shows. Replacing a whole include works too, but then changes to it in the base template no longer reach you.

**Override more.** Copy a file from `template/` (the merged template the publisher unpacks during a build) into the same path under `package/` and change it there. Stick to `includes/` and `content/`: layouts change more often in the base template.

## Back to the default template

Set `template` in `ig.ini` back to the line recorded above it (`; previous: …`) and delete this folder.
