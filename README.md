# gorse-rb

[![Ruby](https://github.com/gorse-io/gorse-rb/actions/workflows/ci.yml/badge.svg)](https://github.com/gorse-io/gorse-rb/actions/workflows/ci.yml)
[![Gem](https://img.shields.io/gem/v/gorse)](https://rubygems.org/gems/gorse)
[![Gem](https://img.shields.io/gem/dt/gorse)](https://rubygems.org/gems/gorse)

Ruby SDK for gorse recommender system

## Install

```bash
gem install gorse
```

## Usage

```ruby
require 'gorse'

client = Gorse.new('http://127.0.0.1:8087', 'api_key')

# Insert a user
client.insert_user({
    'UserId' => 'bob',
    'Labels' => {
        'gender' => 'M',
        'age' => 24
    },
    'Comment' => 'my user'
})

# Insert an item
client.insert_item({
    'ItemId' => 'vuejs:vue',
    'IsHidden' => false,
    'Labels' => {
        'language' => 'JavaScript'
    },
    'Categories' => ['framework'],
    'Timestamp' => '2022-02-24T00:00:00Z',
    'Comment' => 'Vue.js framework'
})

# Insert feedbacks
client.insert_feedback([
    { 'FeedbackType' => 'star', 'UserId' => 'bob', 'ItemId' => 'vuejs:vue',            'Timestamp' => '2022-02-24T00:00:00Z' },
    { 'FeedbackType' => 'star', 'UserId' => 'bob', 'ItemId' => 'd3:d3',                 'Timestamp' => '2022-02-25T00:00:00Z' },
    { 'FeedbackType' => 'star', 'UserId' => 'bob', 'ItemId' => 'dogfalo:materialize',   'Timestamp' => '2022-02-26T00:00:00Z' },
    { 'FeedbackType' => 'star', 'UserId' => 'bob', 'ItemId' => 'mozilla:pdf.js',        'Timestamp' => '2022-02-27T00:00:00Z' },
    { 'FeedbackType' => 'star', 'UserId' => 'bob', 'ItemId' => 'moment:moment',         'Timestamp' => '2022-02-28T00:00:00Z' }
])

# Get recommendation
client.get_recommend('bob', n: 10)
```
