---
layout: post
logo: "--white"
header_style: "c-header--black"
title: "Using Docker instead of a package manager"
date: "Jan 10, 2020"
author: "Roel Bondoc"
author_role: "Fullstack Developer Razeware"
author_bio: "Interests: Ruby on Rails, games, and basketball."
author_image: "roel-bondoc@2x.jpeg"
color: "#049474"
hero: "c-post-hero--dark"
image: "/assets/img/pattern-7@2x.png"
category: "development"
excerpt: "Keeping your computer clean with Docker."
---

Docker is a widely known containerization strategy. One of its main use is to provide developers with a consistent environment for building, packaging, and deploying applications. At raywenderlich.com, we use Docker containers to build our service oriented architecture. Most of our containers are based on the ruby:2.5-slim image (and other close variants). While there are many resources describing how Ruby on Rails projects can be setup and run using Docker, I want to write about using Docker in another fashion.

As it turns out, because of the popularity of Docker, it’s actually a great replacement for a package manager. If you are familiar with `aptitude` for Debian based Linux distributions, or `homebrew` for MacOS, then you know how useful they are for managing installed libraries and applications. What I dislike about package managers is how they directly modify your host system. Installing, upgrading, and removing packages never seem like a clean process to me. After working closely with Docker over a few years, I’ve learned how powerful and convenient it can be for normal day to day use and not just for developing applications.

## Running different versions of ruby
I’ve been using ruby for a good part of my career and managing ruby versions has always seemed a little messy for me. Two projects I’ve used in the past were `rbenv` and `rvm`. Both projects allow your to install multiple ruby versions locally. I’m a big proponent of keeping systems clean, reproducible, and isolated. Using a ruby version manager did not give me the satisfaction of an isolated system. This is where using Docker comes into play. By leveraging its containerization capabilities, it becomes trivial to run any ruby version available.
```
$ docker run -it ruby:2.6
irb(main):001:0>
```
The above command will start and `irb` session using ruby 2.6. The `-it` switch allocates an interactive terminal allowing you to enter in ruby code to be executed. I use this very often to quickly run snippets of ruby that I want to test out or tweak. It is also very useful for testing new 2.6 features without having to install it locally.

## Running a database
Often times when you are developing web applications, you will want to store data into a database. There are many ways to install some of the more common databases like MySQL or Postgresql onto your local OS.  However, by doing so, you taint your OS with background processes, configuration files, and database files. The situation gets even more complicated when you need to run specific versions of those databases. By leveraging Docker, you isolate the database services into their own containers.
```
$ docker run —-net=host postgres:11.2
```
The above docker command will start an instance of Postgres 11.2. By using the `--net=host` switch, the server will bind to the default port of 5432 on your host machine. This will allow any of your database clients to connect locally as if the server was running on your computers OS.

This next command uses the same image but runs `psql` to open a console prompt for your server.
```
$ docker run —-net=host -it postgres:11.2 psql -h localhost -U postgres
```
Using Docker provides a really good balance in giving you the flexibility of choosing how and when you run server applications, as well as opening up tons of other applications at your fingertips.

## Handling Files Using Volumes
One of the key concepts of Docker is that each instance runs in a container. Because of this, the file system that an instance sees is isolated to that container only. So when a container is removed, the filesystem and all of its changes go away. It is common for me to be able to read and write from your local file system. In order for the container to see files in my host OS, I need to mount the volume to the instance. This is done by using the `-v` switch like so:
```
$ docker run -it -v /home/roel/files:/mnt/files ubuntu bash
```
The argument passed specifies to mount `/home/roel/files` from my local file system to `/mnt/` Ubuntu Docker instance running bash. I can then run any number of applications available to me in ubuntu against the files I have. When the instance is stopped and the container is removed, any changes I made to the mounted volume will persist locally.

## There’s more out there
There are tons of Docker images out there to choose from. Head on over to `http://hub.docker.com` to explore. I would also encourage you to explore the multitude of command line options available to the docker command. So, the next time you are about to install a new application through your package manager, take a quick peek and see if there is a docker image available instead. You be glad in the long run as you can keep your computer neat and tidy.
