require 'rspec'
require 'curse_tool'

describe 'CurseTool::CLI' do
  let!(:cli) { CurseTool::CLI }

  context :integration do
    it 'parses a manifest file into one of baughn\'s modpack nix files' do
      cli.build('../manifest/e24.yaml')
    end
  end
end