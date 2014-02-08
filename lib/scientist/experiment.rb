# This mixin provides shared behavior for experiments. Includers must
# implement enabled? and publish(result).
module Scientist::Experiment
  attr_reader :name
  attr_reader :behaviors

  def initialize(name, &block)
    @name = name
    @behaviors = {}

    yield self if !block.nil?
  end

  def run(behavior = "control")
    behavior = behavior.to_s
    block = behaviors[behavior]

    if block.nil?
      raise Scientist::BehaviorMissing.new(self, behavior)
    end

    if behaviors.size == 1 || !enabled?
      return block.call
    end

    results = {}

    behaviors.keys.shuffle.each do |name|
      block = behaviors[name]
      results[name] = Scientist::Observation.new(name, &block)
    end

    use = results[behavior]
    result = Scientist::Result.new(results)

    publish(result)

    if use.raised?
      raise use.exception
    end

    use.value
  end

  def try(behavior = "candidate", &block)
    behavior = behavior.to_s

    if behaviors.include?(behavior)
      raise Scientist::BehaviorNotUnique.new(self, behavior)
    end

    behaviors[behavior] = block
  end

  def use(&block)
    try("control", &block)
  end
end
