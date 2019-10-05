module Main (loop) where

import Prelude

import Data.Either (Either(..))
import Data.Foldable (for_)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class.Console (error)
import Effect.Console (log)
import Role.Harvester (runHarvester)
import Role.Upgrader (runUpgrader)
import Screeps.Creep (getMemory)
import Screeps.Game (creeps, getGameGlobal)
import Screeps.Types (Creep)
import Role.Builder (runBuilder)

ignore :: forall a. a -> Unit
ignore _ = unit

ignoreM :: forall m a. Monad m => m a -> m Unit
ignoreM m = m <#> ignore 


matchUnit :: Creep -> String -> Effect Unit
matchUnit creep role = do
  case role of
    "Harvester" -> 
      (runHarvester creep)
    "Upgrader" -> 
      (runUpgrader creep)
    "Builder" ->
      (runBuilder creep)
    _ -> pure unit

runCreepRole :: Creep -> Effect Unit
runCreepRole creep = 
  do
    role <- getMemory creep "role"
    case role of
      Right json -> 
        matchUnit creep json
      Left e ->
        log e

loop :: Effect Unit
loop = do
  game <- getGameGlobal
  for_ (creeps game) runCreepRole
    
