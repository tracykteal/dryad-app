#APP_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/config.yml")[RAILS_ENV]
hsh = HashWithIndifferentAccess.new

Dir.glob(File.join(Rails.root, 'config', 'tenants', '**.yml')).each do |fn|
  h = HashWithIndifferentAccess.new(YAML.load_file(fn)[Rails.env])
  hsh[h[:tenant_id]] = h
end

TENANT_CONFIG = hsh