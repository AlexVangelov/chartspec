require 'spec_helper'

describe Chartspec do

  it 'should be present', chart: true do
    expect(Chartspec::Formatter).to eq(Chartspec::Formatter)
  end

end

describe "other group" do
  describe "1 subgroup" do
    it "test" do
      expect(true).to eq(true)
    end
  end
  
  describe "2 subgroup" do
    it "test" do
      expect(false).to eq(false)
    end
  end
end
