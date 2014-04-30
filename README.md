# Results
[![Gem Version](https://badge.fury.io/rb/results.png)](http://badge.fury.io/rb/results)
[![Build Status](https://travis-ci.org/ms-ati/results.png)](https://travis-ci.org/ms-ati/results)
[![Dependency Status](https://gemnasium.com/ms-ati/results.png)](https://gemnasium.com/ms-ati/results)
[![Code Climate](https://codeclimate.com/github/ms-ati/results.png)](https://codeclimate.com/github/ms-ati/results)
[![Coverage Status](https://coveralls.io/repos/ms-ati/results/badge.png)](https://coveralls.io/r/ms-ati/results)

A functional combinator of results which are either {Results::Good Good} or {Results::Bad Bad}.

Inspired by the [ScalaUtils][1] library's [Or and Every][2] classes, whose APIs are documented
[here][3] and [here][4].

[1]: http://www.scalautils.org
[2]: http://www.scalautils.org/user_guide/OrAndEvery
[3]: http://doc.scalatest.org/2.1.3/index.html#org.scalautils.Or
[4]: http://doc.scalatest.org/2.1.3/index.html#org.scalautils.Every

## Table of Contents

* [Usage](#usage)
  * [Basic validation](#basic-validation)
  * [Chained filters and validations](#chained-filters-and-validations)
  * [Accumulating multiple bad results](#accumulating-multiple-bad-results)
    * [Multiple filters and validations of a single input](#multiple-filters-and-validations-of-a-single-input)
    * [Combine results of multiple inputs](#combine-results-of-multiple-inputs)
* [TODO](#todo)

## Usage

### Basic validation

By default, `Results` will transform an `ArgumentError` into a `Bad`, allowing built-in
numeric conversions to work directly as validations.

```ruby
def parseAge(str)
  Results.new(str) { |v| Integer(v) }
end

parseAge('1')   # => #<struct Results::Good value=1>
parseAge('abc') # => #<struct Results::Bad why=[#<struct Results::Because error="invalid value for integer", input="abc">]>
```

### Chained filters and validations

Once you have a `Good` or `Bad`, you can chain additional boolean filters using `#when` and `#when_not`.

```ruby
def parseAge21To45(str)
  # Syntax workaround due to no chaining on blocks - Open to suggestions!
  _ = parseAge(str)
  _ = _.when    ('under 45') { |v| v < 45 }
  _ = _.when_not('under 21') { |v| v < 21 }
end

parseAge21To45('29') # => #<struct Results::Good value=29>
parseAge21To45('65') # => #<struct Results::Bad why=[#<struct Results::Because error="not under 45", input=65>]>
parseAge21To45('1')  # => #<struct Results::Bad why=[#<struct Results::Because error="under 21", input=1>]>
```

Want to save your favorite filters? You can use the provided class `Filter`,
or any object with the same duck-type, meaning it responds to `#call` and `#message`.

```ruby
# You can use the provided class Filter
under_45 = Results::Filter.new('under 45') { |v| v < 45 }

# ...or do something funky like this...
under_21 = lambda { |v| v < 21 }.tap { |l| l.define_singleton_method(:message) { 'under 21' } }

# Both work the same way
parseAge('65').when(under_45).when_not(under_21)
#=> #<struct Results::Bad why=[#<struct Results::Because error="not under 45", input=65>]>
```

You can also chain validation functions (returning `Good` or `Bad` instead of `Boolean`) using `#validate`.

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
#=> #<struct Results::Bad why=[#<struct Results::Because error="not between 21 and 45", input=65>]>
```

For convenience, the `#when` and `#when_not` methods can also accept a lambda for
the error message, to format the error message based on the input value.

```ruby
parseAge('65').when(lambda { |v| "#{v} is not under 45" }) { |v| v < 45 }
#=> #<struct Results::Bad why=[#<struct Results::Because error="65 is not under 45", input=65>]>
```

In a similar vein, if you already have a `Filter` or compatible duck-type
(see above), it's easy turn it into a basic validation function returning
`Good` or `Bad` via convenience functions `Results.when` and `Results.when_not`.

```ruby
Results.when_not(under_21).call(16)
#=> #<struct Results::Bad why=[#<struct Results::Because error="under 21", input=16>]>
```

Note that this is equivalent to:

```ruby
Results.new(16).when_not(under_21)
```

The benefit of `Results.when` is for cases where the value (here, 16) is not yet known.

Experience has shown that many filters that are written are simply
predicates called on value objects, such as `Numeric#zero?` or `String#empty?` or
even `Object#nil?`.

For these cases, you can use the convenience function `Results.predicate`.

```ruby
# validates non-nil, non-empty
def valid?(str)
  Results.new(str)
    .when_not(Results.predicate :nil?)
    .when_not(Results.predicate :empty?)
end
```

Or even simpler, just pass the symbol of the predicate name directly to `#when` or `#when_not`.

```ruby
# same as above
def valid_short?(str)
  Results.new(str).when_not(:nil?).when_not(:empty?)
end
```

### Accumulating multiple bad results

So, now the interesting parts (Yes, the earlier sections were a bit slow,
but it picks up a bit here):

#### Multiple filters and validations of a single input

The way we've done things so far, even if you chained multiple filters and validations
together, if more than one would fail for some input, you would only see the first
`Bad`, and none of the the later filters would be run.

Now, instead, we're going to accumulate all the failures for a single input.

One simple way is to intersperse the `#and` method between your chained `#when` calls.

```ruby
# Good still works as before
Results.new(0).when(:integer?).and.when(:zero?)
#=> #<struct Results::Good value=0>

# Bad accumulates multiple failures
Results.new(1.23).when(:integer?).and.when(:zero?)
#=> #<struct Results::Bad why=[
  #<struct Results::Because error="not integer", input=1.23>,
  #<struct Results::Because error="not zero", input=1.23>]>
```

You can also call `#when_all` and`#when_all_not` with a collection of filters.

```ruby
filters = [:integer?, :zero?, Results::Filter.new('greater than 2') { |n| n > 2 }]
r = Results.new(1.23).when_all(filters)
#=> #<struct Results::Bad why=[
  #<struct Results::Because error="not integer", input=1.23>,
  #<struct Results::Because error="not zero", input=1.23>,
  #<struct Results::Because error="not greater than 2", input=1.23>]>
```

For a collection of validation functions, you can use `#validate_all` in a similar fashion.

#### Combine results of multiple inputs

If you have two results, the simplest way to combine them is with `#zip`. If both results
are good, it returns a `Good` containing an array of both values. However, if any results
are bad, it returns a `Bad` containing all the failures.

```ruby
good = Results::Good.new(1)
bad1 = Results::Bad.new('not nonzero', 0)
bad2 = Results::Bad.new('not integer', 1.23)

good.zip(good)
#=> #<struct Results::Good value=[1, 1]>

good.zip(bad1).zip(bad2)
#=> #<struct Results::Bad why=[
  #<struct Results::Because error="not nonzero", input=0>,
  #<struct Results::Because error="not integer", input=1.23>]>
```

If you have a collection of results, you can combine them with `Results.combine`. If all
results are good, it returns a single `Good` containing a collection of all the values.
However, if any results are bad, it returns a single `Bad` containing all the failures.

```ruby
all_good_results = [good, good, good]
some_bad_results = [bad1, good, bad2]

Results.combine(all_good_results)
#=> #<struct Results::Good value=[1, 1, 1]>

Results.combine(some_bad_results)
#=> #<struct Results::Bad why=[
  #<struct Results::Because error="not nonzero", input=0>,
  #<struct Results::Because error="not integer", input=1.23>]>
```

NOTE: this section is under construction...

## TODO

1.  Define api
1.  Implement
1.  Document using yard
1.  Release 0.9.0 and solicit comments
1.  Incorporate suggested changes
1.  Release 1.0.0
1.  Potentially incorporate as a depedendency into [Rumonade](https://github.com/ms-ati/rumonade)
