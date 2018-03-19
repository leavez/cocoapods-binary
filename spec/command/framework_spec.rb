require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Framework do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ framework }).should.be.instance_of Command::Framework
      end
    end
  end
end

