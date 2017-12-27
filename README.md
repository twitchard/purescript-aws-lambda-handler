This module exposes a single function `makeHandler` that converts a curried function to produce an uncurried function of the form expected by AWS lambda.

For example:

```
myHandler :: ∀ e. Foreign → Foreign → Aff e a
myHandler event context =
  pure "Return this string"

handler = makeHandler myHandler
```

can achieve the equivalent of

```
exports.handler = function (event, context, callback) {
  return callback(null, "Return this string")
}
```

The function `makeHandler` is of type
```
makeHandler :: forall a eff.
  Encode a =>
  (Foreign → Foreign → (Aff eff a)) →
  EffFn3 eff Foreign Foreign (EffFn2 eff (Nullable Error) Foreign Unit) (Fiber eff Unit)
```
