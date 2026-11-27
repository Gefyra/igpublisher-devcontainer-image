This page shows features of the IG Publisher that you can use in your own pages. Each section shows what to write, then what it produces. It works with any template. The profile and the example it uses — __PROFILE_NAME__ and __EXAMPLE_TYPE__/__EXAMPLE_ID__ — were picked from this IG when the page was added.

Keep what helps, delete the rest. To remove the page, delete `input/pagecontent/ig-features.md` and its entry under `menu:` in `sushi-config.yaml`, and the files the task added for it: `input/images-source/ig-features-sequence.plantuml`, `input/data/ig_features.json` and `input/intro-notes/StructureDefinition-__PROFILE_ID__-intro.md` and `-notes.md`.

### Links to resources

Three square brackets link to a resource by name or canonical URL, or to a FHIR type. The link text is the resource's title, and the link follows the resource if its page ever moves.

```
[[~[__PROFILE_NAME__]]] · [[~[__PROFILE_URL__]]] · [[~[Patient]]] · this IG's version: [[~[$ver]]]
```

[[[__PROFILE_NAME__]]] · [[[__PROFILE_URL__]]] · [[[Patient]]] · this IG's version: [[[$ver]]]

Plain Markdown links work too: to a page of this IG, and, through `site.data.fhir.path`, into the FHIR specification of the version this IG is built on.

```
{% raw %}[the profile](StructureDefinition-__PROFILE_ID__.html) · [Patient in the spec]({{site.data.fhir.path}}patient.html){% endraw %}
```

[the profile](StructureDefinition-__PROFILE_ID__.html) · [Patient in the spec]({{site.data.fhir.path}}patient.html)

### Data about the IG

Liquid variables give access to what the publisher knows about the IG, so a page never states a version that has gone stale.

```
{% raw %}{{site.data.fhir.ig.title | default: site.data.fhir.ig.name}}, version {{site.data.fhir.ig.version}}, canonical {{site.data.fhir.canonical}}{% endraw %}
```

{{site.data.fhir.ig.title | default: site.data.fhir.ig.name}}, version {{site.data.fhir.ig.version}}, canonical {{site.data.fhir.canonical}}

There is more: the package id, the FHIR version and when the page was built.

```
{% raw %}Package {{site.data.fhir.packageId}}, FHIR {{site.data.fhir.version}}, built {{site.data.fhir.genDate}}{% endraw %}
```

Package {{site.data.fhir.packageId}}, FHIR {{site.data.fhir.version}}, built {{site.data.fhir.genDate}}

### Data about the IG's resources

After a build, `temp/pages/_data/` shows everything Liquid can read: `structuredefinitions`, `resources`, `pages`, `fhir` and more. A loop over `site.data.structuredefinitions` makes a table of the resource profiles with their base type and status:

```
{% raw %}<table class="grid">
<tr><th>Profile</th><th>Based on</th><th>Status</th></tr>
{% for sd in site.data.structuredefinitions %}{% assign p = sd[1] %}{% if p.kind == "resource" and p.derivation == "constraint" %}
<tr><td><a href="{{ p.path }}">{{ p.title | default: p.name }}</a></td><td><a href="{{ p.basepath }}">{{ p.basename }}</a></td><td>{{ p.status }}</td></tr>
{% endif %}{% endfor %}
</table>{% endraw %}
```

<table class="grid">
<tr><th>Profile</th><th>Based on</th><th>Status</th></tr>
{% for sd in site.data.structuredefinitions %}{% assign p = sd[1] %}{% if p.kind == "resource" and p.derivation == "constraint" %}
<tr><td><a href="{{ p.path }}">{{ p.title | default: p.name }}</a></td><td><a href="{{ p.basepath }}">{{ p.basename }}</a></td><td>{{ p.status }}</td></tr>
{% endif %}{% endfor %}
</table>

Extensions have `kind` "complex-type" and are left out here; `p.type == "Extension"` lists them instead. `site.data.resources` works the same way for every resource of the IG, keyed by `Type/id`. A page can quote a resource's description, so the text lives in one place only:

