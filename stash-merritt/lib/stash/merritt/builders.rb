module Stash
  module Merritt
    module Builders
      Dir.glob(File.expand_path('../builders/*.rb', __FILE__)).sort.each(&method(:require))
    end
  end
end
