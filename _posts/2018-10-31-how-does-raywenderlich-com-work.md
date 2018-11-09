---
layout: post
logo: "--white"
header_style: "c-header--white"
title: "How does raywenderlich.com work?"
date: "Oct 31, 2018"
author: "Sam Davies"
author_role: "CTO Razeware"
author_bio: "Writing code, solving problems and entertaining the masses"
author_image: "sam-davies@2x.png"
color: "#283962"
image: "/assets/img/pattern-3@2x.png"
category: "storytime"
excerpt: "Discover the history of the tech stack behind your favourite tutorials site!"
---

If you’re a regular visitor to [raywenderlich.com](https://www.raywenderlich.com), you may have noticed that the site relaunched with a major facelift earlier this year. The goal of this facelift was to make content easier to find, to offer a more pleasant experience when reading articles and watching videos, and to give Android the rightful home that it deserved. We’re still working hard on this mission, with new features like bookmarking, improved search and email management on their way.

But this relaunch involved a lot more than just a lick of paint and a new [/android](https://www.raywenderlich.com/android) page. It represents the culmination of months of work rearchitecting the site with a view to the future, while both maintaining the flow of great content from our teams, and attempting to keep the disruption and burden of extra work to a minimum.

How did we do it? Well, funny you should ask; this post is a high-level review of the architecture and systems we use to bring [raywenderlich.com](https://www.raywenderlich.com) to you in its current form.

## A Bit of History

Ray, who is indeed a real person, despite what the conspiracy theorists might have you believe, started the site nearly 9 years ago as a simple blog. He chose the best platform for starting a blog — WordPress — and that has served up all the content on the site right up until August of this year. The WordPress-powered site has undergone many changes, with custom plugins and functionality built to support the book store, video subscriptions, the tutorial team and more. Still, at its core, it remained WordPress, with all of its good and not-so-good features.

![](assets/img/2018-10-31/how_does_rw_work_01.png)

In 2016, our needs as a learning platform had started to push the limits of what blogging software could offer. We knew that to support all the great site features we wanted would mean biting the bullet and stepping away from WordPress. 

This presented us with a fairly challenging migration path. Every aspect of the site was fully ingrained within WordPress, so we found a small task to start: the forums.

## A Two-Year Plan

OK, so it wasn’t planned to be a two-year project, but is any project, really? 

Our overarching goal during the first 18 months of effort was always to _“let WordPress do what WordPress is good at”_. WordPress shouldn’t be running our forums, user account system, store, video subscriptions, or other backend support. Instead, we feel the core WordPress platform of the site should be reserved for writing, editing and publishing content.

Removing the forums and user account system was a major piece of work, which was designed to lay down some infrastructure foundations for future work. The forums are now hosted in [discourse](https://discourse.org/), which is not only a world-leading discussion platform, but also one that requires very little overhead from our engineering team. Discourse sits in a Docker container on a server on its own, which requires little more than point-and-click upgrades every now and then. The only custom work we had to do was to build a plugin to support the [raywenderlich.com](https://www.raywenderlich.com/) accounts system.

![](assets/img/2018-10-31/how_does_rw_work_02.png)

This first phase was a much bigger undertaking than we expected. At this stage, we didn’t have a dedicated engineering team: it was work that Mic, Brian and I took up alongside our other work of creating books and video content. Combining this with the huge amount of platform research that was required, and the complexity of migrating a fairly complex system, we spent a long time working on this. Longer than we thought we would, for sure.

But once the forums were taken care of, we needed to decide upon the next step in our WordPress diet plan. The next step was to pull out all video subscriber content into its own service, codenamed _betamax_.

## _betamax_ — the Future of Video

Although there were several candidates for our next project, we settled on improving the experience for video subscribers primarily because the user experience was, from our standpoint, quite lacking. Prior to _betamax_, each video within a course was a vimeo embed hosted within a WordPress post. Each one was created manually, and there was no modelling of relationships between videos. This led not only to a mediocre user experience, but also a miserable admin experience.

This was our first completely custom-built product, and as such we had the much-heralded blank canvas. Due to previous expertise within our team, we settled on using [Ruby on Rails](https://rubyonrails.org) as the web framework, and decided that all development and deployment should be done through Docker containers.

## But Rails Doesn’t Scale!

Ah yes! It’s the all-too-popular lazy lament of the self-proclaimed expert. There _is_ a shard of truth in this sentiment, however. Admittedly, Ruby is not an especially runtime-efficient language. However, for a site of the size of raywenderlich.com, Ruby more than makes up for that in its expressiveness and write-time efficiency. If the inefficiencies of Ruby were to become a problem, then we always have the option of ramping up our hardware. It’s not expensive to throw more compute power at a problem, and hardware is usually far cheaper than developers.

I appreciate that I’m being a little facetious here. The key thing is that for our current size and traffic load (and for the vast majority of sites on the internet), we’re keen to prioritize efficiency of feature development over runtime speed.

Due to the dockerized way in which we deploy our rails apps, no app contains any real state, other than short-term caches. This means that it’s easy for us to spin up additional containers behind a load-balancer. In fact, raywenderlich.com is currently running from two app containers load-balanced by an nginx reverse proxy. If we were to hit a CPU-bound capacity issue, then we could easily add extra containers behind that balancer in a matter of minutes.

## Adventures with Docker

If you’ve not heard of [Docker](https://www.docker.com) (a sexy marketing name for the more generic “containerisation” paradigm) then you can think of it as a lightweight virtual machine that essentially allows you to completely codify the OS and dependencies required to run your application, and spin that environment up anywhere. If you have heard of Docker, then you’ll know it is absolutely not a virtual machine, and should not be treated as such. However, I think it is a valuable mental model to consider when exploring the varied uses of Docker.

What does this mean for developers? Well, the environment you run the app in on your development machine is identical to the environment in production. And I mean _identical_. Same OS, same libraries, same dependencies. This has several positive side effects:

- Fewer “well, it worked on my machine” moments
- Spinning up a new dev environment is trivial, and independent of your host OS. You simply install Docker, check out the code, and run `docker-compose up`. You’re done.
- It’s trivial to maintain multiple, slightly different environments. Just because we have a legacy app that requires old versions of OS libs, doesn’t mean that all our new apps have to have the same dependencies.
- Spinning up a new production machine is also really easy. It’s essentially the same process as you would follow to spin up a development machine.

One of the key elements to a successful Docker containerization stragegy is to make your apps as stateless as possible. You can create independent volumes for data storage, but we decided to take the approach of using managed services for our storage requirements within _betamax_. Since we were already using EC2 on AWS as hosting compute power, it was natural to use [RDS](https://aws.amazon.com/rds/) (Relational Database Service) as a managed database solution, [S3](https://aws.amazon.com/s3/) (Simple Storage Servce) for file storage and [ElastiCache](https://aws.amazon.com/elasticache/) for Redis. The priority here is very much to let our engineering team focus on development, and not spend time managing backup rotation and storage for our datastores.

This containerization strategy was a steep learning curve for us, for sure. However, the up-front time and effort to get this approach working has paid off many, many times over. I would definitely recommend investigating this approach for any server-side work you are considering.

![](assets/img/2018-10-31/how_does_rw_work_03.png)


## Payments — Not as Easy as You’d Think

Once we’d completed and deployed the first version of _betamax_, we turned our attention to the next major piece for raywenderlich.com — our store. Continuing the same approach of slimming down WordPress, we rolled a new app, _kerching_, following the same Rails–Docker–AWS approach as before.

One of our goals in redesigning the store was to reduce the friction in the purchase flow. Our previous payment process required over 12 (_12!_) clicks to complete a purchase, and we knew we could do better.

As we started planning this, I definitely had [Stripe](https://stripe.com/) in the back of my head as a contender for payment processing. I’d read about Stripe and had seen how easy it was to integrate. Why would I consider any other platform? This was going to be _great_.

It turns out that online purchasing is bit more complex than just taking your customer’s money. The multitude of tax laws across the world make sure of that. Sales tax in the US depends on both the locations of the seller and the buyer. In the EU, taxation rules depend solely on the location of the buyer; therefore, international sellers still have to charge VAT, which itself differs depending on what country you’re within the EU. Fun times.

One upside, I suppose, is that I learned far more than I ever wanted to know about VAT and sales taxes, before I concluded that managing tax requirements ourselves was simply asking for trouble. This would have not only added a huge development overhead (plus ongoing maintenance), but also added additional challenges from an accountancy perspective.

That struck my favourite option from the list. _Arrivederci_, Stripe.

Fortunately, there are payment providers who can handle the tax side of things for you, by acting as a reseller. This also meant that we vastly reduced the number of providers available to us — to three.

After doing some cost analysis, and spinning up some technical proofs-of-concept, we settled on our current provider, [Paddle](https://www.paddle.com/). They offer a great checkout flow, and handle all the gnarly international taxation issues for us.

Paddle is based in the UK, which is a huge advantage for our US-based customers, since sales tax in the US in not payable on international transactions. Paddle was also open to importing our existing subscribers from our previous payment provider, involving securely transferring payment details via a standardised process. However, our previous payment provider (FastSpring) was unable or unwilling to facilitate this, which resulted in yet more development and customer-care challenges.

Instead of building a nice, new payment pipeline, we instead were forced to build two separate pipelines, and provide a simple user flow for users to switch from our old payment provider to the new one by entering their credit card, at a time that suited them. If customers chose not to switch (and over a year later, many users still haven’t chosen to migrate) then their existing subscription would continue on the old payment provider.

![](assets/img/2018-10-31/how_does_rw_work_04.png)

Despite the fact that we now had two part-time developers and one designer, these additional complications meant that this, once again, took longer than we hoped. However, once it was finished, our checkout flow was much improved, and we immediately saw an improvement in conversion rate.

## Bringing Us Up to Date

At this point, WordPress was pretty much just doing what WordPress does best: writing, editing, storing and serving content. We'd also taken the time to dockerize WordPress; we moved both the app and the database over to AWS to relieve us of expensive old hardware and to bring deployment inline with our other products, via our chatbot, Razebot. 

Razebot is a [hubot](https://hubot.github.com)-based slackbot that facilitates a range of actions, including managing access to our staging infrastructure, uploading static assets to our CDN and deployment of our web apps.

We were now in a position to take a look at the WordPress installation itself. We really wanted to add new features, as mentioned in the outset of this article, and we also wanted to revamp the front-end appearance.

This left us with three options:

1. Work out how to add the required functionality to WordPress and develop an updated theme.
2. Replace WordPress with a custom written app, based on our successful development approach.
3. Come up with some kind of hybrid.

None of us had a huge amount of pleasurable experience of working in PHP, and given that we’d already focused on removing a ton of cruft from our WordPress installation, Option 1 wasn’t that appealing. Option 2 would involve building a CMS, something that might seem like it’ll be easy, but rarely is.

Much as people might dislike WordPress, it’s perfectly good at content creation, metadata editing, file upload, version management and publication. We therefore hatched a plan based on Option 3 — the beginning of _carolus_; the [raywenderlich.com](https://www.raywenderlich.com/) you see today.


## JavaScript Framework of the Week

We knew that the backend of _carolus_ would be written in Rails; not only did we want to stick to the platform decisions we'd already made, but we'd also just employed Roel as a senior Rails engineer, so it'd be odd to switch things up now. Adding Roel to the team took us to a full-time engineering team of three: two full-time developers and a designer.

The frontend, however, was up for grabs. 

We wanted to vastly improve the user experience as readers searched for and browsed both written and video content. Inevitably, this involved investing in a JavaScript framework. But which one?

In the previous incarnations of the site, we’d fallen into the comfortable pit of despair that is jQuery. However, we were keen to investigate alternatives, and also to settle on something that we actually enjoyed working with.

After much reading and fiddling, we decided we’d give [Vue.js](https://vuejs.org/) a try. At the time, it was a fairly popular JavaScript view-layer framework, with a passing resemblance to react.js. Its use has since exploded (presumably as a direct consequence of our adoption?).

Before developing the front-end of _carolus_, we decided we needed a testbed for our chosen approach, and did so with _guardpost_ ([accounts.raywenderlich.com](https://accounts.raywenderlich.com/)). This is a single-page app (SPA) written entirely in Vue.js, using the backend Rails API to handle data mutations. This seemed like a great approach, and to some extent, it was.

However, we found very quickly that we were duplicating logic in both the frontend and the backend. Coupled with the fact that we didn’t necessarily need the power of Vue.js on _every_ single view, we eventually took a hybrid approach in _carolus_.

Rails has a great view templating system in ActionView. It makes pulling content out of data models and displaying it as part of HTML a breeze. We decided that for the majority of the content on pages, we’d render it using Rails. Then, for individual components we’d build a Vue.js app, and mount it once the Rails content had rendered.

This choice gave us the best of both worlds, and along with the first-class support for webpack in Rails (via the [webpacker](https://github.com/rails/webpacker) gem), this is likely to be a popular approach for new apps in the future.

## Content Aggregation

The architecture of [raywenderlich.com](https://www.raywenderlich.com/) today can be summarized as follows:

![](assets/img/2018-10-31/how_does_rw_work_05.png)
￼
This model continues to use both _betamax_ and WordPress (known as _koenig_ in our handy naming system) as the canonical datastores. Content creators, team leads and editors still use these two systems to create records for the content created, ensuring that the content production workflow requires minimal changes. These two systems maintain their databases of content, handle asset uploads and do everything they’ve always done — apart from presentation. That responsibility is instead transferred to _carolus_.

_carolus_ is a Rails app, following the same model as _kerching_ and _betamax_. It has a generic model of content, and keeps a cache of all content from _betamax_ and _koenig_ in its own database. When new content is created, or existing content is updated, a notification is broadcast on _megaphone_, our internal message bus (running on AWS [SNS](https://aws.amazon.com/sns/)). _carolus_ subscribes to these notifications, and then makes the appropriate API request to obtain the latest version of the content from the appropriate service.

Taking this approach meant that although our WordPress theme still requires custom code to support enhancements to the WordPress API, additional metadata fields for authors to fill out in the admin interface, and the _megaphone_ broadcast notifications, these changes are relatively minor, and still fit the WordPress data model well. We continue to run WordPress in a Docker container behind a varnish cache, for, well, _reasons_, with the appropriate admin endpoints proxied by _carolus_. This ensures that raywenderlich.com team members experience minimal disruption to their workflow.

## The Future

So that brings us to today. While we could rest easy, content in knowing that we are far better off now than we were two years ago, there’s still a lot to do.

In the short term, we’ve got various user-facing features across the site that we’re working on. Some of these are things that didn’t make it into the v1 launch of _carolus_, others are in direct response to user feedback on v1 of the site.

Further afield, we’ve got infrastructure improvements we’d like to investigate, such as transitioning from running individual servers to using a container deployment service such as [kubernetes](https://kubernetes.io). Naturally this is alongside the other major features, improvements and services we’re working on to improve [raywenderlich.com](https://www.raywenderlich.com/).

## Conclusion

It’s at this point in blog posts like this you discover the underlying reason for its existence: _“if this kind of thing interests you, why not come and join us—we’re hiring”_. Sadly we’re not currently quite in that position. We have big plans for the future of the site, and will need to expand the engineering team to achieve them, but that’s coming soon.

Our engineering team is tiny—Luke is our fantastic designer, Roel a top-notch full-stack developer, and me. I’m really proud of what the team has achieved over a fairly short amount of time, and what we’re looking to accomplish in the future. It’s our aim to make the great content created by the hugely talented team of authors as accessible and enjoyable as possible. I hope you agree that the recent improvements have been a step in the right direction, and that we’ll do this mission justice in the future.