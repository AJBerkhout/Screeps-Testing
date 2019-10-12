module Role.Upgrader (runUpgrader) where

import Prelude

import CreepRoles (Upgrader)
import Data.Array (head)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Screeps (err_not_in_range, find_my_structures, find_sources, resource_energy)
import Screeps.Creep (amtCarrying, carryCapacity, harvestSource, moveTo, setMemory, transferToStructure, upgradeController)
import Screeps.Game (getGameGlobal)
import Screeps.Room (controller, find, find')
import Screeps.RoomObject (room)
import Screeps.Tower (energy, toTower)
import Screeps.Types (ResourceType(..), Structure, TargetPosition(..))

ignore :: forall a. a -> Unit
ignore _ = unit

ignoreM :: forall m a. Monad m => m a -> m Unit
ignoreM m = m <#> ignore 

isEmptyTower :: forall a. Structure a -> Boolean
isEmptyTower struct =
  case toTower struct of
    Nothing-> false
    Just t -> 
      energy t == 0

runUpgrader :: Upgrader  -> Effect Unit
runUpgrader { creep, mem: { working } } = do
  case working of
    false ->
      if amtCarrying creep resource_energy < (carryCapacity creep)
      then 
        case head (find (room creep) find_sources) of
          Nothing -> do 
            pure unit
          Just targetSource -> do
            harvestResult <- harvestSource creep targetSource
            if harvestResult == err_not_in_range
            then moveTo creep (TargetObj targetSource) # ignoreM
            else pure unit
      else do 
        setMemory creep "working" true
    true -> do
      game <- getGameGlobal
      if (amtCarrying creep (ResourceType "energy") > 0) then
        case (controller (room creep)) of
          Nothing -> do
            pure unit
          Just controller -> do
            upgradeResult <- upgradeController creep controller
            if upgradeResult == err_not_in_range
            then do
              moveTo creep (TargetObj controller) # ignoreM
            else do 
              pure unit
      else do 
        setMemory creep "working" false