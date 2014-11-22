# Load the Rails application.
require File.expand_path('../application', __FILE__)

require 'java'
Dir.glob(File.join("lib/**", "*.jar")).each do |jar|
  $CLASSPATH << "#{Rails.root.to_s}/#{jar}"
end

# Initialize the Rails application.
Clouds::Application.initialize!