```
{% raw %}{% assign res = site.data.resources["StructureDefinition/__PROFILE_ID__"] %}
**{{ res.title | default: res.name }}:** {{ res.description | default: "(no description yet - set Description: in the FSH)" }}{% endraw %}
```

{% assign res = site.data.resources["StructureDefinition/__PROFILE_ID__"] %}
**{{ res.title | default: res.name }}:** {{ res.description | default: "(no description yet - set Description: in the FSH)" }}

### Data of your own

Every JSON file in `input/data/` is available as `site.data.<file name>`. Use it for your own tables and switches, for example a status per artifact, or a flag that CI sets only for release builds. The file name may only have letters, digits and `_`. This IG now has `input/data/ig_features.json`:

```
{% raw %}| Artifact | Status |
|---|---|
{% for s in site.data.ig_features.status %}| {{ s.artifact }} | {{ s.state }} |
{% endfor %}{% endraw %}
```

| Artifact | Status |
|---|---|
{% for s in site.data.ig_features.status %}| {{ s.artifact }} | {{ s.state }} |
{% endfor %}

### Conformance statements

Sentences with SHALL or SHOULD can be marked as conformance statements. The publisher numbers them, links them, and collects them in one table. Inline, put the statement between two section signs, with an id in front:

<p><code>A server §ex-1:**SHALL** reject an unknown code</code><code>§, and report it in an OperationOutcome.</code></p>

A server §ex-1:**SHALL** reject an unknown code§, and report it in an OperationOutcome.

For a statement spanning several paragraphs, put a paragraph that starts with two section signs before it — followed by `id:summary^title` — and a paragraph of just two section signs after it:

<p>Paragraph 1: <code>§</code><code>§ex-2:Search by identifier^Searching for a patient</code><br/>
Paragraph 2: <code>A client **SHOULD** search by identifier rather than by name.</code><br/>
Paragraph 3: <code>A server **SHALL** support the `identifier` search parameter.</code><br/>
Paragraph 4: <code>§</code><code>§</code></p>

This renders as

§§ex-2:Search by identifier^Searching for a patient

A client **SHOULD** search by identifier rather than by name.

A server **SHALL** support the `identifier` search parameter.

§§

The table of all statements in the IG goes wherever a paragraph consists of three section signs, and can only appear once per IG:

__CONFORMANCE_TABLE__

### Diagrams

