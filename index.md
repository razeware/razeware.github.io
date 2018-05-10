---
layout: default
---

<main class="c-home-carousel">
    <div class="c-home-carousel-left">
        <div class="c-home-carousel-left-text-wrapper">
            {% for post in site.posts limit:5 %}
              <div class="c-home-carousel-text"> 
                  <h2><a href="{{ post.url | relative_url }}"><span>{{ post.title | escape }}</span></a><span class="c-home-carousel-text-category">CSS</span></h2>
                  <div class="c-home-carousel-text-author">
                      <span>Written by</span>
                      <span>{{ post.author }}, {{ post.date | date: '%B %d, %Y' }}</span>
                  </div>
              </div>
            {% endfor %}
        </div>
    </div>
    <div class="c-home-carousel-right">
        <div class="c-home-carousel-right-image-wrapper">
            {% for post in site.posts limit:5 %}
              <div class="c-home-carousel-right-image" style="background:{{ post.color }};">
                  <a href="{{ post.url | relative_url }}"><img src="/assets/img/{{ post.image }}.png"></a>
              </div>
            {% endfor %}
        </div>
    </div>
</main>

{% include quote.html %}

<script type="text/javascript">

  const textCarousel = {
      className : 'c-home-carousel-text',
      fullClassName : '.c-home-carousel-text',
      translateA : -100,
      translateB : 0,
      wrapper: '.c-home-carousel-left-text-wrapper'
  }

  const imageCarousel = {
      className : 'c-home-carousel-right-image',
      fullClassName : '.c-home-carousel-right-image',
      translateA : 100,
      translateB : 0,
      wrapper: '.c-home-carousel-right-image-wrapper'
  }

  function loopCarouselNodes(x){
      let textContainer = document.querySelector(x.wrapper);
      let elem = document.createElement('div');
      elem.setAttribute("class", x.className );
      let textNode = textContainer.firstElementChild;
      let textNodeInner = textContainer.firstElementChild.innerHTML;
      textContainer.appendChild(elem);
      elem.innerHTML = textNodeInner;

      setTimeout(function(){
          textContainer.removeChild(textNode);
      }, 2000)
  }

  function translateCarouselNodes(carouselObject){ 
      let textCarouselNodes = document.querySelectorAll(carouselObject.fullClassName);
      textCarouselNodes[0].style.transform = "translateY(" + carouselObject.translateA + "%)";
      textCarouselNodes[1].style.transform = "translateY(" + carouselObject.translateB + "%)";
      loopCarouselNodes(carouselObject);
  }

   setInterval(function(){
      translateCarouselNodes(textCarousel);
      translateCarouselNodes(imageCarousel);
   }, 5000);

</script>
