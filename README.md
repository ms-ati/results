# Results
[![Gem Version](https://badge.fury.io/rb/results.png)](http://badge.fury.io/rb/results)
[![Build Status](https://travis-ci.org/ms-ati/results.png)](https://travis-ci.org/ms-ati/results)
[![Dependency Status](https://gemnasium.com/ms-ati/results.png)](https://gemnasium.com/ms-ati/results)
[![Code Climate](https://codeclimate.com/github/ms-ati/results.png)](https://codeclimate.com/github/ms-ati/results)
[![Coverage Status](https://coveralls.io/repos/ms-ati/results/badge.png)](https://coveralls.io/r/ms-ati/results)

A functional combinator of results which are either Good or Bad inspired by the [ScalaUtils][1] library's
[Or and Every][2] classes.

[1]: http://www.scalautils.org
[2]: http://www.scalautils.org/user_guide/OrAndEvery

## Usage

### Basic validation

By default, `Results` will transform an `ArgumentError` into a `Bad`, allowing built-in
numeric conversion to work directly as a validator.

```ruby
def parseAge(str)
  Results.new(str) { |v| Integer(v) }
end

parseAge('1')
#=> #<struct Results::Good value=1>

parseAge('abc')
#=> #<struct Results::Bad error="invalid value for integer", input="abc">
```

### Chained filters and validations

Once you have a `Good` or `Bad`, you can chain additional boolean filters using `#when` and `#whenNot`.

```ruby
def parseAge21To45(str)
  # Syntax workaround due to lack of support for chaining on blocks
  a = parseAge(str)
  b = a.when    ('under 45') { |v| v < 45 }
  _ = b.when_not('under 21') { |v| v < 21 }
end

parseAge21To45('29')
#=> #<struct Results::Good value=29>

parseAge21To45('65')
#=> #<struct Results::Bad error="not under 45", input=65>

parseAge21To45('1')
#=> #<struct Results::Bad error="under 21", input=1>
```

Or you can chain validation functions (returning `Good` or `Bad` instead of `Boolean`) using `#validate`.

```ruby
def parseAgeRange(str)
  parseAge(str).validate do |v|
    case v
    when 21...45 then Results::Good.new(v)
    else              Results::Bad.new('not between 21 and 45', v)
    end
  end
end

parseAgeRange('29')
#=> #<struct Results::Good value=29>

parseAgeRange('65')
#=> #<struct Results::Bad error="not between 21 and 45", input=65>
```

For convenience, the `#when` and `#whenNot` methods also accept a lambda for
the error message, in case you want to format the error message based on the value provided.

More coming soon...

## TODO

1.  Define api
1.  Implement
1.  Document using yard
1.  Release 0.9.0 and solicit comments
1.  Incorporate suggested changes
1.  Release 1.0.0
1.  Potentially incorporate as a depedendency into [Rumonade](https://github.com/ms-ati/rumonade)
