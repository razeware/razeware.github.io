---
layout: post
logo: "--white"
header_style: "c-header--white"
title: "Avoiding ActiveRecord Callback Nightmares"
date: "July 13, 2018"
author: "Roel Bondoc"
author_role: "Fullstack Developer Razeware"
author_image: "roel-bondoc"
color: "#2A2E43"
image: "/assets/img/pattern-2.png"
category: "development"
excerpt: "Consider these techniques to avoid the pitfalls of callback hell."
---

Without a doubt, ActiveRecord callbacks is one of the most powerful features of rails. Although it keeps to the spirit of keeping your code DRY, it can be the double edge sword when used improperly. If you do not carefully consider when and where you use callbacks, you can easily find yourself in callback hell. With each callback you write, and as each day passes from the day you right it, you are adding to the mental requirement needed to know and understand how your models work. Let's take a look at some of the common issues you may run into and how we can work around them.

## Avoid them if possible

Sometimes you just have to resist the temptation to use a tool just because it is there. This point runs along the same line of premature optimiaztion. Until you know what you need to optimize, it is better to take the long route in an attempt to fully understand the issue.

Consider a business requirement:

> Send an email to the user upon creation.

Here it is easy to consider using a callback since the requirement is that we should always send an email.

```ruby
class User < ApplicationRecord
  after_create :send_email
end
```

Then your `#create` method in your controller would look something like this:

```ruby
  def create
    @user = User.create
    redirect_to @user
  end
```

While this gives you a super clean codebase, you are losing a bit of context when you only look at the model or controller individually. It is important to remember that when writing code, its not just about writing it for the present, but also for the person reading it in the future.

Consider the new business requirement:

> When creating a new group, add a new default user.

Here's what it may look like:

```ruby
class Group < ApplicationRecord
  has_many :users
  after_create do
    users.create
  end
end
```

Looking at this code in isolation, it seems relatively harmless. Without the proper context of the user model, the developer will be unaware of any side effects that may occur (sending an email to some default user).

While it may sound a bit counter intuivite to the "fat models and skinny controllers" mantra, it is important to keep related logic together at the point where they should occur.

```ruby
  def create
    @user = User.create
    @user.send_email
    redirect_to @user
  end
```

This now becomes more explicit that when your web form creates a user via the controller, it will now send an email. Any other method that may create a user no longer has to worry about any unwanted side effects.

## Keep them isolated

Although callbacks are executed in the order they are added to a model, it is something to consider not to rely on that ordering. In other words, callbacks that rely on the outcome of a previous callback can be a source of bugs/confusion.

```ruby
class Ticket < ApplicationRecord
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

The above notification will be sent with the correct up to date stats. However, if any ordering of the callbacks change, the notification may be sent out prematurely before the stats are updated.

Try to keep related operations together and don't be afraid if you think your code may look "ugly":

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

Being explicit in what you are trying to accomplish will go a long way in ensuring that the next person to read your code will have a better understanding of what needs to be done. Use descriptive method names to communicate your intent.

## Cascading callbacks

Simiarly, things can get a little hairy when your callbacks start triggering callbacks in other classes that you don't intend to.

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

At some point in the future, we add another callback to `Course`:

```ruby
class Course < ApplicationRecord
  has_many :videos
  after_save :propogate_category
  
  def propogate_category
    videos.each { |video| video.update(category: category) }
  end
end
```

While the above code may not generate any errors, it will perform unecessary work. And if this pattern continues, eventually may lead to more complex dependencies requiring more congnitive overheard to understand.

When dealing with operations that touch on may different parts of a system, one thing to consider is creating a class that can encapsulate all of this logic:

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

This will make things clear what operations need to take place between related models. At the same time, no callbacks are needed, thus there is less of a requirement to keep the context of each model on your mind.

## Final thoughts

Sometimes it's important to realize that the goal of writing software isn't always to implement common patterns, or follow certain rules. Try to avoid hidden gotcha's and alleviate the need to keep entire models in your mind in order to understand what is going on. The goal should be communicating your intent and building a codebase that you can live in so that it is not a nightmare.
