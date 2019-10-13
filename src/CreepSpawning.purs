module CreepSpawning where

import Prelude

import CreepClassification (CreepMemory(..), VocationalCreep(..), classifyCreep, spawnCreep)
import CreepRoles (Role(..))
import Data.Array (concat, (..), fromFoldable, length, mapMaybe)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Traversable (for)
import Effect (Effect)
import Effect.Class.Console (logShow)
import Screeps.Constants (ok, part_carry, part_move, part_work)
import Screeps.Game (creeps, getGameGlobal)
import Screeps.Room (energyAvailable, energyCapacityAvailable)
import Screeps.RoomObject (room)
import Screeps.Spawn (canCreateCreep, canCreateCreep', spawning)
import Screeps.Types (ReturnCode, Spawn)

ignore :: forall a. a -> Unit
ignore _ = unit

ignoreM :: forall m a. Monad m => m a -> m Unit
ignoreM m = m <#> ignore 

spawnCreepIfNeeded :: Spawn -> Effect Unit
spawnCreepIfNeeded spawn =
  let 
    minHarvesters = 2
    minUpgraders = 1
    minBuilders = 3
    minLDHarvesters = 3
  in 
    do
      thisGame <- getGameGlobal
      creepsAndRolesObj <- for (creeps thisGame) $ classifyCreep
      let
        creepsAndRoles = fromFoldable creepsAndRolesObj 
        harvesters = creepsAndRoles # mapMaybe (case _ of 
          (Right (Harvester h)) -> Just h
          _ -> Nothing)
        upgraders = creepsAndRoles # mapMaybe (case _ of 
          (Right (Upgrader u)) -> Just u
          _ -> Nothing)
        builders = creepsAndRoles # mapMaybe (case _ of 
          (Right (Builder b)) -> Just b
          _ -> Nothing)
        ldHarvesters = creepsAndRoles # mapMaybe (case _ of 
          (Right (LDHarvester b)) -> Just b
          _ -> Nothing)
        maxEnergy = (energyCapacityAvailable (room spawn))
        canCreate = canCreateCreep spawn [part_work, part_work, part_carry, part_move]
      if (canCreate == ok) then
        case (spawning spawn) of
          Nothing -> 
            if ((length harvesters) < minHarvesters && maxEnergy >= energyAvailable (room spawn)) then
              createBalancedCreep spawn maxEnergy (HarvesterMemory {role: HarvesterRole})
              >>= logShow
            else if ((length builders) < minBuilders && maxEnergy >= energyAvailable (room spawn)) then
              createBalancedCreep spawn maxEnergy (BuilderMemory {role: BuilderRole, working: true})
              >>= logShow
            else if ((length upgraders) < minUpgraders && maxEnergy >= energyAvailable (room spawn)) then
              createBalancedCreep spawn maxEnergy (UpgraderMemory {role: UpgraderRole, working: true})
              >>= logShow
            else if ((length ldHarvesters) < minLDHarvesters && maxEnergy >= energyAvailable (room spawn)) then
              createLDHarvesterForAdjacentRoom spawn maxEnergy
            else 
              pure unit
          Just x -> 
            pure unit
    else do pure unit
          
createLDHarvesterForAdjacentRoom :: Spawn -> Int -> Effect Unit
createLDHarvesterForAdjacentRoom spawn energy =
  -- let 
  --   maybeExits = describeExits (name (room spawn))
  --   noName = Nothing
  -- in 
  --   case maybeExits of
  --     Just exitInfo ->
  let 
    targetRoom = "\"W2N1\""
    -- targetRoom = exitInfo."5"
    workParts = [part_work, part_work]
    numberOtherParts = (energy - 200) / 100
    moveParts = map (\n -> part_move) (0..(numberOtherParts-1))
    carryParts = map (\n -> part_carry) (0..(numberOtherParts-1))
    allParts = concat [workParts, moveParts, carryParts]
    noName = Nothing
  in
    spawnCreep spawn allParts noName (LDHarvesterMemory {role: LDHarvesterRole, home: "\"W2N2\"", targetRoom})
    >>= logShow
      -- Nothing ->
        -- pure unit

createBalancedCreep :: Spawn -> Int -> CreepMemory -> Effect (Either ReturnCode String)
createBalancedCreep spawn energy mem =
  let 
    numberOfParts = energy / 200
    moveParts = map (\n -> part_move) (0..(numberOfParts-1))
    workParts = map (\n -> part_carry) (0..(numberOfParts-1))
    carryParts = map (\n -> part_work) (0..(numberOfParts-1))
    allParts = concat [moveParts, workParts, carryParts]
    noName = Nothing
  in do
    spawnCreep spawn allParts noName mem