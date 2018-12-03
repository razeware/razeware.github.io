---
layout: post
logo: "--white"
header_style: "c-header--white"
title: "Pub-Sub Messaging Made Easy"
date: "Nov 26, 2018"
author: "Roel Bondoc"
author_role: "Fullstack Developer Razeware"
author_bio: "Interests: Ruby on Rails, games, and basketball."
author_image: "roel-bondoc@2x.jpeg"
color: "#2A2E43"
image: "/assets/img/pattern-2@2x.png"
category: "development"
excerpt: "Some useful tidbits when implementing pub-sub messaging."
---

Razeware utilizes a microservice architecture that powers the raywenderlich.com website experience. This architecture pattern is a useful technique in building websites. Allowing you to separate concerns into their own service with the benefit of being able to independently build, scale, and deploy them individually. Because of this separation, there may be a need where your services still need to communicate with each other. One way to achieve this is through a pattern called PubSub messaging.

![](assets/img/2018-12-03/pubsub-1-system.png)

Publish/Subscribe messaging is the act of one service publishing data to a shared service, often called a "Message Bus". A subscriber maintains a connection to this shared Message Bus which will eventually receive published messages. In systems with a heavily utilized message bus, it is not uncommon to have multiple publishers publishing to multiple channels to be recieved by multiple subscribers.

### One, Two, Four, Three, Five

In the raywenderlich.com tech stack we have a separate service that manages our store, kerching, and another service that manages our video content, betamax. From a high level perspective, kerching would know which users had bought which video product. This required betamax to know which user would have access to a video when requested. The quickest and most efficient way to move this information accross was to broadcast a message on the bus when a user gained access to a product, as well as when they lose access. Each message was encoded with the users id, the product that was changed, and wether or not they have access. The subscriber, in this case betamax, would then read each message, and update its own internal database of users product access.

![](assets/img/2018-12-03/pubsub-2-synchronous.png)

While this worked out well for quite a while, we eventually started to receive complaints where some users were unable to access videos even though they were subscribed. This lead us to chase down message logs and piece together the state of a users access for each message that would alter their access. Eventually, investigations became very time consuming as we kept getting more users and the message bus became busier.

The most important thing we wanted to get right was to ensure our users had the correct access to their videos. With this being our primary goal, we decided to undo any message optimizations and instead aim for accuracy. We achieved this by limiting the amount of information sent in a message to just a simple notification that access had changed. With this notifcation, betamax now only knows that a users access has changed, but still doens't know what. This required betamax to make an API request to kerching to synchronize all product accesses.

![](assets/img/2018-12-03/pubsub-3-idempotent.png)

With this new setup, it doesn't matter what information or in what order betamax receives a message. The end result will always be the same. Fortunately betamax and kerching have a sizeable amount of traffic that can handle a few more API calls without having to scale unecessarily. This change not only decreased the amount of issues we received, but also made it far easier to debug when issues did arise.

### Leave your message and go!

The newest part of our tech stack is our content aggregation service, carolus. This is the main part of the website you see on a day to day basis. Now you are probably begging to know how does this site aggregate data from several other sources of information in such a seemless manner? Well, I'm glad you asked. We built carolus to subscribe to all content changes that goes on in our world of raywenderlich.com. As outlined in a previous post, we have different admin interfaces that generate our content which all eventually ends up in carolus.

When content is generated for the site, a notification is sent on our message bus with a unique identifier. The service subscriber, carolus, then reads these notifications. The unique identifer has information that tells carolus what admin service generated the content and how to look it up. At this point, carolus can then fetch the content using an API request.

Let's say for instance we naively setup our subscription event cycle like this:

![](assets/img/2018-12-03/pubsub-4-synchronous.png)

It is important to note that carolus currently runs off of 2 web processes with 5 threads each. These webprocesses handle everything from public users, admin users, and subscriber events. This means that if our processes are tied up, they will be unable to serve other requests.

Since we live in a micro services world, the availability of carolus shouldn't be dependent on the reliability of external factors, which include other services in our system. If carolus makes an API request to fetch data and for some reason the request takes a really long time, this can be bad. A tied up thread becomes your bottleneck. If an notification forces carolus to make a really long API request, compound this multiple times, you'll start losing the ability to handle actual user traffic.

To get around this, we opted to make use of another background processing technique in the form of a queue. In our case we use Sidekiq which is backed by Redis. Whenver carolus receives a content notification, the events controller queues up the notification into Redis and returns right away. This frees up process to handle a new request since now it is a Sidekiq process that makes an API request.

![](assets/img/2018-12-03/pubsub-5-queue.png)

We can now greatly increase the amount of notifications we can handle and allow us to serve real users without having to scale horizontally. Another added benefit of this is we can fine tune how many worker process we need and even scale it based on the load on the queue. This can all be done without affecting carolus' ability to serve our users.

Implementing a message bus is integral in properly organzing the flow of data in your microservices architecture. Just keep in mind that it is not a end all solution, but it can solve a lot of your problems when used carefully. If you want to learn more about our experiences or just want to chat, feel free to hit me up on Twitter!