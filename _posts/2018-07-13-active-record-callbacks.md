---
layout: post
logo: "--white"
header_style: "c-header--white"
title: "Working with ActiveRecord Callback"
date: "October 12, 2018"
author: "Roel Bondoc"
author_role: "Fullstack Developer Razeware"
author_image: "roel-bondoc"
color: "#2A2E43"
image: "/assets/img/pattern-2.png"
category: "development"
excerpt: "Consider these techniques to avoid common callback pitfalls."
---

We've all been there. You jump into an existing project. It's a standard Rails app, adhering to all the common Rails practices and design patterns. But the more you familiarize yourself with the app, the more it becomes apparent you are untangling a deep web of nested business logic, hidden behind those practices and design patterns that were suppose to make things easy. I'm talking about ActiveRecord callbacks which is one of the most powerful features of Rails.

At Razeware, it is common practice to use callbacks as a design pattern. We have a Rails app that handles all the video content on raywenderlich.com. Within the app there are many models that often share information and behavior. We used callbacks to ensure certain operations took place when changes were made (like updating groups of videos when a course was updated). Overtime, the amount of callbacks increased, and so did the complexity of the models. I had the task to add a few small features which turned into a exercise of having to understand more of the app than needed to complete the task.

It is important to carefully consider when and where you use callbacks, otherwise you can easily find yourself in a predicament. With each callback you write, and as each day passes, you are adding to the mental requirement needed to understand how your models work. Let's take a look at some of the common issues you may run into and how we can work around them.

## Premature usage

Sometimes you have to resist the temptation to use a tool just because it is there. This is basically the same idea as avoiding premature optimization: Until you know what you need to optimize, it’s better to follow the long route so that you can fully understand the issue before you over-design the solution.

Consider the following business requirement:

> Send an email to the user upon creation.

It’s easy to consider using a callback in this case, since the requirement is to always send an email:

```ruby
class User < ApplicationRecord
  after_create :send_email
end
```

That means your `#create` method in your controller would look something like this:

```ruby
class UsersController < ApplicationController
  def create
    @user = User.create
    redirect_to @user
  end
end
```

While this gives you a super-clean codebase, this hides away behavior into a class. If you are browsing your controller code six months down the road, you don’t have the complete context of this functionality without digging into the code further. You’ve gained clean code at the cost of obfuscating the details. When writing code, you aren’t just writing it for the present, but also for the person (maybe yourself!) reading it in the future.

Consider another business requirement:

> When creating a new group, add a new default user.

Here's how you might implement this:

```ruby
class Group < ApplicationRecord
  has_many :users
  after_create do
    users.create(name: 'default')
  end
end
```

The code looks pretty harmless on its own. But in this model, you don’t have any context about any cascading effects of the user model, and you, the developer, won’t know about possible side effects, such as sending an email to some default user. Whoops!

While it may sound contrary to the whole "fat models and skinny controllers" mantra, it’s important to keep related pieces of logic together at the point where they should occur.

I’ve reworked the above code as such:

```ruby
class UsersController < ApplicationController
  def create
    @user = User.create
    @user.send_email
    redirect_to @user
  end
end
```

This is now more explicit: when your web form creates a user via the controller, it will now send an email. Nothing ambiguous about that. Any other method that wants to create a user no longer has to worry about any unexpected side effects.

## Dependent callbacks

Although callbacks are executed in the order they are added to a model, you may not want to rely on that ordering. In other words, callbacks that rely on the outcome of a previous callback can be a source of bugs or confusion.

Consider the following snippet that updates statistics in the database while also sending out a notification.

```ruby
class Video < ApplicationRecord
  belongs_to :category
  after_commit :refresh_category_stats
  after_commit :send_notification

  def refresh_category_counts
    category.update_stats
  end

  def send_notification
    StatsNotification.send(self)
  end
end
```

The above notification will be sent with the correct up-to-date stats. Looks fine, doesn’t it? However, if the ordering of the callbacks change in the future, or are placed into modules, the notification may be sent out prematurely before the stats are updated.

To solve this, try to keep related operations together and don't be afraid if you think your code may look "ugly", as you can see in my updated code:

```ruby
class Video < ApplicationRecord
  belongs_to :category
  after_commit :refresh_category_stats_and_send_notification

  def refresh_category_stats_and_send_notification
    category.update_stats
    StatsNotification.send(self)
  end
end
```

Being explicit about what your code is trying to do will give the next person to read your code a better understanding of how to work with your codebase. That means you should also use descriptive method names to communicate your intent!

## Cascading callbacks

Things can get a little hairy when your callbacks start triggering callbacks in other classes that you don't intend to. For instance, look at the following code that updates a `course` release date based on the earliest release date of its `videos`:

```ruby
class Course < ApplicationRecord
  has_many :videos
end

class Video < ApplicationRecord
  belongs_to :course
  after_save :update_course_release_date

  def update_course_release_date
    course.update(release_date: course.videos.earliest.release_date)
  end
end
```

At some point in the future, a different developer adds another callback to `Course`:

```ruby
class Course < ApplicationRecord
  has_many :videos
  after_save :propogate_category
  
  def propogate_category
    videos.each { |video| video.update(category: category) }
  end
end
```

The above code may not generate any errors, but it’s doing work unnecessarily. And if development continues down this path, things will likely end up in a state with many complex dependencies which will take more time to understand.

## Consolidate logic into a separate class

When dealing with multiple operations that touch on many different parts of a system, a good approach is to create a class to encapsulate all of this logic. Here, I’ve consolidated all of the related behavior into a single class:

```ruby
class CourseVideoUpdater
  def initialize(course)
    @course = course
  end
  
  def update
    propogate_course_category
    update_course_release_date
  end
  
  def propogate_course_category
    course.videos.each { |video| video.update(category: course.category) }
  end
  
  def update_course_release_date
    course.update(release_date: course.videos.earliest.release_date)
  end
end
```

This make it clear which operations need to happen between related models. At the same time, I can do this all without callbacks, which means I don’t have to mentally consider the internal details of each callback as I develop. Nice!

## Final thoughts

I first started working on refactoring bits and pieces of our content and permissions services. As I uncovered the logic hidden away in callbacks, it was enlightening as I had to remember multiple layers of behavior that should have been unrelated to my original task. Each callback made sense on its own, but it was apparent that after years of additional code, the original intent gets lost. With a bit of consideration, we can provide a better codebase not only for ourselves but for new developers who come across our code.

The goal of writing software isn't always to implement common patterns, or follow certain rules. It’s far more important to avoid hidden gotcha's and reduce the cognitive overhead required to work with your models. Your real goal, in any coding project, is to communicate your intent clearly to others and build a codebase that you can live with and with the least amount of frustration possible.