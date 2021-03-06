require 'spec_helper'

def load_players_for_dan
  test_mod = mock('Dank0')
  @boss = create_player_for_module(Dank0)
  @minions = []
  (1..2).each do |n|
    mod = Object::const_get("Dank#{n}")
    @minions << create_player_for_module(mod)
  end
  @enemies = []
  RSpec.configuration.mock_player_count.each do |n|
    mod = Object::const_get("PlayerMock#{n}")
    @enemies << create_player_for_module(mod)
  end
end

describe Dank0, "The Boss" do  
  before(:each) { start_game and load_players_for_dan and silence_output }
  
  it "shouldnt have more than 3 player instances total" do
    @minions.count.should == 2
  end
  
  describe "#to_s" do
    it "should have the correct name for the boss" do
      @boss.to_s.should == "Dan Knox"
    end
  end
  
  describe "minion?" do
    it "should return false after the first round" do
      commence_rounds 1
      @boss.send(:minion?).should be_false
    end
  end
  
  describe "#prepare_friendlies" do
    it "should only be called during the first round" do
      @boss.should_receive(:prepare_friendlies).once
      commence_rounds 2
    end
    
    it "should tell the minions that the game is underway" do
      Player.any_instance.stub(:trade)
      @minions.first.should_receive(:trade).with(:begin_game).once
      commence_rounds 1
    end
  end
    
  describe "#set_attack_targets" do
    before(:each) do
      commence_rounds 5
    end
    
    it "should tell the first five minions to attack the most experienced enemy" do
      target = @enemies.sort_by { |e| e.stats[:experience] }.last
      @minions.first.should_receive(:trade) do |command,new_target|
        new_target.stats[:experience].should == target.stats[:experience]
      end
      @boss.send(:set_attack_targets)
    end
    
    it "should tell the remaining minions to attack the second most experienced enemy" do
      target = @enemies.sort_by { |e| e.stats[:experience] }[-2]
      @minions.last.should_receive(:trade) do |command,new_target|
        new_target.stats[:experience].should == target.stats[:experience]
      end
      @boss.send(:set_attack_targets)
    end
  end
end

describe "Dank(1..9)", "The Minions" do
  before(:each) { start_game and load_players_for_dan and silence_output }
  
  describe "#to_s" do
    it "should have the correct name for the minions after the first round" do
      commence_rounds 1
      @minions.each { |m| m.to_s.should == "Minion" }
    end
  end
  
  describe "minion?" do
    it "should return true after the first round" do
      commence_rounds 1
      @minions.each { |m| m.send(:minion?).should be_true }
    end
  end
  
  describe "#prepare_friendlies" do
    it "should never be called" do
      @minions.each { |minion| minion.should_not_receive(:prepare_friendlies) }
      commence_rounds 2
    end
  end
  
  describe "#promote_minion" do
    before(:each) do
      @minion = @minions.first
    end
    
    it "should not trigger if boss is most experienced" do
      @minion.stub(:boss_lacks_experience?).and_return(false)
      @minion.should_not_receive(:promote_minion)
      commence_rounds 1
    end
    
    it "should trigger when boss falls behind a minion in experience" do
      @minion.stub(:boss_lacks_experience?).and_return(true)
      @minion.should_receive(:promote_minion)
      commence_rounds 1
    end
    
    it "should set the most experienced minion as the new boss" do
      commence_rounds 1
      new_boss = @minions.sort_by { |m| m.stats[:experience] }.last
      @minion.send(:promote_minion)
      new_boss.minion?.should be_false
    end
  end
  
  describe "#boss_lacks_experience?" do
    before(:each) { commence_rounds 1 }
    
    it "should return true when a minion has more experience than the boss" do
      minion = @minions.first
      minion.stub(:stats).and_return({ experience: 1000 })
      @boss.stub(:stats).and_return({ experience: 0 })
      @boss.send(:boss_lacks_experience?).should be_true
    end
    
    it "should return false when the boss has the highest experience level" do
      @boss.stub(:stats).and_return({ experience: 10000 })
      @boss.send(:boss_lacks_experience?).should be_false
    end
  end
end

describe "New Game" do
  before(:each) { start_game and load_all_players_and_monsters and silence_output }
  context "during the end game after 100 rounds" do
    before(:each) do
      commence_rounds 100
    end
    
    it "Dan Knox should always be the winner!" do
      #proxies = @game.proxies
      #winner = proxies.inject(proxies[0]) {|max, item| item.stats[:experience] > max.stats[:experience] ? item : max }
      #winner.to_s.should =~ /(Dan Knox|Minion)/ # its possible for minion to have equal experience until i put in place a system to destroy minions when all enemies are dead
      pending "need to update strategy again to be competitive with only 3 player instances."
    end
  end
end