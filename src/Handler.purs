module Web.AWS.Lambda (
    makeHandler
) where
import Prelude

import Control.Monad.Aff (Aff, Fiber, attempt, launchAff)
import Control.Monad.Eff (kind Effect)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Eff.Exception (Error)
import Control.Monad.Eff.Uncurried (EffFn2, EffFn3, mkEffFn3, runEffFn2)
import Data.Either (Either(Right, Left))
import Data.Foreign (Foreign)
import Data.Foreign.Class (class Encode, encode)
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable, toNullable)

foreign import null :: Foreign
{-
  Converts a curried function to produce an
  uncurried function of the form expected by
  AWS lambda.

  For example

  myHandler :: ∀ e. Foreign → Foreign → Aff e a
  myHandler event context =
    pure "Return this string"

  handler = makeHandler myHandler

  will become the equivalent of

  exports.handler = function (event, context, callback) {
    return callback(null, "Return this string")
  }
-}

makeHandler :: forall a eff.
  Encode a =>
  (Foreign → Foreign → (Aff eff a)) →
  EffFn3 eff Foreign Foreign (EffFn2 eff (Nullable Error) Foreign Unit) (Fiber eff Unit)
makeHandler fn = mkEffFn3 fn'
  where
    fn' event ctx callback = launchAff do
      result <- attempt (fn event ctx)
      case result of
        Left err → liftEff $ runEffFn2 callback (toNullable (Just err)) null
        Right val → liftEff $ runEffFn2 callback (toNullable Nothing) (encode val)
      pure unit
