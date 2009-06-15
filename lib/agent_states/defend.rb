module BraveZealot
  module DefendStates
    def defend
      push_next_state(:seek_done, :sniper_attack)
      transition(:defend, :seek)
    end
  end
end