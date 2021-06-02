Legion::Settings
=====

Legion::Settings is a hash like class used to store LegionIO Settings. 

Supported Ruby versions and implementations
------------------------------------------------

Legion::Json should work identically on:

* JRuby 9.2+
* Ruby 2.4+


Installation and Usage
------------------------

You can verify your installation using this piece of code:

```bash
gem install legion-json
```

```ruby
require 'legion-settings'
Legion::Settings.load(config_dir: './') # will automatically load json files it has access to inside this dir

Legion::Settings[:client][:hostname]
Legion::Settings[:client][:new_attribute] = 'foobar'

```

Authors
----------

* [Matthew Iverson](https://github.com/Esity) - current maintainer
