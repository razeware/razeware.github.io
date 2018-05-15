# Razeware Blog

## Contributing

Please also refer to the Razeware [blog policies](https://razeware.atlassian.net/wiki/spaces/RAZEWARE/pages/194609156/Developer+Blog+Policies).

All posts are to be added to the `_posts` directory using the following filename format:

```
./_posts/YYYY-MM-DD-title-using-dashes.md

#example
./_posts/2018-03-05-how-we-built-a-design-language.md
```

The date is the date which the post is published, followed by the text that will be used as the URL.

Each post must contain the following fields at the top of the file:

```
---
layout: post
title: How we built a design language
date: 2018-03-05
permalink: /design-language
author: Luke
tags: design
---
```

The fields `title`, `date`, and `permalink` are optional and can be used to override what would normally be generated by the filename.

## Development

To build and run the blog locally, you will need to have [docker-compose](https://docs.docker.com/compose/install/) installed.

The razeware blog is based on the open source static website generator [Jekyll](https://jekyllrb.com).

At the time of this document, the blog is hosted using github pages. With github pages, the `master` branch gets published to [https://razeware.github.io](https://razeware.github.io). At some point in the future we may transition to a custom domain and/or host elsewhere.

### Running the blog locally

```
$ bin/start
```

The server will then start up and available by going to [http://localhost:4000](http://localhost:4000)

Any changes you make to the blog (ie css, layouts, pages) automatically rebuilds the site. Only changes to `_config.yml` are not automatic, and will require a server restart.