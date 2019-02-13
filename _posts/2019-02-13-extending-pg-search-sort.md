---
layout: post
logo: "--white"
header_style: "c-header--black"
title: "Extending sort capabilities of pg_search"
date: "Feb 13, 2019"
author: "Roel Bondoc"
author_role: "Fullstack Developer Razeware"
author_bio: "Interests: Ruby on Rails, games, and basketball."
author_image: "roel-bondoc@2x.jpeg"
color: "#ffcb32"
hero: "c-post-hero--dark"
image: "/assets/img/pattern-6@2x.png"
category: "development"
excerpt: "Adjusting the sort capabilities pg_search to provide better search results."
---

The search functionality of raywenderlich.com is powered by Postgresql using the `pg_search` ruby gem. Out of the box it is a fantastic library and makes building a search feature easy. Although, as easy as it was, we were quick to discover that our search results were not returning desired results. So I decided to take a closer look at how `pg_search` constructs its queries.

## The default sort
By default `pg_search` sorts results by a rank result of all the queried columns combined as a single value. In addition, you can set weights on each column so that certain columns will return a higher value than others. The configuration looks something like this:

```
class Content < ApplicationRecord
  include PgSearch
  pg_search_scope :search,
                  against: {
                    name: 'A',
                    description: 'B',
                    search_meta: 'C'
                  }
end
```

This allows relevant results with the `name` attribute to be ranked higher than those with results just in the `description` or `search_meta` fields. However, when put into practice, I found that some results were getting ranked higher even if the search term was not in the `name` field.

```
irb:> puts Content.search('firebase').limit(10).map(&:name)
Firebase Tutorial for Android: Getting Started
Text Recognition with ML Kit
Image Recognition With ML Kit
Firebase Tutorial: Getting Started
Firebase Tutorial: Real-time Chat
Firebase Remote Config Tutorial for iOS
Firebase Remote Config Tutorial for iOS
Firebase Tutorial: Real-time Chat
Firebase Tutorial: iOS A/B Testing
Firebase Tutorial: iOS A/B Testing
```

It turns out that if the search term appears enough times in the other fields, they can rank higher than expected. Because our content is comprised of various different types of data, we needed something a bit more customized than what the gem gives out of the box.

## The fix

What we needed was a way to sort results based on the presence of each attribute individually, with the rank value as the secondary order. Breaking this down, there are two components needed to fix this:
1. Getting individual match results for each column.
2. Sort the results based on the individual match results.
Unfortunately there is no easy way to extend the capabilities of `pg_search`, so my solution was to monkey patch the gem. The change adds the matching columns as a boolean value:

```
SELECT

...

(setweight(to_tsvector('english', coalesce("contents"."name"::text, '')), 'A')) @@ (to_tsquery('english', ''' ' || 'firebase' || ' ''' || ':*')) AS order_column0,

(setweight(to_tsvector('english', coalesce("contents"."description"::text, '')), 'B')) @@ (to_tsquery('english', ''' ' || 'firebase' || ' ''' || ':*')) AS order_column1,

(setweight(to_tsvector('english', coalesce("contents"."search_meta"::text, '')), 'C')) @@ (to_tsquery('english', ''' ' || 'firebase' || ' ''' || ':*')) AS order_column2

FROM contents

...
```

With these values we can now add the new columns to the ordering clause:

```
ORDER BY order_column0 DESC, pg_search_d1b2a59fbea7e20077af9f.rank DESC, "contents"."id" ASC, order_column1 DESC, order_column2 DESC
```

By calling the new extension, we get a better set of results:

```
irb:> puts Content.search('firebase').with_pg_search_ordering.limit(10).map(&:name)
Firebase Tutorial for Android: Getting Started
Firebase Tutorial: Getting Started
Firebase Tutorial: Real-time Chat
Firebase Remote Config Tutorial for iOS
Firebase Remote Config Tutorial for iOS
Firebase Tutorial: Real-time Chat
Firebase Tutorial: iOS A/B Testing
Firebase Tutorial: iOS A/B Testing
Firebase Tutorial: Real-time Chat
Firebase Tutorial: Getting Started
```

From the visitors perspective, the site will now return much better results.

Feel free to head on over to [my fork](https://github.com/roelbondoc/pg_search) of the `pg_search` gem. It’s still a work in progress and will need some test coverage. If there are others out there with an interest in such a feature I could open a PR to merge it back upstream. Hit me up on GitHub or on Twitter if you have any questions or just want to chat!
