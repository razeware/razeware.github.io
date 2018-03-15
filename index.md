---
layout: default
---

<div>
  {% assign post = site.posts.first %}
  <h1>
    <a href="{{ post.url | relative_url }}">
      {{ post.title | escape }}
    </a>
  </h1>
  <div>
    {{ post.excerpt }}
  </div>
</div>
