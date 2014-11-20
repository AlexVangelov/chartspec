require 'spec_helper'

describe Chartspec do

  describe 'run' do

    it 'should work', chart: true do
      expect(Chartspec).to eq(Chartspec)
    end

  end
end