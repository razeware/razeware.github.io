---
layout: post
logo: "--white"
header_style: "c-header--white"
title: "Avoiding ActiveRecord Callback Unpleasantries"
date: "July 13, 2018"
author: "Roel Bondoc"
author_role: "Fullstack Developer Razeware"
author_image: "roel-bondoc"
color: "#2A2E43"
image: "/assets/img/pattern-2.png"
category: "development"
excerpt: "Consider these techniques to avoid common callback pitfalls."
---

[TODO: Roel: This introduction is your first and only chance to hook the reader. Again, take the time to tell the story here. What project or projects were you working on when you realized that there was a great opportunity to write about ActiveRecord callbacks? Set the stage. Tell the reader what drove you to write about this topic. Otherwise, it feels like "Sam said I should write about ActiveRecord callbacks so that’s what I did." Which isn’t the case! Take the following structure for your introduction and expand it: "I was working on project X [give some high-level details about the project], which makes extensive use of ActiveRecord callbacks. In fact, here at Razeware we use ActiveRecord callbacks as a design pattern because [talk about why it’s a good design pattern and what problem it solves]. But while they may seem quite useful, the more I used them in our projects, I realized that they caused [this particiular problem]. Let me share what I’ve learned, as it may help you decide when and where to use ActiveRecord callbacks in your work."] 

Without a doubt, ActiveRecord callbacks is one of the most powerful features of Rails. Although it keeps to the spirit of keeping your code DRY, it can be the double edge sword when used improperly. At Razeware, it is common practice to use callbacks as a design pattern. We have used callbacks in many places and I had the opportunity to add more functionality on top of what we already had. Over time, it was easy for me to see how the amount of knowledge stored away steadily increased. Uncovering this information for the first time, or trying to remember it a second time, became a task on its own.

It is important to carefully consider when and where you use callbacks, otherwise you can easily find yourself in a predicament. With each callback you write, and as each day passes, you are adding to the mental requirement needed to understand how your models work. Let's take a look at some of the common issues you may run into and how we can work around them.

## Avoid them if possible

This might just be the obvious. [Remove previous sentence, the next sentence sets up the scene just perfectly on its own.] Sometimes you have to resist the temptation to use a tool just because it is there. This is basically the same idea as avoiding premature optimization: Until you know what you need to optimize, it’s [use contractions whenever possible to make the reader feel comfortable. "it is" is very formal language when read. Use "it’s" and other familiar contractions to make a piece more approachable.] better to follow the long route so that you can fully understand the issue before you overdesign the solution.

Consider the following business requirement:

> Send an email to the user upon creation.

[Always go for the familiar, casual language when you can. Take a look at how I’ve reworded the sentence below.]

Before: [Here it is easy to consider using a callback since the requirement is that we should always send an email.]
After: It’s easy to consider using a callback in this case, since the requirement is to always send an email:

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

While this gives you a super-clean codebase, [set up the mental scenario here that causes the issue...] if you are browsing your controller code six months down the road, you don’t have the complete context of this functionality without digging into the code further. You’ve gained clean code at the cost of obfuscating the details. [It is important to remember that] [You almost never need to lead in a sentence with "it is important to remember that" -- just say it.] When writing code, you aren’t just writing it for the present, but also for the person (maybe yourself!) reading it in the future.

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

The code looks pretty harmless on its own. But in this model, you don’t have any context about any follow-on effects of the user mode, and you, the developer, won’t know about possible side effects, such as sending an email to some default user. Whoops!

While it may sound [a bit] [You don’t really need modifiers such as "a bit" for strong adjectives like "counterintuitive". Especially when your modifier is trying to dampen the adjective. Just go for the adjective. And I think the word you’re going for is "contrary" anyway lol] [counterintuivite] contrary to the whole "fat models and skinny controllers" mantra, it’s important to keep related pieces of logic together at the point where they should occur.

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

This is now more explicit: when your web form creates a user via the controller, it will now send an email. Nothing anbiuguous about that. Any other method that wants to create a user no longer has to worry about any unexpected side effects.

## Keep them isolated

Although callbacks are executed in the order they are added to a model, you may not want to rely on that ordering. In other words, callbacks that rely on the outcome of a previous callback can be a source of bugs or confusion.

Consider the following snippet that [does the following stuff -- explain this to set up the mental model of this action before showing code]

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

The above notification will be sent with the correct up-to-date stats. Looks fine, doesn’t it? However, if the ordering of the callbacks change in the future, or areplaced into modules, the notification may be sent out prematurely before the stats are updated.

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

Things can get a little hairy when your callbacks start triggering callbacks in other classes that you don't intend to. For instance, look at the following code that [does this thing]:

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

The above code may not generate any errors, but it’s doing work unecessarily. And if development continues down this path, things will likely end up in a state with many complex dependencies which will take more time to understand.

## Probably need a header here to set up the bit below

When dealing with multiple operations that touch on many different parts of a system, a good approach is to create a class to encapsulate all of this logic. Here, I’ve [tell the user what each of the bits are doing below, again to set up the mental model]:

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

This make it clear which operations need to happemn between related models. At the same time, I can do this all without callbacks, which meand I don’t have to mentally consider the internal details of each callback as I develop. Nice!

## Final thoughts

When I first started working on [project or projects that led to this email], uncovering the logic hidden away in callbacks was enlightening [How was it enlightening?]. Each callback made sense on its own, but it was apparent that looking at them with a fresh pairs of eyes sheds a new light on how that information should be conveyed. [I can vaguely see what you’re trying to say in the previous sentence, but it’s not really clear. If you were explaining this to someone non-technical, what would you say? ] With a bit of consideration and empathy, we can provide a better codebase not only for ourselves but for new developers who come across our code.

The goal of writing software isn't always to implement common patterns, or follow certain rules. It’s far more important o avoid hidden gotcha's and reduce the cognitive overhead required to work with your models. Your real goal, in any coding project, is to communicate your intent clearly to others and build a codebase that you can live in for long periods of time with the least amount of frustration possible.