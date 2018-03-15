---
layout: page
title: Posts
permalink: /posts/
---

{% if site.posts.size > 0 %}
  <ul>
    {% for post in site.posts %}
    <li>
      {% assign date_format = site.minima.date_format | default: "%b %-d, %Y" %}
      <h3>
        <a href="{{ post.url | relative_url }}">
          {{ post.title | escape }}
        </a>
      </h3>
      {% if site.show_excerpts %}
        {{ post.excerpt }}
      {% endif %}
    </li>
    {% endfor %}
  </ul>
{% endif %}
