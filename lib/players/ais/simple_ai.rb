class SimpleAi < Ai

  def play!
      valid_target = true

      if me.target_action != nil
          target_action = me.target_action
          if target_action.action.positive?
            target  = me.permanents.select{ |card| target_action.can_target(card) }.shuffle.first
          else
            target  = opponent.permanents.select{ |card| target_action.can_target(card) }.shuffle.first
          end
        if target
          # puts "Ai decides to #{target_action.action.name} #{target.name} with #{target_action.action.card.name}"
          return SinApp.action(@player, target_action.action , target )
        else
          valid_target = false
        end
      end

      land = hand.find {|c| c.is_a?(Land) && c.action(Play) != nil && c.action(Play).can_be_activated }
      if land
        # puts "Ai decides to play #{land.name}"
        return SinApp.action(@player, land.action(Play) )
      end


      creature = hand.sort_by(&:cost).reverse.find {|c|  c.is_a?(Creature) && c.action(Play).can_be_activated }
      if creature
        # puts "Ai decides to summon #{creature.name}"
        return SinApp.action(@player, creature.action(Play) )
      end


      spell = hand.sort_by(&:cost).reverse.find { |c| c.is_a?(Spell) && c.action(Play).can_be_activated  }
      if spell && ( valid_target || me.target_action == nil ||  me.target_action.action != spell.action(Play) )
        # puts "Ai decides to cast #{spell.name}"
        return SinApp.action(@player, spell.action(Play) )
      end


      action = me.permanents.map(&:actions).flatten.find { |a| a.can_be_activated &&
            !a.is_a?(Produce) &&
            !a.is_a?(UndoAttack) &&
            !a.is_a?(UndoBlock) &&
            !a.is_a?(Produce) &&
            !a.is_a?(Block) &&
            !a.is_a?(Attack) }
      if action && me.target_action == nil
        # puts "@@Ai decides for #{action.card.name} to #{action.name}"
        return SinApp.action(@player, action )
      end

      creature = creatures.find { |c| c.action(Attack).can_be_activated  && should_attack_with?(c) }
      # puts "should_attack_with?(creature) => #{creature.name} : #{should_attack_with?(creature)}" if creature
      if creature
        # puts "Ai decides to attack with #{creature.name}"
        return SinApp.action(@player, creature.action(Attack) )
      end

      if world.turn.phase.is_a?(BlockPhase)
        attacking_creatures = opponent.creatures.select{ |c| c.flags[:attacking] &&  !c.flags[:blocked] }
        attacking_creatures.sort_by(&:value).reverse.each do |attacking_creature|
          defending_creatures = creatures.select{ |c| c.action(Block).can_be_activated  && c.can?( Block, attacking_creature) }.sort_by(&:value)
          defending_creatures.each do |defending_creature|
            if defending_creature.attack >= attacking_creature.health
              # I can kill it
              if defending_creature.health > attacking_creature.attack
                # and not die
                return SinApp.action(@player, defending_creature.action(Block) ,  attacking_creature)
              end

              if defending_creature.value <= attacking_creature.value
                # and the other card is better or the same
                return SinApp.action(@player, defending_creature.action(Block) ,  attacking_creature)
              end
            end

            total_dmg = attacking_creatures.map(&:attack).inject{|sum,x| sum + x }

            if total_dmg / 2  >= @player.health
              # It is going to kill more than half my HP let's block
              return SinApp.action(@player, defending_creature.action(Block) ,  attacking_creature)
            end
          end
        end

      end


      if ! world.stack.empty?
        # puts "Ai resolve stack #{world}"
        return world.resolve_stack!
      end


      if world.turn.phase.is_a?(DiscardPhase) && hand.size >= 8 && me.playing? &&
        card = hand.select{ |c| c.action(Discard).can_be_activated }.sort_by(&:cost).reverse.first
        return SinApp.action(@player, card.action(Discard) ) if card
      end

      next_action = @player.actions.first
      return SinApp.action(@player, next_action)
  end

  def should_attack_with?(attacking_creature)
    # puts "opponent.creatures => #{opponent.creatures.size}"

    opponent.creatures.select{ |c| !c.tapped? &&  c.can_block_creature(attacking_creature) }.sort_by(&:value).each do |defending_creature|
      if defending_creature.would_kill? attacking_creature
        # my card can get killed
        if ! attacking_creature.would_kill?(defending_creature)
          # puts "Don't attack with #{attacking_creature} because #{defending_creature} would block and kill without dying"
          return false
        end
        if attacking_creature.would_kill?( defending_creature ) &&
          attacking_creature.value <= defending_creature.value
          # puts "Don't attack with #{attacking_creature} because #{defending_creature} would kill and die but #{attacking_creature} is better"
          return false
        end
      end
    end
    return true
  end

end
