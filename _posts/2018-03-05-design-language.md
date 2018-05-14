---
layout: post
logo: "--white"
header_style: "c-header--white"
title: "Using AWS for loading assets"
date: "April 05, 2017"
author: "Sam Davies"
author_role: "CTO Razeware"
author_bio: "Lorem Ipsum is simply dummy text of the printing and typesetting industry."
author_image: "sam-davies"
color: "#2A2E43"
image: "pattern-1"
category: "aws"
excerpt: "Lorem Ipsum is simply dummy text of the printing and typesetting industry."
---

## Code your own blockchain in less than 200 lines of Go!

*If this isn’t your first time reading this post, check out Part 2: [Here](https://www.google.com)*

This tutorial is adapted from this excellent post about writing a basic blockchain using Javascript. We’ve ported it over to Go and added some extra goodies like viewing your blockchain in a web browser. If you have any questions about the following tutorial, make sure to join our Telegram chat. Ask us anything! [I'm an inline-style link](https://www.google.com)

The data examples in this tutorial will be based on your resting heartbeat. We are a healthcare company after all :-) For fun, count your pulse for a minute (beats per minute) and keep that number in mind throughout the tutorial.

Almost every developer in the world has heard of the blockchain but most still don’t know how it works. They might only know about it because of Bitcoin and because they’ve heard of things like smart contracts. This post is an attempt to demystify the blockchain by helping you write your own simple blockchain in Go, with less than 200 lines of code! By the end of this tutorial, you’ll be able to run and write to a blockchain locally and view it in a web browser.

What better way to learn about the blockchain than to create your own?

**What you will be able to do**

*   Create your own blockchain
*   Understand how hashing works in maintaining integrity of the blockchain
*   See how new blocks get added
*   See how tiebreakers get resolved when multiple nodes generate blocks

**What you won’t be able to do**

To keep this post simple, we won’t be dealing with more advanced consensus concepts like proof of work vs. proof of stake. Network interactions will be simulated so you can view your blockchain and see blocks added, but network broadcasting will be reserved for a future post.

### Let’s get started!

##### Setup

Since we’re going to write our code in Go, we assume you have had some experience with Go. After installing and configuring Go, we’ll also want to grab the following packages:

`go get github.com/davecgh/go-spew/spew`

*Spew* allows us to view `structs` and `slices` cleanly formatted in our console. This is nice to have.

`go get github.com/gorilla/mux`

Gorilla/mux is a popular package for writing web handlers. We’ll need this.

`go get github.com/joho/godotenv`

##### Imports

Here are the imports we’ll need, along with our package declaration. Let’s write these to `main.go`

```
package main

import (
  "crypto/sha256"
  "encoding/hex"
  "encoding/json"
  "io"
  "log"
  "net/http"
  "os"
  "time"

  "github.com/davecgh/go-spew/spew"
  "github.com/gorilla/mux"
  "github.com/joho/godotenv"
)

```




