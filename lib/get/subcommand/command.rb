# frozen_string_literal: true

# Base class for (sub)commands. (Sub)Commands should be singletons.
class Command
  attr_reader :description, :action

  protected

  def initialize(usage, description, &action)
    @usage = usage
    @description = description
    @action = action
  end
end
