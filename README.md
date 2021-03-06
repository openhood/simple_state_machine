SimpleStateMachine
==================

Allow an Active Record or MongoMapper model to act as a finite state machine just as the popular plugin acts_as_state_machine but with many enhancements such as the possibility to have multiple states per object.

It can work together with the classic act_as_state_machine on the same project but both cannot be used at the same time for one given Active Record model. Moreover, simple_state_machine work standalone and doesn't require acts_as_state_machine.

You also get magic methods to check current state and a way to revert to previous state in database (or initial value for a new record) if something went wrong.


Dependencies
------------

* Ruby 1.8.7 or 1.9.2

Lazy dependencies
-----------------

* gem "active_record", ">= 3.0.0"
* gem "mongo_mapper", "~> 0.9.0"

Usage
-----

* With ActiveRecord

          require "simple_state_machine/active_record"

          class Chicken < ActiveRecord::Base
            state_machine :user_state, [:pending, :active, :removed, :on_hold]
            state_machine :validation_state, [:waiting, :reviewed, :validated, :invalid]
            def user_activate!
              return false if !user_state_pending?
              self.user_state = :active
              save! rescue user_state_revert
              user_state_active?
            end
          end

          # And then you can do:

          c = Chicken.create # c.user_state = :pending
          c.user_activate! # c.user_state = :active

* With MongoMapper

          require "simple_state_machine/mongo_mapper"

          class Chicken
            include MongoMapper::Document
            plugin SimpleStateMachine::MongoMapper

            state_machine :user_state, [:pending, :active, :removed, :on_hold]
            state_machine :validation_state, [:waiting, :reviewed, :validated, :invalid]
            def user_activate!
              return false if !user_state_pending?
              self.user_state = :active
              save! rescue user_state_revert
              user_state_active?
            end
          end

          # And then you can do:

          c = Chicken.create # c.user_state = :pending
          c.user_activate! # c.user_state = :active
          
License
-------

SimpleStateMachine is Copyright © 2010-2011 Openhood.com It is free software, and may be redistributed under the terms specified in the MIT-LICENSE file.