Mermaid diagrams are written into an element with the class `mermaid`. See the [Mermaid syntax](https://mermaid.js.org/intro/syntax-reference.html) for flowcharts, sequence diagrams and more.

```
<div class="mermaid">
sequenceDiagram
    Client->>Server: GET __EXAMPLE_TYPE__/__EXAMPLE_ID__
    Server-->>Client: 200 OK, the __EXAMPLE_TYPE__
</div>
```

<div class="mermaid">
sequenceDiagram
    Client->>Server: GET __EXAMPLE_TYPE__/__EXAMPLE_ID__
    Server-->>Client: 200 OK, the __EXAMPLE_TYPE__
</div>

PlantUML diagrams are drawn during the build instead of in the browser, so they also show in the offline download. Each `input/images-source/<name>.plantuml` becomes an include `<name>.svg`. The `div` keeps Markdown away from the SVG. Sequence diagrams need nothing else; other kinds also need Graphviz.

```
{% raw %}<div>{% include ig-features-sequence.svg %}</div>{% endraw %}
```

<div>{% include ig-features-sequence.svg %}</div>

This IG now has `input/images-source/ig-features-sequence.plantuml`. A syntax error in such a file stops the build.

### Parts of an example

An example can be shown in JSON or XML, whole or in part. `BASE:` picks an element with FHIRPath, `ELIDE:` replaces elements with `...`, and `EXCEPT:` keeps only the elements named.

```
{%! fragment __EXAMPLE_TYPE__/__EXAMPLE_ID__ JSON ELIDE:text %}
{%! fragment __EXAMPLE_TYPE__/__EXAMPLE_ID__ XML EXCEPT:id %}
```

{% fragment __EXAMPLE_TYPE__/__EXAMPLE_ID__ JSON ELIDE:text %}

{% fragment __EXAMPLE_TYPE__/__EXAMPLE_ID__ XML EXCEPT:id %}

### Generated views

Everything the publisher renders on the resource pages is also available as an include: tables of a profile, the narrative of an example, and many more. After a build, `temp/pages/_includes` lists them all.

```
{% raw %}{% include StructureDefinition-__PROFILE_ID__-diff.xhtml %}
{% include __EXAMPLE_TYPE__-__EXAMPLE_ID__-html.xhtml %}{% endraw %}
```

{% include StructureDefinition-__PROFILE_ID__-diff.xhtml %}

{% include __EXAMPLE_TYPE__-__EXAMPLE_ID__-html.xhtml %}

A profile has more views than the differential:

| View | Include `StructureDefinition-<id>-…` |
|---|---|
| Counts of mandatory and Must Support elements, extensions used | `summary.xhtml` |
| Only the Must Support elements | `snapshot-by-mustsupport.xhtml` |
| Terminology bindings, constraints | `tx.xhtml`, `inv.xhtml` |
| Definitions of all elements (long) | `dict.xhtml` |
| Where the profile is used | `uses.xhtml` |

```
{% raw %}{% include StructureDefinition-__PROFILE_ID__-summary.xhtml %}
{% include StructureDefinition-__PROFILE_ID__-snapshot-by-mustsupport.xhtml %}{% endraw %}
```

{% include StructureDefinition-__PROFILE_ID__-summary.xhtml %}

{% include StructureDefinition-__PROFILE_ID__-snapshot-by-mustsupport.xhtml %}

### Text on a resource's own page

The publisher generates the pages of profiles, value sets, examples and so on. Your own text goes onto them through Markdown files in `input/intro-notes/`, named after the page. No configuration is needed.

```
input/intro-notes/<Type>-<id>-intro.md   shown above the generated content
input/intro-notes/<Type>-<id>-notes.md   shown below it
```

They work like any page: Liquid, `[[[…]]]` links and conformance statements all work. This IG now has both files for [the profile](StructureDefinition-__PROFILE_ID__.html); open it to see them.

### Lists of the IG's resources

Lists cover a whole kind of resource and stay current as resources are added. They contain only the list items, so the list itself is opened and closed around them.

```
{% raw %}{% include ul-open.xhtml %}
{% include list-simple-profiles.xhtml %}
{% include ul-close.xhtml %}{% endraw %}
```

{% include ul-open.xhtml %}
{% include list-simple-profiles.xhtml %}
{% include ul-close.xhtml %}

### Note boxes

The base templates style a few kinds of boxes. A `div` needs `markdown="1"` for Markdown inside it to be rendered.

```
<div class="stu-note" markdown="1">
**Trial use:** this part may change based on feedback.
</div>
```

<div class="stu-note" markdown="1">
**Trial use:** this part may change based on feedback.
</div>

### Authoring tips

#### Stable anchors {#stable-anchors}

Every heading gets an anchor made from its text, so it changes when the heading is reworded or translated. Give a heading a fixed one with `{#id}`, and a paragraph, list or table with `{: #id}` on the line after it:

```
### Searching {#search}

A paragraph other pages can link to.
{: #search-rule}
```

This heading has one: [link to it](#stable-anchors). Ids must be unique on a page.

#### Notes only authors see

{% comment %}
This note is in the page source but not in the published page.
{% endcomment %}

```
{% raw %}{% comment %}
TODO: align with the search page.
{% endcomment %}{% endraw %}
```

Liquid drops the block before the page is built. An HTML comment `<!-- … -->` would still be readable in the page source.

#### Liquid pitfalls

- Liquid runs before Markdown, also inside code blocks. To show Liquid code, wrap it in `raw` … `endraw`, as this page does.
- Tags inside a `comment` block are still parsed: a broken tag there stops the build, too.
- A Liquid error stops the whole Jekyll run. Look for `Liquid Exception` in the build log.

### Further reading

The [IG Guidance](https://build.fhir.org/ig/FHIR/ig-guidance/) describes these features and more: SQL queries over the IG's resources, UML and PlantUML diagrams, multi-language IGs, and the IG parameters.
