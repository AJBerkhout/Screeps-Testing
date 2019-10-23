module Role.WallRepairer (runWallRepairer, WallRepairerMemory, WallRepairer) where

import Prelude

import CreepRoles (Role)
import Data.Array (filter, head)
import Data.Either (Either(..))
import Data.Int (toNumber)
import Data.Maybe (Maybe(..), isJust)
import Effect (Effect)
import Screeps (err_not_in_range, find_construction_sites, find_sources_active, find_structures, resource_energy, structure_wall)
import Screeps.Creep (amtCarrying, build, carryCapacity, harvestSource, moveTo, repair, setAllMemory, transferToStructure)
import Screeps.Room (controller, find)
import Screeps.RoomObject (pos, room)
import Screeps.RoomPosition (findClosestByPath)
import Screeps.Structure (hits, hitsMax, unsafeCast)
import Screeps.Types (Creep, FindContext(..), TargetPosition(..))

ignore :: forall a. a -> Unit
ignore _ = unit

ignoreM :: forall m a. Monad m => m a -> m Unit
ignoreM m = m <#> ignore 

type WallRepairerMemory = { role :: Role, working :: Boolean }
type WallRepairer = { creep :: Creep, mem :: WallRepairerMemory }

setMemory :: WallRepairer -> WallRepairerMemory -> Effect Unit
setMemory {creep} mem = setAllMemory creep mem 

runWallRepairer :: WallRepairer -> Effect Unit
runWallRepairer repairer@{ creep, mem } = do

  if mem.working
  then do
    case ((amtCarrying creep resource_energy) == 0) of
      true -> 
        do
          setMemory repairer (mem { working = false })
      false ->
        case head (filter (\n -> (toNumber (hits n) / toNumber (hitsMax n)) < 0.0003 && (isJust (unsafeCast structure_wall n))) (find (room creep) find_structures)) of
          Nothing -> 
            case head (find (room creep) find_construction_sites) of
              Nothing -> do
                case controller (room creep) of
                  Just c -> do
                    transferResult <- transferToStructure creep c resource_energy
                    if transferResult == err_not_in_range
                    then moveTo creep (TargetObj c) # ignoreM
                    else pure unit
                  Nothing -> 
                    pure unit
              Just targetSite -> do
                buildResult <- build creep targetSite
                if buildResult == err_not_in_range 
                then moveTo creep (TargetObj targetSite) # ignoreM
                else pure unit
          Just damagedBuilding -> do
            repairResult <- repair creep damagedBuilding
            if repairResult == err_not_in_range then
              moveTo creep (TargetObj damagedBuilding) # ignoreM
            else do 
              pure unit
  else do
    case ((amtCarrying creep resource_energy) == (carryCapacity creep)) of
      true -> do
        setMemory repairer (mem { working = true })
      false -> do
        source <- findClosestByPath (pos creep) (OfType find_sources_active)
        case source of
          Right (Just targetSource) -> do
            harvestResult <- harvestSource creep targetSource
            if harvestResult == err_not_in_range
            then moveTo creep (TargetObj targetSource) # ignoreM
            else pure unit
          _ -> pure unit
              

