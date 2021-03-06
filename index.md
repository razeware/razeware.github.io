---
layout: default
permalink: /
logo: "--white"
---

<main class="c-home-carousel">
    <div class="c-home-carousel-left">
        <div class="c-home-carousel-left-text-wrapper">
            {% for post in site.posts limit:5 %}
              <div class="c-home-carousel-text"> 
                  <h2><a href="{{ post.url | relative_url }}"><span>{{ post.title | escape }}</span></a><span class="c-home-carousel-text-category">{{ post.category }}</span></h2>
                  <div class="c-home-carousel-text-author">
                      <span>[ {{ post.date | date: '%B %d, %Y' }} · {{ post.author }} ]</span>
                  </div>
              </div>
            {% endfor %}
        </div>
        <span class="c-home-carousel__paginator">
          <span class="c-home-carousel__paginator-page">1</span> of <span class="c-home-carousel__paginator-total">5</span>
        </span>
    </div>
    <div class="c-home-carousel-right">
        <div class="c-home-carousel-right-image-wrapper">
            {% for post in site.posts limit:5 %}
              <div class="c-home-carousel-right-image" style="background:{{ post.color }};">
                  <a href="{{ post.url | relative_url }}"><img src="{{ post.image }}"></a>
              </div>
            {% endfor %}
        </div>
    </div>
</main>

{% include quote.html %}

<script type="text/javascript">

  //Use objects to set common data for the left and right slides of the carousel
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

  //If carousel link is hovered pause it
  let runCarousel = true;

  function getCarouselLinks(){
    let carouselLinks = document.querySelectorAll('.c-home-carousel-text a');

    carouselLinks.forEach(function(link){
      link.addEventListener('mouseover', function(e){
        runCarousel = false;
      })
      link.addEventListener('mouseout', function(e){
        runCarousel = true;
      })
    });

  }

  getCarouselLinks();

  //Function to queue a carousel slide after it's been translated out of view
  function loopCarouselNodes(x){
      let textContainer = document.querySelector(x.wrapper);
      let elem = document.createElement('div');
      elem.setAttribute("class", x.className );
      let textNode = textContainer.firstElementChild;
      let textNodeInner = textContainer.firstElementChild.innerHTML;
      let textBg = window.getComputedStyle(textNode, null).getPropertyValue('background-color');
      textContainer.appendChild(elem);
      //Get background color
      elem.style.backgroundColor = textBg;
      elem.innerHTML = textNodeInner;

      setTimeout(function(){
          textContainer.removeChild(textNode);
      }, 2000)
  }

  //Function to translate the carousel slides
  function translateCarouselNodes(carouselObject){ 
      getCarouselLinks();
      let textCarouselNodes = document.querySelectorAll(carouselObject.fullClassName);

      //If there's more than 1 slide change activate the carousel
      if(textCarouselNodes.length > 1 && runCarousel){
        textCarouselNodes[0].style.transform = "translateY(" + carouselObject.translateA + "%)";
        textCarouselNodes[0].style.transition = "all 1.5s cubic-bezier(0.68, -0.55, 0.265, 1.55)";
        textCarouselNodes[0].style.opacity = "0";
        textCarouselNodes[1].style.transform = "translateY(" + carouselObject.translateB + "%)";
        textCarouselNodes[1].style.opacity = "1";
        textCarouselNodes[1].style.transition = "all 1.5s cubic-bezier(0.68, -0.55, 0.265, 1.55)";
        loopCarouselNodes(carouselObject);
      }
  }

  //Carousel paginator to update the current post on the carousel
  const numberOfSlides = document.querySelectorAll('.c-home-carousel-text');
  let currentPage = document.querySelector('.c-home-carousel__paginator-page');
  document.querySelector('.c-home-carousel__paginator-total').innerHTML = numberOfSlides.length;

  function updatePagination(){

    let count = 1;

    if(Number(currentPage.innerHTML) < numberOfSlides.length){
      count++;
      currentPage.innerHTML = count;
    }
    else{
      count = 0;
      currentPage.innerHTML =  1;
    }
    
  }

  //Change carousel slides every 5 seconds
   setInterval(function(){
      translateCarouselNodes(textCarousel);
      translateCarouselNodes(imageCarousel);
      updatePagination();
   }, 5000);

</script>
