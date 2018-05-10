---
layout: posts
title: "Posts"
permalink: /posts/
---

{% if site.posts.size > 0 %}
  {% for post in site.posts %}
  <div class="c-grid-blog-post">
    <a href="{{ post.url | relative_url }}">
        <div class="c-grid-blog-post-artwork" style="background:{{ post.color }};"><img src="/assets/img/{{ post.image }}.png"></div>
        <h2><span>{{ post.title | escape }}</span></h2>
        <span class="c-grid-blog-post-meta">{{ post.date | date: '%B %d, %Y' }}  ·  <span>{{ post.category }}</span></span>
        </a>
  </div>  
  {% endfor %}
{% endif %} 
