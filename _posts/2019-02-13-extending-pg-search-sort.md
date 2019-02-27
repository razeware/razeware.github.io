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

PostgreSQL comes out of the box with fantastic full text-search capabilities. With a very robust feature set, it’s a popular option to implement search without having to use an external appliance like Elasticsearch or Solar.

PostgreSQL is also the database behind [raywenderlich.com](https://www.raywenderlich.com/). Naturally, it made sense to explore its features to build our very own [search page](https://www.raywenderlich.com/library). Fortunately, there is a nice gem called [pg_search](https://github.com/Casecommons/pg_search) that leverages the search features in PostgreSQL and easily integrate them into a Rails app. It’s fairly simple to implement: Once you’ve added it to your `Gemfile`, you can add full text search by including the module and calling the appropriate methods.

The gem gives a very intuitive API that lets you take advantage of many of PostgreSQL’s search features. First let's call `pg_search_scope` by passing a name for the search method and specifying which columns to search against.
```
class Content < ApplicationRecord
  include PgSearch
  pg_search_scope :search, against: :name
end
```

Calling `pg_search_scope` generates a method with the name as specified by the first parameter. Calling this method, in this case `.search`, allows you to query for results based on the `name` column. The results are sorted using a rank value. The rank value is a number based on how relevant each record is to your search term. The more relevant your record is, the higher the rank value should be. You can even set weights for multiple fields, allowing certain fields to be more important to the rank than others. Here you can see how weights can be added by converting the `against` value into a hash, where keys become the column name and the values are a weight value.

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

The code above formed the basis of the first iteration of the raywenderlich.com search page. However, we were quick to realize that some searches were not returning optimal results. For example, under certain conditions, searching for "core data" would sometimes return content that didn't have the term "core data" in the title. The term may have been in the body text of the content, but since it was missing from the title, the results felt irrelevant to the search term.

The example here shows how some results were getting ranked higher even if the search term was not in the `name` field. By default, `pg_search` sorts results by a rank result of all the queried columns combined as a single value. For some records, the lower ranked columns affected the rank value too much and the results did not appear intuitive:

```
irb:> Content.search('firebase').limit(5).map(&:name)
Firebase Tutorial for Android: Getting Started
Text Recognition with ML Kit   # <== no firebase term
Image Recognition With ML Kit  # <== no firebase term
Firebase Tutorial: Getting Started
Firebase Tutorial: Real-time Chat
```
Although the gem was working exactly as advertised, we wanted to fine tune the result set a bit more to our liking. In order to do that, I started by looking at how the SQL queries were constructed:

```
SELECT "contents".* FROM "contents" INNER JOIN
(SELECT "contents"."id" AS pg_search_id,
 (ts_rank(
          (setweight(to_tsvector('simple', coalesce("contents"."name"::text, '')), 'A') ||
           setweight(to_tsvector('simple', coalesce("contents"."description"::text, '')), 'B') ||
           setweight(to_tsvector('simple', coalesce("contents"."search_meta"::text, '')), 'C')),
          (to_tsquery('simple', ''' ' || 'firebase' || ' ''')), 0)
  ) AS rank
 FROM "contents"
 WHERE ((
     (setweight(to_tsvector('simple', coalesce("contents"."name"::text, '')), 'A') ||
      setweight(to_tsvector('simple', coalesce("contents"."description"::text, '')), 'B') ||
      setweight(to_tsvector('simple', coalesce("contents"."search_meta"::text, '')), 'C')
      ) @@ (to_tsquery('simple', ''' ' || 'firebase' || ' '''))
     ))
 ) AS pg_search_d1b2a59fbea7e20077af9f
ON "contents"."id" = pg_search_d1b2a59fbea7e20077af9f.pg_search_id
ORDER BY pg_search_d1b2a59fbea7e20077af9f.rank DESC, "contents"."id" ASC
```
As you can see, the entire result set is ordered by a `rank` value. What we needed, instead, was to be able to sort on the presence of the search term first of each column and then rank. The PostgreSQL `@@` search operator returns a Boolean value that we can use just for this purpose.
```
db=# SELECT to_tsvector('simple', 'The quick brown fox.') @@ to_tsquery('simple', 'fox');
 ?column?
----------
 t
(1 row)

db=# SELECT to_tsvector('simple', 'The quick brown fox.') @@ to_tsquery('simple', 'cow');
 ?column?
----------
 f
(1 row)
```
By applying this concept to our search SQL query, we can sort the results a bit better. 

Since there is no easy-to-extend functionality on the `pg_search` gem, we had to monkey patch the necessary modules in an initializer. Monkey patching allowed us to get changes out quicker and get feedback sooner. To monkey patch, I added a class method `.with_pg_search_ordering`. When chained to our original search method, the gem produced the extra SQL needed to modify the `ORDER BY` clause of the query.
```
SELECT

...

(to_tsvector('english', coalesce("contents"."name"::text, ''))) @@ (to_tsquery('english', ''' ' || 'firebase' || ' ''' || ':*')) AS order_column0,

(to_tsvector('english', coalesce("contents"."description"::text, ''))) @@ (to_tsquery('english', ''' ' || 'firebase' || ' ''' || ':*')) AS order_column1,

(to_tsvector('english', coalesce("contents"."search_meta"::text, ''))) @@ (to_tsquery('english', ''' ' || 'firebase' || ' ''' || ':*')) AS order_column2

FROM contents

...

ORDER BY order_column0 DESC, pg_search_d1b2a59fbea7e20077af9f.rank DESC, "contents"."id" ASC, order_column0 DESC, order_column1 DESC, order_column2 DESC
```
By calling the new extension, we get a better set of results:
```
irb:> Content.search('firebase').with_pg_search_ordering.limit(5).map(&:name)
Firebase Tutorial for Android: Getting Started
Firebase Tutorial: Getting Started
Firebase Tutorial: Real-time Chat
Firebase Remote Config Tutorial for iOS
Firebase Remote Config Tutorial for iOS
```
As you can expect, from the visitors’ perspective, the results appear more relevant and helpful. 

Using the `pg_search` gem is a great way to get your search up and running quickly, but don’t be afraid to dive deeper into what PostgreSQL search can do for you. I recommend checking out [Rach Belaid’s post](http://rachbelaid.com/postgres-full-text-search-is-good-enough/) for a more in-depth analysis of these features and how they work; the article really helped me to understand what was going on with our search and how to improve it.

If you want to see what changes were necessary to accomplish this, feel free to head on over to [my fork](https://github.com/roelbondoc/pg_search) of the `pg_search` gem. It’s still a work in progress and will need some test coverage. If there are others out there with an interest in such a feature, I could open a PR to merge it back upstream to the main repo. Hit me up on GitHub or on Twitter if you have any questions or just want to chat!
