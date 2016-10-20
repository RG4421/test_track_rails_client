module RuboCop
  module Cop
    module Betterment
      class HTMLSafe < Cop
        MSG = 'Using html_safe creates the potential for XSS attacks. See here for more info: https://betterconfluence.atlassian.net/wiki/display/BetterEng/Unsafe+HTML+rendering'

        def on_send(node)
          _receiver, method_name = *node
          return unless method_name == :html_safe
          add_offense(node, :selector, MSG)
        end
      end
    end
  end
end
