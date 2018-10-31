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
color: "#2A2E43"
image: "/assets/img/pattern-1.png"
category: "storytime"
excerpt: "Discover the history of the tech stack behind your favourite tutorials site!"
---

If you’re a regular [raywenderlich.com](https://www.raywenderlich.com) reader you may have noticed that, earlier this year, the site relaunched with a major facelift. This was designed to make content easier to find, to offer a more pleasant experience when reading articles and watching videos, and to give Android the rightful home that it deserved. We’re still working hard on this mission—with new features like bookmarking, improved search and email management on their way.

This relaunch was more than just a lick of paint and a new [/android](https://www.raywenderlich.com/android) page. It represents the culmination of months of work rearchitecting the site with a view to the future, whilst both maintaining the flow of great content from our teams, and attempting to keep the disruption and burden of extra work to a minimum.

How did we do it? Well, funny you should ask, this post is a high-level review of the architecture and systems we use to bring [raywenderlich.com](https://www.raywenderlich.com) to you in its current form.


## A bit of history

Ray, who is indeed a real person, despite what the conspiracy theorists might have you believe, started the site nearly 9 years ago—as a simple blog. He chose the best tool for starting a blog—WordPress, and that served all the content you saw on the site right up until August of this year. It underwent many changes, with custom plugins and functionality built to support the book store, video subscriptions, the tutorial team etc, but it was still, at its core, WordPress.

[PIC OF WORDPRESS MONOLITH]

Back in 2016, we decided that if we wanted to start adding extra functionality to the site then we needed to bite the bullet and step away from WordPress—our needs as a learning platform had started to push the limits of what blogging software could offer.

At the time, this was a major undertaking—every aspect of the site was fully ingrained within WordPress, so we started small—with the forums.

## A 2-year plan

OK, so it wasn’t planned as a 2-year project, but the aim throughout the first 18 months of the work was always to _“just let WordPress do what WordPress is good at”_. It shouldn’t be running our forums, user account system, store, video subscriptions etc. It should be used for writing, editing and publishing content.

Removing the forums and user account system was a major piece of work, which was designed to setup our infrastructure for future work. The forums are now hosted in discourse, which is not only a world-leading discussion platform, but also requires very little overhead from our engineering team. It sits in a docker container on a server on its own, with point and click upgrades every now and then. The only custom work we had to do was to build a plugin to support the [raywenderlich.com](https://www.raywenderlich.com/) accounts system.

[PIC OF UPDATED ARCHITECTURE]

This first phase was a much bigger undertaking than we expected. At this stage we didn’t have a dedicated engineering team—it was work that Mic, Brian and did, alongside creating books and video content. Combining this with the huge amount of platform research required and the complexity of migration, we spent a long time working on this.

The next step to re-WordPressing WordPress was to pull out all video subscriber content into its own service—codenamed _betamax_.

## _betamax_—the Future of Video

Although there were several candidates for our next project, we settled on improving the experience for video subscribers primarily because it was severly lacking. Prior to _betamax_, each video within a course was a vimeo embed hosted within a WordPress post. Manually created, and with no modelling of the relationship between videos. This led not only to a mediocre user experience, but also a miserable admin experience.

This was our first completely custom-built product, and as such we had the much heralded blank-canvas. Due to previous expertise, we settled on using [Ruby on Rails](https://rubyonrails.org) as the web framework, and decided that all development and deployment should be done through docker containers.

## But Rails Doesn’t Scale

Ah yes—the all-too-popular lazy lament of the self-proclaimed expert. There is a shard of truth in this sentiment—Ruby is not an especially runtime-efficient language. However, for a site of our size, it more than makes up for that in its expressiveness and write-time efficiency. If it were a problem, then hardware is far cheaper than developers—it’s not expensive to throw more compute power at a problem.

I appreciate that I’m being a little facetious here. The key thing is that at our size and traffic (and for the vast majority of sites on the internet) we’re keen to prioritise efficiency of feature development over runtime speed.

Due to the dockerised way in which we deploy our rails apps, none of them contains any state (other than short-term caches). This means that it’s easy for us to spin up additional containers behind a load-balancer. In fact, the raywenderlich.com is currently running from two app containers load-balanced by an nginx reverse proxy. If we were to reach a CPU bound capacity issue then we could easy add extra containers, in a matter of minutes.

## Adventures with Docker

If you’ve not heard of [Docker](https://www.docker.com) (a sexy marketing name for the more generic “containerisation” paradigm) then you can think of it as a lightweight virtual machine—essentially allowing you to completely codify the OS and dependencies required to run your application, and then to spin it up anywhere. If you have heard of Docker then you’ll know it is absolutely not a virtual machine, and should not be treated as such. However, I think it is a valuable mental model to consider when discovering it.

What does this mean? Well, the environment you run the app in on your development machine is identical to the environment in production. Identical. Same OS, same libraries, same dependencies. This has several positive side effects:

- Fewer “well, it worked on my machine” moments
- Spinning up a new dev environment is trivial, and independent of your host OS—install docker, checkout the code, and run `docker-compose up`. You’re done.
- It’s easy to maintain multiple, slightly different environments. Just because we have a legacy app that requires old versions of OS libs, that doesn’t mean that all our new apps have to have the same dependencies.
- Spinning up a new production machine is also really easy—essentially the same process as a development machine.

One of the key things about docker is that you should make your apps as stateless as possible. It’s possible to create independent volumes for data storage, but we decided to take the approach of using managed services for our storage requirements within _betamax_. Since we were already using EC2 on AWS as hosting compute power, it was natural to use [RDS](https://aws.amazon.com/rds/) (Relational Database Service) as a managed database solution, [S3](https://aws.amazon.com/s3/) (Simple Storage Servce) for file storage and [ElastiCache](https://aws.amazon.com/elasticache/) for Redis. The priority here is very much to let our engineering team focus on development, and not managing backup rotation and storage for our datastores.

Anyway, this was a steep learning curve for us, but it has paid off many times over. I would definitely recommend investigating this approach for any server-side work you are considering.

[IMAGE OF _betamax_]


## Payments—not as easy as you’d hope

Once we’d completed and deployed the first version of _betamax_, we turned our attention to the next major piece for raywenderlich.com—the store. Continuing the same approach of pulling stuff out of WordPress, we rolled a new app (_kerching_) following the same Rails / Docker / AWS approach as before.

One of the key things we wanted to achieve with the store relaunch was to reduce the friction in actually making a purchase. Our previous payment process required over 12 clicks to complete a purchase, and we knew we could do better.

As we started planning this, I definitely had [Stripe](https://stripe.com/) in my head—I’d read about it and had seen how easy it was to integrate—this was going to be great project.

Turns out, online purchasing is more complex than just taking money. The multitude of tax laws across the world make sure of that. Sales tax in the US depends on both the location of the seller and the buyer. In the EU it depends solely on the location of the buyer, and international sellers still have to charge VAT, which differs dependent on the country within the EU. During this time, I learnt far more than I ever wanted to know about VAT and sales taxes, before concluding that doing this ourselves was just asking for trouble. It would have added not only a huge development overhead (now and ongoing maintenance) but also additional challenges from an accountancy perspective.

That struck my favourite option from the list—cheerio Stripe.

Luckily there are payment providers who can handle this for you, by acting as a reseller. This also meant that we vastly reduced the number of providers available to us. To three.

After costings analysis, and technical proofs-of-concept we settled on our current provider, [Paddle](https://www.paddle.com/), who offer a great checkout flow, and handle all the gnarly taxation issues for us.

Paddle is based in the UK, which is actually a huge advantage for our US-based customers, since sales tax in the US in not payable on international transactions. They were also open to importing our existing subscribers from our previous payment provider—a process of securely transferring payment details, following a standardised process. However, our previous payment provider (FastSpring) were unable or unwilling to facilitate this, resulting in yet more development challenges.

Instead of building a nice, new payments pipeline, we instead to build two separate ones, and provide a simple user flow for users to switch from our old payment provider to the new one by entering their credit card, at a time that suited them. If they chose not to (and to this day, lots of users haven't) then their existing subscription would continue on the old payment provider.

[IMAGE OF _kerching_]

Despite the fact that we now had an almost-full-time engineering team of two developers and one designer, these additional complications meant that this, once again, took longer than we hoped. However, once it was finished, our checkout flow was much improved, and we immediately saw an improvement in conversion rate.

## Bringing us up to date

By this stage WordPress was pretty much just doing what WordPress does—writing, editing, storing and serving content. We'd also taken the time to dockerise it, and move both the app and the database over to AWS, relieving us of expensive old hardware, and bringing deployment inline with our other products—via out chatbot razebot. Razebot is a [hubot](https://hubot.github.com)-based slackbot who facilitates a range of actions, including managing access to our staging infrastructure, uploading static assets to our CDN and deployment of our web apps.

We were now in a position to take a look at the WordPress site itself—we really wanted to add extra features, and to revamp the appearance. This left us with three options:

1. Work out how to add the required functionality to WordPress and develop an updated theme.
2. Replace WordPress with a custom written app, based on our successful development approach.
3. Come up with some kind of hybrid.

None of us had a huge amount of pleasurable experience of working in PHP, and given that we’d focused on removing cruft from our WordPress install, option 1 wasn’t that appealing. Option 2 would involve building a CMS, something that might seem like it’ll be easy, but rarely is. Much as people might dislike WordPress, it’s perfectly good at content creation, metadata editing, file upload, version management and publication. We therefore hatched a plan based on option 3—the beginning of _carolus_—the [raywenderlich.com](https://www.raywenderlich.com/) you see today.


## JavaScript Framework of the week

We knew that the backend of _carolus_ would be written in rails—not only did we want to stick to the platform decisions we'd already made, but we'd also just employed Roel as a senior rails engineer, so it'd be odd to switch that choice now. Roel's joining the team took us to a full-time engineering team of three—two developers and a designer.

The frontend, however, was up for grabs. 

It was really important to us that we made significant improvements in the user experience for users as they seek, browse, read and watch. Inevitably, this involved investing in a JavaScript framework. In the previous incarnations of the site, we’d fallen into the comfortable pit of despair that is jQuery. However, we were keen to investigate alternatives, and to settle on something that we actually enjoyed working with.

After much reading and fiddling, we decided we’d give [Vue.js](https://vuejs.org/) a try. At the time it was a fairly popular JavaScript view-layer framework, with a passing resemblance to react.js. Its use has since exploded, presumably as a direct consequence of our adoption?

Before developing the front-end of _carolus_, we decided we wanted a testbed for our chosen approach, and did so with _guardpost_ ([accounts.raywenderlich.com](https://accounts.raywenderlich.com/)). This is a single-page app (SPA) written entirely in Vue.js, using the backend rails API to handle data mutations. This seemed like a great approach, and to an extent it was. However, we found very quickly that we were duplicating logic in both the frontend and backend. Coupled with the fact that we didn’t necessarily need the power of Vue.js on every single view led us to taking a hybrid approach in _carolus_.

Rails has a great view templating system in ActionView. It makes pulling content out of data models and displaying it as part of HTML a breeze. We therefore decided that for the majority of the content on pages, we’d render it using rails. Then, for individual components we’d build a Vue.js app, and mount it once the rails content had rendered. This gave us the best of both worlds, and given the first-class support webpack has in rails now (via the [webpacker](https://github.com/rails/webpacker) gem) is likely to be a popular approach for new apps in the future.

## Content Aggregation

The architecture of [raywenderlich.com](https://www.raywenderlich.com/) today can be summarised as follows:

[PIC]
￼
This model continues to use both _betamax_ and WordPress (_koenig_ in our handy naming system) as the canonical datastores. Content creators, team leads and editors still use these two systems to create records for the content created—ensuring that the content production workflow required minimal changes. These two systems maintain their databases of content, handle asset uploads and everything they’ve always done. Apart from presentation. That responsibility is instead transferred to _carolus_.

_carolus_ is a rails app, following the same model as _kerching_ and _betamax_. It has a generic model of what content is, and keeps a cache of all content from _betamax_ and _koenig_ in its own database. When new content is created, or existing content is updated, a notification is broadcast on _megaphone_, our internal message bus (running on AWS [SNS](https://aws.amazon.com/sns/)). _carolus_ subscribes to these notifications, and then makes the appropriate API request to obtain the latest version of the content from the appropriate service.

Taking this approach meant that although our WordPress theme still has custom code to support enhancements to the WordPress API, additional meta data fields for authors to fill out in the admin interface, and the _megaphone_ broadcast notifications, these changes are relatively minor, and still fit the WordPress data model well. We continue to run WordPress in a docker container, (behind a varnish cache, for, well, reasons) with the appropriate admin endpoints proxied by _carolus_. This ensures that the disruption to raywenderlich.com team members experience minimal disruption to their workflow.


## The future

In the short term we’ve got various user-facing features across the site that we’re working on. Some are things that didn’t make it into the v1 launch of _carolus_, others are in direct response to user feedback.

Further afield, we’ve got infrastructure improvements we’d like to investigate, e.g. transitioning from running individual servers to using a container deployment service such as [kubernetes](https://kubernetes.io). Naturally this is alongside the other major features, improvements and services we’re working on to improve [raywenderlich.com](https://www.raywenderlich.com/).

## Conclusion

It’s at this point in blog posts like this you discover the underlying reason for its existence: _“if this kind of thing interests you, why not come and join us—we’re hiring”_. Sadly we’re not currently quite in that position. We have big plans for the future of the site, and will need to expand the engineering team to achieve them, but that’s coming soon.

Our engineering team is tiny—Luke is our fantastic designer, Roel a top-notch full-stack developer, and me. I’m really proud of what the team has achieved over a fairly short amount of time, and what we’re looking to accomplish in the future. It’s our aim to make the great content created by the hugely talented team of authors as accessible and enjoyable as possible. I hope you agree that the recent improvements have been a step in the right direction, and that we’ll do this mission justice in the future.
